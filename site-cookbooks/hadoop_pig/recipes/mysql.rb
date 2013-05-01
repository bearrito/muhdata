

mysql_connection_info = {:host => "localhost",
                         :username => 'root',
                         :password => node['mysql']['server_root_password']}

mysql_database 'hivemetastoredb' do
  connection mysql_connection_info
  action :create
end


mysql_database_user node[:hive][:db_user] do
  connection mysql_connection_info
  password  node[:hive][:db_password]
  action :create
end

mysql_database_user node[:hive][:db_user] do
    connection mysql_connection_info
    database_name node[:hive][:db]
    privileges [:all]
    action :grant
end
