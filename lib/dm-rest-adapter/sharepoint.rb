class DataMapperRest::Format::Json
  def default_options
    DataMapper::Mash.new({ :mime => "application/json;odata=verbose" })
  end

  def parse_collection(json, model)
    array = JSON.parse(json)["d"]["results"]
    field_to_property = Hash[ model.properties(repository_name).map { |p| [ p.field, p ] } ]
    array.collect do |hash|
      record_from_hash(hash, field_to_property)
    end
  end

  def resource_path(*path_items)
    model = path_items.first[:model]
    "/_api/web/lists/getByTitle(\'#{model.storage_name}\')/items"
  end
end #Json

class Net::HTTP
  alias_method :__original_request__, :request
  def request(req, body=nil, &block)
    req.ntlm_auth(username, '', password)
    __original_request__(req, body, &block)
  end

  def username
    configs[:username]
  end

  def password
    configs[:password]
  end

  def configs
    {
      :username => '', 
      :password => ''
    }
  end
end


module DataMapper
  module Sharepoint
    module Resource
      def self.included(model)        
        model.send :include, DataMapper::Resource
        username = "rsober"
        password = "sharept70"
        Net::HTTP.class_eval %Q{
          def configs
            {
              :username => "#{username}",
              :password => "#{password}"
            }
          end
        }
      end #included
    end #Resource
  end #Sharepoint
end #DataMapper