include_recipe "apache_bigdata::default"
include_recipe "apache_bigdata::forrest"

tmp_staging 			=  node[:hcat][:staging]
remote_hcat_source 		= "#{node[:hcat][:mirror]}/hcatalog-#{node[:hcat][:version]}-incubating/hcatalog-src-#{node[:hcat][:version]}-incubating.tar.gz"
tmp_hcat_source_compressed 	= "#{tmp_staging}/hcatalog-src-#{node[:hcat][:version]}-incubating.tar.gz"
tmp_hcat_source			= "#{tmp_staging}/hcatalog-src-#{node[:hcat][:version]}-incubating"
hcatalog_version  		= "hcatalog-#{node[:hcat][:version]}-incubating"
hcatalog_src_version  		= "hcatalog-src-#{node[:hcat][:version]}-incubating"

local_hcat			= "#{node[:hcat][:home]}/#{node[:hcat][:version]}"
user_home 			= "/home/#{node[:auth][:hduser]}"


temp_hcatalog_home_version	= "#{node[:hcat][:staging]}/#{hcatalog_version}"	
hcatalog_home_version		= "/opt/#{hcatalog_version}"
hcatalog_home			= "/opt/hcatalog"

directory tmp_staging do
   action :create
end


node[:hcat][:debs].each do |deb|
   package deb do
     action :install
   end
end


remote_file tmp_hcat_source_compressed do
   source remote_hcat_source
   not_if { ::File.exists?(tmp_hcat_source_compressed) }
end

execute "untar hcat" do
    cwd "#{tmp_staging}"
    command "tar xvzf #{tmp_hcat_source_compressed}"
end

execute "chown_staging" do
    cwd "/tmp"
    command "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]} #{tmp_staging}" 
end

execute "chown hcat" do
    command "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]} #{tmp_hcat_source}" 
end

execute "source bashrc" do
   user node[:auth][:hduser]
   command "source ~/.bashrc"
   action :run
   returns 127

end

template "#{tmp_hcat_source}/build.xml" do
  source "build.xml.erb"

end
execute "build_tarball_as_hduser" do
   environment 'JAVA_HOME' => node[:hadoop][:java_home]
   user node[:auth][:hduser]
   cwd "#{tmp_hcat_source}"
   command "ant package && touch #{tmp_staging}/build_tarball_as_hduser"
   creates "#{tmp_staging}/build_tarball_as_hduser"
end

directory hcatalog_version do 
    action :create
    owner node[:auth][:hduser]
    group node[:auth][:hdgroup]
end

directory temp_hcatalog_home_version do 
    action :create
    owner node[:auth][:hduser]
    group node[:auth][:hdgroup]
    recursive true
end



execute "copy_hcatalog" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command  "cp #{tmp_staging}/#{hcatalog_src_version }/build/#{hcatalog_version}.tar.gz  #{temp_hcatalog_home_version}"
   
end

execute "untar_hcatalog" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command  "tar xvzf #{temp_hcatalog_home_version}/#{hcatalog_version}.tar.gz -C #{temp_hcatalog_home_version}"
   
end




directory hcatalog_home do 
    action :create
    owner node[:auth][:hduser]
    group node[:auth][:hdgroup]
    recursive true
end


execute "chmod_install_script" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd  "#{temp_hcatalog_home_version}/#{hcatalog_version}"
   command "chmod 740 share/hcatalog/scripts/hcat_server_install.sh"
end


execute "run_hcatalog_setup_script" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd  "#{temp_hcatalog_home_version}/#{hcatalog_version}"
   command "share/hcatalog/scripts/hcat_server_install.sh -r #{hcatalog_home} -d /usr/share/java -h #{node[:hadoop][:install_dir]}/hadoop -p #{node[:hive][:thrift][:port]}"
   creates  "#{hcatalog_home}/chef-init-hcatalog-install"
end



execute "chown_hcatalog" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command  "chown -R #{node[:auth][:hduser]}:#{node[:auth][:hdgroup]}  #{hcatalog_home}"
   creates 
end


