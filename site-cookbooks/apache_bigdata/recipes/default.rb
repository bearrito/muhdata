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



execute "update_apt" do
    command "apt-get update"
end


node[:hadoop][:debs].each do |deb|
   package deb do
     action :install
   end
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

file "#{user_home}/.ssh/known_hosts" do
    user  node[:auth][:hduser]
    group node[:auth][:hdgroup]
    action :create_if_missing
end

execute "cat_ssh_to_auth_keys" do
  
  user  node[:auth][:hduser]
  group node[:auth][:hdgroup]
  cwd   user_home
  creates "/home/#{node[:auth][:hduser]}/.ssh/authorized_keys"
  command "touch #{user_home}/.ssh/authorized_keys && cat #{user_home}/.ssh/id_rsa.pub >> #{user_home}/.ssh/authorized_keys "
  action :run
end

execute "authorize_the_local_host" do
    user  node[:auth][:hduser]
    group node[:auth][:hdgroup]
    cwd   user_home
    command  "cd #{user_home} && ssh-keyscan -t rsa,dsa localhost 2>&1 | sort -u - #{user_home}/.ssh/known_hosts > #{user_home}/.ssh/tmp_hosts && cat #{user_home}/.ssh/tmp_hosts >> #{user_home}/.ssh/known_hosts"
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


execute "setup_bash_rc" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command "echo 'export HADOOP_HOME=#{hadoop_sym}' >> .bashrc && echo 'export JAVA_HOME=#{node[:hadoop][:java_home]}' >> .bashrc && echo 'export PATH=$PATH:$HADOOP_HOME/bin' >> .bashrc"
   action :run
end

execute "format_the_namenode" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   command name_node_format
   action :run
end

execute "start_hadoop" do
   environment 'HADOOP_HOME' => hadoop_sym
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   command "$HADOOP_HOME/bin/start-all.sh"
   action :run
end




