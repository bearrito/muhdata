include_recipe "hadoop_pig::default"
include_recipe "hadoop_pig::forrest"


tmp_staging			= "/tmp/staging"
remote_hcat_source 		= "#{node[:hcat][:mirror]}/hcatalog-#{node[:hcat][:version]}-incubating/hcatalog-src-#{node[:hcat][:version]}-incubating.tar.gz"
tmp_hcat_source_compressed 	= "#{tmp_staging}/hcatalog-src-#{node[:hcat][:version]}-incubating.tar.gz"
tmp_hcat_source			= "#{tmp_staging}/hcatalog-src-#{node[:hcat][:version]}-incubating"
hcatalog_version  		= "hcatalog-#{node[:hcat][:version]}-incubating"
hcatalog_src_version  		= "hcatalog-src-#{node[:hcat][:version]}-incubating"

local_hcat			= "#{node[:hcat][:home]}/#{node[:hcat][:version]}"
user_home 			= "/home/#{node[:auth][:hduser]}"

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
execute "build tarball as hduser" do
   environment 'JAVA_HOME' => node[:hadoop][:java_home]
   user node[:auth][:hduser]
   cwd "#{tmp_hcat_source}"
   command "ant package && touch /tmp/staging/nobuild"
   creates "/tmp/staging/nobuild"
end

