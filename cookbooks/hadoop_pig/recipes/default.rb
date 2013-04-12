#
# Cookbook Name:: chef-hadoop
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

user_home = "/home/#{node[:auth][:hduser]}"
user node[:auth][:hduser] do
  shell "/bin/bash"
  home user_home
  system false
  action :create
  supports :manage_home => true
end

group node[:auth][:hdgroup] do
  action :create
  members node[:auth][:hduser]
  append true
end

apt_package "openjdk-7-jdk" do 
	action :install
end

hadoop_src = "#{node[:hadoop][:mirror]}/#{node[:hadoop][:version]}/#{node[:hadoop][:version]}.tar.gz"
hadoop_install_dir = "#{node[:hadoop][:install_dir]}"
hadoop_local_src = "#{hadoop_install_dir}/#{node[:hadoop][:version]}.tar.gz"
hadoop_local = "#{hadoop_install_dir}/#{node[:hadoop][:version]}"

remote_file hadoop_local_src do

	source  hadoop_src
	not_if { ::File.exists?(hadoop_local_src)}
	owner node[:auth][:hduser]
	group node[:auth][:hdgroup]
	mode 00770
end


execute "extract_hadoop" do
  command "tar xvzf #{hadoop_local_src}"
  cwd node[:hadoop][:install_dir]
end

directory hadoop_local do
  action :create
  owner node[:auth][:hduser]
  group node[:auth][:hdgroup]
  mode 00770
end


pig_src = "#{node[:pig][:mirror]}/#{node[:pig][:version]}/#{node[:pig][:version]}.tar.gz"
pig_install_dir = "#{node[:pig][:install_dir]}"
pig_local_src = "#{pig_install_dir}/#{node[:pig][:version]}.tar.gz"
pig_local = "#{pig_install_dir}/#{node[:pig][:version]}"


remote_file pig_local_src do

        source  pig_src
        owner node[:auth][:hduser]
        group node[:auth][:hdgroup]
        mode 00770
	not_if { ::File.exists?(pig_local_src)}
end



execute "extract_pig" do
  command "tar xvzf #{pig_local_src}"
  cwd node[:pig][:install_dir]
end


directory pig_local do
  action :create
  owner node[:auth][:hduser]
  group node[:auth][:hdgroup]
  mode 00770
end

directory "#{user_home}/.ssh" do
  action :create
  owner node[:auth][:hduser]
  group node[:auth][:hdgroup]
  mode 00700
end


execute "create_ssh_pair" do
  
  user  node[:auth][:hduser]
  group node[:auth][:hdgroup]
  cwd   user_home
  creates "/home/#{node[:auth][:hduser]}/.ssh/id_rsa.pub"
  command "touch foo.key && ssh-keygen -t rsa -N '' -f '/home/#{node[:auth][:hduser]}/.ssh/id_rsa'"
  action :run
end

execute "cat_ssh_to_auth_keys" do
  
  user  node[:auth][:hduser]
  group node[:auth][:hdgroup]
  cwd   user_home
  creates "/home/#{node[:auth][:hduser]}/.ssh/authorized_keys"
  command "touch /home/#{node[:auth][:hduser]}/.ssh/authorized_keys && cat /home/#{node[:auth][:hduser]}/.ssh/id_rsa.pub >> /home/#{node[:auth][:hduser]}/.ssh/authorized_keys "
  action :run
end



directory node[:hadoop][:temp_dir] do
 action :create
  owner node[:auth][:hduser]
  group node[:auth][:hdgroup]
  mode 00750
  recursive true 
end

link "#{node[:hadoop][:install_dir]}/hadoop" do
  to hadoop_local
end

hadoop_sym = "#{node[:hadoop][:install_dir]}/hadoop"

directory hadoop_sym do
  action :create
  owner node[:auth][:hduser]
  group node[:auth][:hdgroup]
  mode 00770
end




node[:hadoop][:configs].each do |config|
  template "hadoop config" do
    path "#{hadoop_local}/conf/#{config}"
    source "#{config}.erb"
    owner node[:auth][:hduser]
    group node[:auth][:hdgroup]
    mode 0640
  end
end


chown_command = "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]} #{hadoop_sym}"
chown_command_1 = "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]} #{hadoop_local}"

execute "chown_hadoop_symlink" do
  command "echo #{hadoop_sym}"
  command chown_command
  command chown_command_1
end

hadoop_command = "#{hadoop_sym}/bin/hadoop"
name_node_format = "#{hadoop_command} namenode -format"

execute "format_the_namenode" do
   command name_node_format
   action :run
end

