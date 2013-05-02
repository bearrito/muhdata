
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

default[:forrest][:mirror]	= "http://archive.apache.org/dist/forrest/0.9/"
default[:forrest][:version] 	= "apache-forrest-0.9"
default[:forrest][:home]	= "/opt"
default[:forrest][:md5]		= "56799bac54f79cd26a8ba29b10904259"

default[:hcat][:mirror] 	= "http://apache.tradebit.com/pub/incubator/hcatalog"
default[:hcat][:version] 	= "0.5.0"
default[:hcat][:debs]		= ["ant","maven"]
default[:hcat][:home] 		= "/opt"

default[:hive][:mirror]		= "http://mirror.cc.columbia.edu/pub/software/apache/hive/"
default[:hive][:version_number] =  "0.10.0"

default[:hive][:version]	= "hive-#{hive[:version_number]}"
default[:hive][:schema_version]	= "hive-schema-#{hive[:version_number]}"
default[:hive][:db_password]	= "default3023i"
default[:hive][:db_user]	= "hduser"
default[:hive][:db]		= "hivemetastoredb"
default[:hive][:debs]		= ["libmysql-java"]
default[:hive][:root]		= "/opt"

default[:hive][:thrift][:server]	= "localhost"
default[:hive][:thrift][:port]		= 3233

default[:auth][:hduser]      	= "hduser"
default[:auth][:hdgroup]      	= "hadoop"

default[:java][:home] 		= "foo"
