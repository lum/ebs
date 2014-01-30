#
# Cookbook Name:: ebs
# Recipe:: elasticsearch
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

aws_ebs_raid 'data_log_volume_raid' do
  aws_access_key          aws_creds['aws_access_key_id']
  aws_secret_access_key   aws_creds['aws_secret_access_key']
  mount_point '/srv/elasticsearch'
  disk_count 2
  disk_size node['aws']['ebs']['data_log']['disk_size']
  disk_type "io1"
  disk_piops node['aws']['ebs']['data_log']['piops']
  level 0
  filesystem 'xfs'
  action :auto_attach
end
