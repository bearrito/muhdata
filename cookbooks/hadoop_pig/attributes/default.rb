
default[:hadoop][:mirror]	= "http://apache.petsads.us/hadoop/core"
default[:hadoop][:version]      = "hadoop-1.1.2"
default[:hadoop][:install_dir]	= "/opt"
default[:hadoop][:temp_dir]     = "/var/hadoop/tmp"
default[:hadoop][:configs] 	= ["hadoop-env.sh","core-site.xml","mapred-site.xml","hdfs-site.xml"]
default[:hadoop][:java_home]         = "/usr/lib/jvm/java-7-openjdk-amd64"

# one of: debug, verbose, notice, warning
default[:pig][:install_dir]  	= "/opt"
default[:pig][:mirror]		= "http://apache.mirrors.hoobly.com/pig/"
default[:pig][:version]		= "pig-0.11.1"


default[:auth][:hduser]      	= "hduser"
default[:auth][:hdgroup]      	= "hadoop"

default[:java][:home] 		= "foo"
