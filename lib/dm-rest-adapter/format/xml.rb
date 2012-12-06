module DataMapperRest
  module Format
    class Xml < AbstractFormat
      def default_options
        DataMapper::Mash.new({ :mime => "application/xml", :extension => "xml" })
      end
      
      def string_representation(resource)
        resource.to_xml
      end
      
      def parse_collection(xml, model)
        doc = REXML::Document::new(xml)
        
        field_to_property = Hash[ model.properties(repository_name).map { |p| [ p.field, p ] } ]
        element_name = element_name(model)
        doc.elements.collect("/#{DataMapper::Inflector.pluralize(resource_name(model))}/#{element_name}") do |entity_element|
          record_from_rexml(entity_element, field_to_property)
        end
      end
      
      def parse_record(xml, model)
        doc = REXML::Document::new(xml)

        element_name = element_name(model)

        unless entity_element = REXML::XPath.first(doc, "/#{element_name}")
          raise "No root element matching #{element_name} in xml"
        end

        field_to_property = Hash[ model.properties(model.default_repository_name).map { |p| [ p.field, p ] } ]
        record_from_rexml(entity_element, field_to_property)
      end

      private
      
      def record_from_rexml(entity_element, field_to_property)
        record = {}

        entity_element.elements.map do |element|
          field = element.name.to_s.tr('-', '_')
          next unless property = field_to_property[field]
          record[property.name.to_s] = property.typecast(element.text)
        end

        record
      end

      def element_name(model)
        DataMapper::Inflector.singularize(model.storage_name(model.default_repository_name))
      end
    end
  end
end
