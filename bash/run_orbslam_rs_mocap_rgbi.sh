#!/bin/bash

# update lib cache
sudo ldconfig

# set the path to the directory containing the files
src_dir="/media/jlee/T7/data/tagnav/Aug23"
dst_dir="/media/jlee/T7/data/tagnav/wolf_results/visual-SLAM/tag-nav/results/rgb-i"
# set the name of the sequence of interest
sequence_name="Aug23_0"
# create a variable to hold the full path to the source directory
src_fname="${src_dir}/${sequence_name}.bag"
# create a variable to hold the full path to the destination directory
dst_fname="${dst_dir}/${sequence_name}.bag"

# source ros workspace
source ../../devel/setup.bash

# launch orb slam ros
roslaunch orb_slam3_ros rs_d435i_mono_inertial.launch &

# wait for a few seconds to make sure the launch has started
sleep 5

# start recording a rosbag containing mocap (ground truth) and orb slam (estimate) messages
rosbag record /orb_slam3/camera_pose /mocap/posestamped -O ${dst_fname} &
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
evo_ape bag ${dst_fname} /mocap/posestamped /orb_slam3/camera_pose -av --plot --plot_mode xyz 2>&1 | tee "${dst_dir}/${sequence_name}.txt"
