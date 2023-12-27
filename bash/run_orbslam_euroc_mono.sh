#!/bin/bash

# update lib cache
sudo ldconfig

# set the path to the directory containing the files
file_dir="/home/jlee/Downloads/euroc"

# set the name of the sequence of interest
fname="V1_01_easy"
# create a variable to hold the full path to the source directory
src_fname="${file_dir}/${fname}.bag"
# create a variable to hold the full path to the temporary directory
dst_fname="${file_dir}/${fname}_post.bag"

# source ros workspace
source ../../devel/setup.bash

# launch orb slam ros
roslaunch orb_slam3_ros euroc_stereo_inertial.launch &

# wait for a few seconds to make sure the launch has started
sleep 5

# start recording a rosbag containing mocap (ground truth) and orb slam (estimate) messages
rosbag record /vicon/firefly_sbx/firefly_sbx /orb_slam3/camera_pose -O ${dst_fname} &
record_pid=$!

# start playing back a rosbag file to render orb slam
rosbag play ${src_fname} &
play_pid=$!

# wait for the rosbag playback to complete
wait $play_pid

# stop the rosbag record process
kill $record_pid

# stop the roslaunch process
rosnode kill --all

# run evo to get APE results
evo_ape bag ${dst_fname} /vicon/firefly_sbx/firefly_sbx /orb_slam3/camera_pose -av --plot --plot_mode xyz 2>&1 | tee "${dst_fname}.txt"