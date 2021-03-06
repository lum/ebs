#
# Cookbook Name:: ebs
# Recipe:: graphite
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

aws_ebs_raid 'graphite_data_volume_raid' do
  mount_point '/srv/graphite'
  disk_count node['aws']['ebs']['graphite_data']['disk_count']
  disk_size node['aws']['ebs']['graphite_data']['disk_size']
  disk_type "io1"
  disk_piops node['aws']['ebs']['graphite_data']['piops']
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

mount "/srv/graphite" do
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