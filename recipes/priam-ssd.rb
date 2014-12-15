#
# Cookbook Name:: ebs
# Recipe:: priam-ssd
#
# Copyright 2014, Steve Lum
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

directory "/srv/cassandra/data" do 
	user 'cassandra'
	group 'tomcat7'
	mode 00755
	recursive true
	action :create
end

execute "create-file-system" do
  user "root"
  group "root"
  command "mkfs.xfs /dev/xvdb"
  not_if 'mount -l | grep /srv/cassandra'  # NB we grep for the mount-point *not* the device name b/c it'll show as /dev/xvdc or similar not the "role" name mount
end

mount "/srv/cassandra/data" do
  device '/dev/xvdb'
  fstype 'xfs'
  options "noatime,nobootwait"
  action [:mount, :enable]
end

execute "update_initramfs" do
  user "root"
  command "/usr/sbin/update-initramfs -u"
  action :nothing
end