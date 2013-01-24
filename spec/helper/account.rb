require 'yaml'

require 'box/account'
require 'box/api'

ACCOUNT = YAML.load_file(File.dirname(__FILE__) + '/account.yml')

def get_api( access_token = nil )
  Box::Api.new( access_token || ACCOUNT['access_token'])
end

def get_account(access_token = nil)
  Box::Account.new( get_api(access_token) )
end

def get_root
  get_account.root
end
