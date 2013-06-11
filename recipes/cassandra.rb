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

aws_ebs_volume "ebs_commit_drive" do
	aws_access_key          aws_creds['aws_access_key_id']
	aws_secret_access_key   aws_creds['aws_secret_access_key']
	size  node['aws']['ebs']['commit_log']['disk_size']  # in GB
	device "/dev/xvdd"
	piops node['aws']['ebs']['commit_log']['piops']  # i/o operations per second
	volume_type "io1"
	action [ :create, :attach ]
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
  command "mkfs.xfs /dev/xvdd"
  not_if 'mount -l | grep /srv/cassandra/commitlog'  # NB we grep for the mount-point *not* the device name b/c it'll show as /dev/xvdc or similar not the "role" name mount
end

mount "/srv/cassandra/commitlog" do
  device '/dev/xvdd'
  fstype 'xfs'
  options "noatime,nobootwait"
  action [:mount, :enable]
end

aws_ebs_raid 'data_log_volume_raid' do
  mount_point '/srv/cassandra/data'
  disk_count 2
  disk_size node['aws']['ebs']['data_log']['disk_size']
  disk_type "io1"
  disk_piops node['aws']['ebs']['data_log']['piops']
  level 0
  filesystem 'xfs'
  action :auto_attach
end

template 'mdadm configuration' do
  path value_for_platform(
    ['centos','redhat','fedora','amazon'] => {'default' => '/etc/mdadm.conf'},
    'default' => '/etc/mdadm/mdadm.conf'
  )
  source 'mdadm.conf.erb'
  mode 0644
  owner 'root'
  group 'root'
  notifies :run, "execute[update_initramfs]"
end

mount "/srv/cassandra/data" do
  device '/dev/md0'
  fstype 'xfs'
  options "noatime,nobootwait"
  action [:mount, :enable]
  notifies :run, "execute[update_initramfs]"
end

execute "update_initramfs" do
  user "root"
  command "/usr/sbin/update-initramfs -u"
  action :nothing
end
