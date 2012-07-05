log_level        :info
log_location     STDOUT
chef_server_url  'https://api.opscode.com/organizations/CHEF_ORGNAME'
validation_key         "/etc/chef/client.pem"
validation_client_name 'CHEF_CLIENT_NODE_NAME'
