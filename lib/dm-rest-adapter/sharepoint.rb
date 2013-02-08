require 'pry'
module DataMapper
  module Sharepoint
    module Ntlm
      def request(req, body=nil, &block)
        req.ntlm_auth(username, '', password)
        __original_request__(req, body, &block)
      end

      def username
        "rsober"
      end

      def password
        "sharept70"
      end
    end

    module Json
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
    end

    module Resource
      def self.included(model)        
        model.send :include, DataMapper::Resource

        Net::HTTP.instance_eval do
          alias_method :__original_request__, :request unless method_defined?(:__original_request__)
          include DataMapper::Sharepoint::Ntlm
        end

        DataMapperRest::Format::Json.class_eval do
          include DataMapper::Sharepoint::Json
        end
      end
    end    
  end
end



