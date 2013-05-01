
remote_forrest_source 		= "#{node[:forrest][:mirror]}/#{node[:forrest][:version]}.tar.gz"
local_forrest_source_compressed = "#{node[:forrest][:home]}/#{node[:forrest][:version]}.tar.gz"
local_forrest 			= "#{node[:forrest][:home]}/#{node[:forrest][:version]}"
user_home = "/home/#{node[:auth][:hduser]}"


remote_file local_forrest_source_compressed do
    source remote_forrest_source
    not_if { ::File.exists?(local_forrest_source_compressed) }
end

execute "untar forrest" do
  command "tar xvzf #{node[:forrest][:version]}.tar.gz"
  cwd "#{node[:forrest][:home]}"
  creates "#{local_forrest}"
end

execute "build forrest" do
  command "./build.sh"
  cwd "#{local_forrest}/main"
end


execute "setup_bash_rc" do
   user node[:auth][:hduser]
   group node[:auth][:hdgroup]
   cwd user_home
   command "echo 'export FORREST_HOME=#{local_forrest}' >> .bashrc "
   command "echo 'export PATH=$PATH:$FORREST_HOME/bin' >> .bashrc"
   action :run
end



