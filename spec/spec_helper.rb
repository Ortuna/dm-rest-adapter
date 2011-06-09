require 'rubygems'
require 'pathname'
require 'fakeweb'
require 'dm-validations'

# Support running specs with 'rake spec' and 'spec'
$LOAD_PATH.unshift('lib') unless $LOAD_PATH.include?('lib')

require 'dm-rest-adapter'

ROOT = Pathname(__FILE__).dirname.parent

DataMapper.setup(:default, 'rest://admin:secret@localhost:4000/?format=xml')
DataMapper.setup(:without_extension, 'rest://admin:secret@localhost:4000/?format=xml&extension=')

Pathname.glob((ROOT + 'spec/fixtures/**/*.rb').to_s).each { |file| require file }

FakeWeb.allow_net_connect = false
