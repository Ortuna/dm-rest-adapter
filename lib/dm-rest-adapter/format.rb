module DataMapperRest
  module Format
    class AbstractFormat
  	  attr_accessor :extension, :mime, :repository_name

      def initialize(options = {})
        options = default_options.merge(options)
        @extension = options[:extension]
        @extension = nil if @extension == "" # consider blank extension as not present
        @mime = options[:mime]
        @repository_name = options.fetch(:repository_name, :default)
      end

      def default_options
        DataMapper::Mash.new
      end

      def resource_name(model)
        model.storage_name(model.default_repository_name) 
      end

      def resource_path(*path_fragments)
        path = path_fragments.reduce("") do |memo, fragment|
          model = fragment[:model]
          key   = fragment[:key]
          memo << "#{resource_name(model)}/"
          memo << "#{key}/" if key
          memo
        end.chomp("/")
        
        path = "#{path}.#{extension}" if extension
        
        path
      end
      
      def properties_to_serialize(resource)
        model = resource.model
        model.properties + model.relationships.reject{ |r| r.source_key == model.key }.collect{ |r| r.source_key }.flatten
      end
      
      def update_attributes(resource, body)
        return if DataMapper::Ext.blank?(body)

        model      = resource.model
        properties = model.properties(repository_name)

        parse_record(body, model).each do |key, value|
          if property = properties[key.to_sym]
            property.set!(resource, value)
          end
        end
      end
      
      def string_representation(resource)
        raise NotImplementedError,
          "#{self.class}#string_representation not implemented"
      end
      
      def parse_collection(body, model)
        raise NotImplementedError,
          "#{self.class}#parse_collection not implemented"
      end
      
      def parse_record(body, model)
        raise NotImplementedError,
          "#{self.class}#parse_record not implemented"
      end
    end
  end
end
