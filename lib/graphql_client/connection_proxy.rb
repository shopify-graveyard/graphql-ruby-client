module GraphQL
  module Client
    class ConnectionProxy
      include Enumerable

      def initialize(parent:, client:, type:, field:)
        @parent = parent
        @client = client
        @type = type
        @field = field
        @objects = []

        @query = ConnectionQuery.new(parent: @parent, field: @field, return_type: @type, client: @client)
        fetch_page
      end

      def fetch_page
        query = @query.query
        initial_response = Request.new(client: @client).from_query(query)

        edges = deep_find(initial_response.data, 'edges')

        response = initial_response
        @objects = @objects + edges.map{|edge| edge['node']}
        while(has_next_page?(response.data))
          cursor = edges.last['cursor']
          response = Request.new(client: @client).from_query(@query.query(after: cursor))
          edges = deep_find(response.data, 'edges')
          @objects = @objects + edges.map{|edge| edge['node']}
        end
      end

      def deep_find(hash, target_key)
        return hash[target_key] if hash.key?(target_key)
        hash.each do |key, value|
          result = deep_find(value, target_key) if value.is_a? Hash
          return result unless result.nil?
        end

        nil
      end

      def has_next_page?(response_data)
        next_page = deep_find(response_data, 'hasNextPage')
        if next_page.nil?
          false
        else
          next_page
        end
      end

      def length
        entries.length
      end

      def each(&block)
        @objects.each do |node|
          yield node
        end
      end

      def create(attributes = {})
        input_block = ''
        attributes.each do |key, value|
          input_block << "#{key.to_s}: \"#{value}\"\n"
        end

        fields = @type.primitive_fields.keys.join(',')
        type_name = @type.name.camelize(:lower)

        mutation = "
          mutation {
            #{type_name}Create(
              input: {
                #{input_block}
              }
            ) {
              #{type_name} {
                #{fields}
              },
            userErrors {
              field,
              message
            }
          }
        }"

        request = Request.new(client: @client, type: @type)
        ObjectProxy.new(type: @type, properties: request.from_query(mutation).object[type_name], client: @client)
      end
    end
  end
end
