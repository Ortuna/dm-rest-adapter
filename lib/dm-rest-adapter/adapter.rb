module DataMapperRest
  # TODO: Specs for resource format parse errors (existing bug)

  class Adapter < DataMapper::Adapters::AbstractAdapter
    attr_accessor :rest_client, :format
    
    def create(resources)
      resources.each do |resource|
        model = resource.model

        path_items = extract_parent_items_from_resource(resource)
        path_items << { :model => model.storage_name(model.default_repository_name) }

        path = @format.resource_path(*path_items)
        
        DataMapper.logger.debug("About to POST using #{path}")
        
        response = @rest_client[path].post(
          @format.string_representation(resource),
          :content_type => @format.mime, :accept => @format.mime
        ) do |response, request, result, &block|
          
          DataMapper.logger.debug("Response to POST was #{response.inspect}")
          
          # See http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.2 for HTTP response 201
          if @options[:follow_on_create] && [201, 301, 302, 307].include?(response.code)
            response.args[:method] = :get
            response.args.delete(:payload)
            response.follow_redirection(request, result, &block)
          else
            response.return!(request, result, &block)
          end
        end

        @format.update_attributes(resource, response.body)
      end
    end

    def read(query)
      model = query.model

      path_items = extract_parent_items_from_query(query)
      DataMapper.logger.debug("Reading #{path_items}")
      
      records = []
      
      if id = extract_id_from_query(query)
        begin
          path_items << { :model => model, :key => id }
          path = @format.resource_path(*path_items)
          
          DataMapper.logger.debug("About to GET using #{path}")
          
          response = @rest_client[path].get(:accept => @format.mime)
          
          DataMapper.logger.debug("Response to GET was #{response.inspect}")
          
          records = [ @format.parse_record(response.body, model) ]
        rescue RestClient::ResourceNotFound
          DataMapper.logger.error("Resource was not found at #{path}. Response was #{response.inspect}")
          records = []
        end
      else
        path_items << { :model => model }
        query_options = { :accept => @format.mime }
        params = extract_params_from_query(query)
        query_options[:params] = params unless params.empty?
        
        path = @format.resource_path(*path_items)
        
        DataMapper.logger.debug("About to GET using #{path} with query_options of #{query_options.inspect}")
        
        response = @rest_client[path].get(query_options)
        
        DataMapper.logger.debug("Response to GET was #{response.inspect}")
        records = @format.parse_collection(response.body, model)
      end

      records
    end

    def update(dirty_attributes, collection)
      collection.select do |resource|
        model = resource.model
        key   = model.key
        id    = key.get(resource).first
        
        path_items = extract_parent_items_from_resource(resource)
        path_items << { :model => model, :key => id }

        dirty_attributes.each { |p, v| p.set!(resource, v) }

        response = @rest_client[@format.resource_path(*path_items)].put(
          @format.string_representation(resource),
          :content_type => @format.mime, :accept => @format.mime
        )

        @format.update_attributes(resource, response.body)
      end.size
    end

    def delete(collection)
      collection.select do |resource|
        model = resource.model
        key   = model.key
        id    = key.get(resource).first
        
        path_items = extract_parent_items_from_resource(resource)
        path_items << { :model => model, :key => id }
        
        response = @rest_client[@format.resource_path(*path_items)].delete(
          :accept => @format.mime
        )

        (200..207).include?(response.code)
      end.size
    end

    private

    def initialize(*)
      super
      
      DataMapper.logger.debug("Initializing REST adapter with #{@options.inspect}")
      
      raise ArgumentError, "Missing :format in @options" unless @options[:format]

      case @options[:format]
        when "xml"
          @format = Format::Xml.new(@options.merge(:repository_name => name))
          DataMapper.logger.debug("Using XML format")
        when "json"
          @format = Format::Json.new(@options.merge(:repository_name => name))
          DataMapper.logger.debug("Using JSON format")
        when String
          @format = load_format_from_string(@options[:format]).new(@options.merge(:repository_name => name))
          DataMapper.logger.debug("Using loaded format #{@format.inspect}")
        else
          @format = @options[:format]
          DataMapper.logger.debug("Using format of #{@format.inspect}")
      end
      
      if @options[:limit_param_name]
        @has_overridden_limit_param = !(@options[:limit_param_name].nil? or @options[:limit_param_name].empty?)
        DataMapper.logger.warn(":limit_param_name was given without specifying an actual parameter name!") unless @has_overridden_limit_param
         
        @limit_param_name = @options[:limit_param_name].to_sym
        DataMapper.logger.debug("Will use #{@limit_param_name} for a limit parameter")
      end
      
      if @options[:offset_param_name]
        @has_overridden_offset_param = !(@options[:offset_param_name].nil? or @options[:offset_param_name].empty?) 
        DataMapper.logger.warn(":offset_param_name was given without specifying an actual parameter name!") unless @has_overridden_offset_param
        
        @offset_param_name = @options[:offset_param_name].to_sym
        DataMapper.logger.debug("Will use #{@offset_param_name} for an offset parameter")
      end
      
      if @options[:disable_format_extension_in_request_url]
        @format.extension = nil
        DataMapper.logger.debug("Will not use format extension in requested URLs")
      end
      DataMapper.logger.debug("Initializing RestClient with #{normalized_uri}")
      @rest_client = RestClient::Resource.new(normalized_uri)
      @rest_client = STDOUT #if DataMapper.logger.level == 0
    end
    
    def load_format_from_string(class_name)
      canonical = if class_name.start_with?("::")
        class_name.gsub(/^::/, "")
      else
        class_name
      end
      
      canonical.split("::").reduce(Kernel) { |klass, name| klass.const_get(name) }
    end

    def normalized_uri
      @normalized_uri ||=
        begin
          Addressable::URI.new(
            :scheme       => @options[:scheme] || "http",
            :user         => @options[:user],
            :password     => @options[:password],
            :host         => @options[:host],
            :port         => @options[:port],
            :path         => @options[:path] || @options[:prefix],
            :fragment     => @options[:fragment]
          )
        end
    end

    def extract_id_from_query(query)
      return nil unless query.limit == 1

      conditions = query.conditions

      return nil unless conditions.kind_of?(DataMapper::Query::Conditions::AndOperation)
      return nil unless (key_condition = conditions.select { |o| o.subject.key? }).size == 1

      key_condition.first.value
    end
    
    # Note that ManyToOne denotes the child end of a 'has 1' or a 'has n' relationship
    def extract_parent_items_from_resource(resource)
      model = resource.model
      
      nested_relationship = model.relationships.detect do |relationship|
        relationship.kind_of?(DataMapper::Associations::ManyToOne::Relationship) &&
          relationship.inverse.options[:nested]
      end
      
      return [] unless nested_relationship
      
      path_items = if nested_relationship.loaded?(resource)
        extract_parent_items_from_resource(nested_relationship.get(resource))
      else
        []
      end
      
      path_items << {
        :model => nested_relationship.target_model,
        :key => nested_relationship.source_key.get(resource).first
      }.reject { |key, value| value.nil? }
    end
    
    # Note that ManyToOne denotes the child end of a 'has 1' or a 'has n' relationship
    def extract_parent_items_from_query(query)
      model = query.model
      conditions = query.conditions
      
      return [] unless conditions.kind_of?(DataMapper::Query::Conditions::AndOperation)
      
      nested_relationship_operand = conditions.detect do |operand|
        operand.kind_of?(DataMapper::Query::Conditions::EqualToComparison) &&
          operand.relationship? &&
          operand.subject.kind_of?(DataMapper::Associations::ManyToOne::Relationship) &&
          operand.subject.inverse.options[:nested]
      end
      
      return [] unless nested_relationship_operand
      
      nested_relationship = nested_relationship_operand.subject
      
      extract_parent_items_from_resource(nested_relationship_operand.value) << {
        :model => nested_relationship.target_model,
        :key => nested_relationship.target_key.get(nested_relationship_operand.value).first
      }.reject { |key, value| value.nil? }
    end

    def extract_params_from_query(query)
      model = query.model
      conditions = query.conditions
      params = {}

      return params unless conditions.kind_of?(DataMapper::Query::Conditions::AndOperation)
      return params if conditions.any? { |o| o.subject.respond_to?(:key?) && o.subject.key? }
      
      condition_params = extract_params_from_conditions(query)
      
      params.merge!(condition_params) if condition_params
      
      params[:order] = extract_order_by_from_query(query) unless query.order.empty?
      
      options = query.options
   
      if @has_overridden_limit_param and not options[:limit].nil?
        params[@limit_param_name] = options[:limit]
      end

      if @has_overridden_offset_param and not options[:offset].nil?
        params[@offset_param_name] = options[:offset]
      end
      
      params
    end
    
    def extract_params_from_conditions(query)
      params = []
      
      query.conditions.select{|c| c.kind_of?(DataMapper::Query::Conditions::EqualToComparison)}.each do |condition|
        if condition.relationship? && !condition.subject.inverse.options[:nested]
          params << { condition.foreign_key_mapping.subject.field.to_sym => condition.foreign_key_mapping.value }
        else
          params << { condition.subject.field.to_sym => condition.loaded_value }
        end
      end

      params.compact.reduce({}) { |memo, v| memo.merge(v) }
    end
    
    def extract_order_by_from_query(query)
      orders = []
      query.order.each do |order|
        orders << { order.target.field.to_sym => order.operator }
      end
      orders
    end
  end
end
