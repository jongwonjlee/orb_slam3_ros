#!/bin/bash

# update lib cache
sudo ldconfig

# set the path to the directory containing the files
#file_dir="/data"
file_dir="/media/jlee/T7/MagPIE2/data-Mar24"
# set the name of the sequence of interest
sequence_name="magpie2Dataset_loc000"
# create a variable to hold the full path to the source directory
src_dir="${file_dir}/${sequence_name}.bag"
# create a variable to hold the full path to the destination directory
dst_dir="${file_dir}/${sequence_name}_post.bag"

# source ros workspace
source ../../devel/setup.bash

# launch orb slam ros
roslaunch orb_slam3_ros rs_d435i_rgbd_inertial.launch &

# wait for a few seconds to make sure the launch has started
sleep 5

# start recording a rosbag containing mocap (ground truth) and orb slam (estimate) messages
rosbag record /orb_slam3/camera_pose /mocap/posestamped -O ${dst_dir} &
record_pid=$!

# start playing back a rosbag file to render orb slam
rosbag play ${src_dir} &
play_pid=$!

# wait for the rosbag playback to complete
wait $play_pid

# stop the rosbag record process
kill $record_pid

# stop the roslaunch process
rosnode kill --all

# run evo to get APE results
# evo_ape bag ${dst_dir} /mocap/posestamped /orb_slam3/camera_pose -av --plot --plot_mode xyz 2>&1 | tee "${file_dir}/${sequence_name}.txt"
