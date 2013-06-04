#
# Cookbook Name:: ebs
# Recipe:: cassandra
#
# Copyright 2013, Steve Lum
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

include_recipe 'aws'

aws_creds = data_bag_item("aws", "main")

aws_ebs_volume "ebs_commit_drive" do
	aws_access_key          aws_creds['aws_access_key_id']
	aws_secret_access_key   aws_creds['aws_secret_access_key']
	size  100  # in GB
	device "/dev/xvdc"
	piops 500  # i/o operations per second
	volume_type "io1"
	action [ :create, :attach ]
end

# naming based on role/recipe to avoid collisions over names like /dev/xvdc when roles are piles on boxes
link "/dev/cassandra/commitlog" do
  to "/dev/xvdc"
  link_type :symbolic
end

directory "/srv/cassandra/commitlog" do
  user 'root'
  group 'root'
  mode 00755
  recursive true
  action :create
end

execute "create-file-system" do
  user "root"
  group "root"
  command "mkfs.xfs /dev/cassandra/commitlog"
  not_if 'mount -l | grep /srv/cassandra/commitlog'  # NB we grep for the mount-point *not* the device name b/c it'll show as /dev/xvdc or similar not the "role" name mount
end

mount "/srv/cassandra/commitlog" do
  device '/dev/cassandra/commitlog'
  fstype 'xfs'
  options "noatime,nobootwait"
  action [:mount, :enable]
end

aws_ebs_raid 'data_log_volume_raid' do
  mount_point '/srv/cassandra/datafile'
  disk_count 2
  disk_size 500
  disk_type "io1"
  disk_piops 1000
  level 0
  filesystem 'ext4'
  action :auto_attach
end