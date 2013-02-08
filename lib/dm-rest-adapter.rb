require 'rexml/document'
require 'json'

require 'rest-client'

require 'addressable/uri'

require 'dm-core'
require 'dm-serializer'

require 'dm-rest-adapter/adapter'
require 'dm-rest-adapter/format'
require 'dm-rest-adapter/format/xml'
require 'dm-rest-adapter/format/json'
require 'dm-rest-adapter/exceptions'

require 'restclient'
require 'ntlm/http'
require 'dm-rest-adapter/sharepoint'

DataMapper::Adapters::RestAdapter = DataMapperRest::Adapter
DataMapper::Associations::Relationship::OPTIONS << :nested
