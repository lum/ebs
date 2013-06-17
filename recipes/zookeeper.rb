#
# Cookbook Name:: ebs
# Recipe:: zookeeper
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

case node[:platform]
when 'debian','ubuntu'
  package 'xfsdump'
  package 'xfsprogs'
  package 'xfslibs-dev'
when 'redhat','centos','fedora','amazon'
  package 'xfsprogs-devel'
end

include_recipe 'aws'

aws_creds = data_bag_item("aws", "main")

aws_ebs_volume "ebs_zookeeper_drive" do
  aws_access_key          aws_creds['aws_access_key_id']
  aws_secret_access_key   aws_creds['aws_secret_access_key']
  size  node['aws']['ebs']['data_log']['disk_size']  # in GB
  device "/dev/xvdd"
  piops node['aws']['ebs']['data_log']['piops']  # i/o operations per second
  volume_type "io1"
  action [ :create, :attach ]
end

directory "/srv/zookeeper" do
  user 'root'
  group 'root'
  mode 00755
  recursive true
  action :create
end

execute "create-file-system" do
  user "root"
  group "root"
  command "mkfs.xfs /dev/xvdd"
  not_if 'mount -l | grep /srv/zookeeper'  # NB we grep for the mount-point *not* the device name b/c it'll show as /dev/xvdc or similar not the "role" name mount
end

mount "/srv/zookeeper" do
  device '/dev/xvdd'
  fstype 'xfs'
  options "noatime,nobootwait"
  action [:mount, :enable]
end
