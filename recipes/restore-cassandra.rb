#
# Cookbook Name:: ebs
# Recipe:: restore-cassandra
#
# Copyright 2013, Steve Lum
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

formatted_nodename = #{nodename}.gsub('.', '_')
ebs_snap_ids = data_bag_item("snapshots", "#{formatted_nodename}")

aws_ebs_volume "ebs_commit_drive" do
	aws_access_key          aws_creds['aws_access_key_id']
	aws_secret_access_key   aws_creds['aws_secret_access_key']
	size  node['aws']['ebs']['commit_log']['disk_size']  # in GB
	device "/dev/xvdd"
	piops node['aws']['ebs']['commit_log']['piops']  # i/o operations per second
	volume_type "io1"
	snapshot_id ebs_snap_ids['commit_volume']['commit_volume_snapshot_id']
	action [ :create, :attach ]
end

mount "/srv/cassandra/commitlog" do
  device '/dev/xvdd'
  fstype 'xfs'
  options "noatime,nobootwait"
  action [:mount, :enable]
end

data_vol_snapshots = []
data_vol_snapshots << ebs_snap_ids['data_volume1']['data_volume1_snapshot_id']
data_vol_snapshots << ebs_snap_ids['data_volume2']['data_volume2_snapshot_id']

aws_ebs_raid 'data_log_volume_raid' do
  mount_point '/srv/cassandra/data'
  disk_count node['aws']['ebs']['data_log']['disk_count']
  disk_size node['aws']['ebs']['data_log']['disk_size']
  disk_type "io1"
  disk_piops node['aws']['ebs']['data_log']['piops']
  level 0
  filesystem 'xfs'
  snapshots data_vol_snapshots
  action :auto_attach
end