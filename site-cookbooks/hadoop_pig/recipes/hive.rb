remote_hive_source 		= "#{node[:hive][:mirror]}/#{node[:hive][:version]}/#{node[:hive][:version]}.tar.gz"
hive_source_compressed 		= "#{node[:hive][:root]}/#{node[:hive][:version]}.tar.gz"
hive_home_version		= "#{node[:hive][:root]}/#{node[:hive][:version]}"
hive_home			= "#{node[:hive][:root]}/hive"

user_home 			= "/home/#{node[:auth][:hduser]}"

hcatalog_version  		= "hcatalog-#{node[:hcat][:version]}-incubating"
hcatalog_schema_version 	= "hcatalog-schema-#{node[:hcat][:version]}-incubating"

temp_hcatalog_home_version	= "/tmp/hcat-staging/#{hcatalog_version}"	
hcatalog_home_version		= "/opt/#{hcatalog_version}"
hcatalog_home			= "/opt/hcatalog"


node[:hive][:debs].each do |deb|
   package deb do
     action :install
   end
end

remote_file hive_source_compressed do
   source remote_hive_source
   not_if { ::File.exists?(hive_source_compressed) }
end

execute "untar hive" do
    cwd "#{node[:hive][:root]}"
    command "tar xvzf #{hive_source_compressed}"
end

link  hive_home do
  to hive_home_version
end

execute "chown_hive" do
    command "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]} #{hive_home}" 
    command "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]} #{hive_home_version}"
end

execute "setup_hive_hdfs" do 
  environment 'HADOOP_HOME' => "#{node[:hadoop][:install_dir]}/hadoop"
  command  "$HADOOP_HOME/bin/hadoop fs -mkdir       /tmp"
  command  "$HADOOP_HOME/bin/hadoop fs -mkdir       /user/hive/warehouse"
  command  "$HADOOP_HOME/bin/hadoop fs -chmod g+w   /tmp"
  command  "$HADOOP_HOME/bin/hadoop fs -chmod g+w   /user/hive/warehouse"
  creates  "#{hcatalog_home}/chef-init-hdfs"

end

execute "setup_bash_rc" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command "echo 'export HIVE_HOME=#{hive_home}' >> .bashrc"
   action :run
end



hive_db_init = "mysql -u #{node[:hive][:db_user]} -D #{node[:hive][:db]} -h #{node[:hive][:thrift][:server]} < #{hive_home}/scripts/metastore/upgrade/mysql/#{hcatalog_schema_version}.mysql.sql"

execute "init_the_hive_db" do
     command hive_db_init
     creates  "#{hcatalog_home}/chef-init-hive-db"
end


execute "setup_bash_rc_for_hive" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command "echo 'export HIVE_HOME=#{hive_home}' >> .bashrc"
   action :run
end

directory hcatalog_home do 
    action :create
    user node[:auth][:hduser]
    group node[:auth][:hdgroup]
end

directory temp_hcatalog_home_version do 
    action :create
    user node[:auth][:hduser]
    group node[:auth][:hdgroup]
end

execute "copy_chown_hcatalog" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command = "cp /tmp/staging/#{hcatalog_version}/build/#{hcatalog_version}.tar.gz  #{temp_hcatalog_home_version}"
   command = "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]}  #{hcatalog_home}"
   creates  #{temp_hcatalog_home_version}
end

link  hcatalog_home do
  to hcatalog_home_version
end


execute "run_hcatalog_setup_script" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd  temp_hcatalog_home_version
   command = "share/hcatalog/scripts/hcat_server_install.sh -r  #{hcatalog_home} -d /usr/share/java -h #{node[:hadoop][:install_dir]}/hadoop -p #{node[:hive][:thrift][:port]}"
   creates  "#{hcatalog_home}/chef-init-hcatalog-install"
end



