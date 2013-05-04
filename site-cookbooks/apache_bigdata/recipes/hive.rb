remote_hive_source 		= "#{node[:hive][:mirror]}/#{node[:hive][:version]}/#{node[:hive][:version]}.tar.gz"
hive_source_compressed 		= "#{node[:hive][:root]}/#{node[:hive][:version]}.tar.gz"
hive_home_version		= "#{node[:hive][:root]}/#{node[:hive][:version]}"
hive_home			= "#{node[:hive][:root]}/hive"
hive_schema_version 		=  node[:hive][:schema_version]

user_home 			= "/home/#{node[:auth][:hduser]}"




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
    user node[:auth][:hduser]
    group node[:auth][:hdgroup]
    command  "echo $HADOOP_HOME && echo whoami"
end

execute "setup_hive_hdfs" do 
    environment 'HADOOP_HOME' => "#{node[:hadoop][:install_dir]}/hadoop"
    user node[:auth][:hduser]
    group node[:auth][:hdgroup]
    command  command <<-EOF
	$HADOOP_HOME/bin/hadoop dfs -test -e  /tmp 
		if [ $? -eq 0 ]
		then
  			echo '/tmp already exists'

	else 
  		echo 'creating /tmp'
  		$HADOOP_HOME/bin/hadoop fs -mkdir /tmp
  		$HADOOP_HOME/bin/hadoop fs -chmod g+w   /tmp

	fi

	$HADOOP_HOME/bin/hadoop dfs -test -e  /user/hive/warehouse
	if [ $? -eq 0 ]
	then  
 		echo '/usr/hive/warehouse already exists'

	else 
  		echo 'creating /usr/hive/warehouse'
  		$HADOOP_HOME/bin/hadoop fs -mkdir /user/hive/warehouse
  		$HADOOP_HOME/bin/hadoop fs -chmod g+w   /user/hive/warehouse	
	fi
    EOF


end



execute "setup_bash_rc" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command "echo 'export HIVE_HOME=#{hive_home}' >> .bashrc"
   action :run
end



hive_db_init = "mysql -u #{node[:hive][:db_user]} -D #{node[:hive][:db]} -h #{node[:hive][:thrift][:server]} -p#{node[:hive][:db_password]} < #{hive_home}/scripts/metastore/upgrade/mysql/#{hive_schema_version}.mysql.sql"

execute "init_the_hive_db" do
     user node[:hive][:db_user]
     group node[:auth][:hdgroup]
     command hive_db_init
     creates  "#{hive_home}/chef-init-hive-db"
end


execute "setup_bash_rc_for_hive" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command "echo 'export HIVE_HOME=#{hive_home}' >> .bashrc"
   action :run
end



template "#{hive_home}/conf/hive-site.xml" do
   source "hive-default.xml.template.erb"
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
end




