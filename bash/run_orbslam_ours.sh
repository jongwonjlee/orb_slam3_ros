#!/bin/bash

# update lib cache
sudo ldconfig

# set the path to the directory containing the files
file_dir="/media/jlee/T7/data/MagPIE2/data-Mar24"

# set the name of the sequence of interest
fname="magpie2Dataset_loc009"
# create a variable to hold the full path to the source directory
src_dir="${file_dir}/raw/${fname}.bag"
# create a variable to hold the full path to the temporary directory
tmp_dir="${file_dir}/tmp/${fname}.bag"

# source ros workspace
source ../../devel/setup.bash

# launch orb slam ros
roslaunch orb_slam3_ros rs_d435i_rgbd_inertial.launch &

# wait for a few seconds to make sure the launch has started
sleep 5

# start recording a rosbag containing mocap (ground truth) and orb slam (estimate) messages
rosbag record /orb_slam3/camera_pose -O ${tmp_dir} &
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

# export mocap in tum format
evo_traj bag ${src_dir} /mocap/posestamped --save_as_tum
mv mocap_posestamped.tum ${file_dir}/traj/${fname}_gt.tum

# export orbslam odometry in tum format
evo_traj bag ${tmp_dir} /orb_slam3/camera_pose --save_as_tum
mv orb_slam3_camera_pose.tum ${file_dir}/traj/${fname}_od.tum

# export orbslam keyframes (i.e., backend optimization results with loop closure) in tum format
mv ~/orbslam3_kfpose.tum ${file_dir}/traj/${fname}_kf.tum

# run evo to get APE results of odometry
evo_ape tum ${file_dir}/traj/${fname}_gt.tum ${file_dir}/traj/${fname}_od.tum -av --plot --plot_mode xy --save_plot ${file_dir}/results/${fname}_od 2>&1 | tee "${file_dir}/results/${fname}_od.txt"

# run evo to get APE results of keyframe poses
evo_ape tum ${file_dir}/traj/${fname}_gt.tum ${file_dir}/traj/${fname}_kf.tum -av --plot --plot_mode xy --save_plot ${file_dir}/results/${fname}_kf 2>&1 | tee "${file_dir}/results/${fname}_kf.txt"