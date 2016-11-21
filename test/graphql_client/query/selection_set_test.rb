require 'test_helper'

module GraphQL
  module Client
    module Query
      class SelectionSetTest < Minitest::Test
        def setup
          schema_string = File.read(fixture_path('merchant_schema.json'))
          @schema = GraphQLSchema.new(schema_string)
        end

        def test_initializes_creates_empty_structures
          selection_set = SelectionSet.new

          assert_equal({}, selection_set.fields)
          assert_equal({}, selection_set.fragments)
          assert_equal [], selection_set.inline_fragments
          assert_equal [], selection_set.selections
        end

        def test_add_field_adds_query_fields_to_fields_hash
          selection_set = SelectionSet.new
          document = Document.new(@schema)
          field = @schema.query_root.fields.fetch('shop')
          query_field = QueryField.new(field, document: document)

          selection_set.add_field(query_field)

          assert_equal({ 'shop' => query_field }, selection_set.fields)
          assert_equal [query_field], selection_set.selections
        end

        def test_add_fragment_adds_fragment_to_fragments_hash
          selection_set = SelectionSet.new
          document = Document.new(@schema)
          type = @schema.query_root.fields.fetch('shop').base_type
          fragment = Fragment.new('shopFields', type, document: document)

          selection_set.add_fragment(fragment)

          assert_equal({ 'shopFields' => fragment }, selection_set.fragments)
          assert_equal [fragment], selection_set.selections
        end

        def test_add_inline_fragment_adds_inline_fragment_to_array
          selection_set = SelectionSet.new
          document = Document.new(@schema)
          type = @schema.query_root.fields.fetch('shop').base_type
          inline_fragment = InlineFragment.new(type, document: document)

          selection_set.add_inline_fragment(inline_fragment)

          assert_equal [inline_fragment], selection_set.inline_fragments
          assert_equal [inline_fragment], selection_set.selections
        end

        def test_contains_checks_if_a_field_exists_by_name
          selection_set = SelectionSet.new
          document = Document.new(@schema)
          field = @schema.query_root.fields.fetch('shop')
          query_field = QueryField.new(field, document: document)

          selection_set.add_field(query_field)

          assert selection_set.contains?('shop')
        end

        def test_empty_delegates_to_selections_array
          selection_set = SelectionSet.new

          assert selection_set.empty?
        end

        def test_empty_is_false_when_selections_exist
          selection_set = SelectionSet.new
          document = Document.new(@schema)
          field = @schema.query_root.fields.fetch('shop')
          query_field = QueryField.new(field, document: document)

          selection_set.add_field(query_field)

          refute selection_set.empty?
        end

        def test_to_query_builds_a_graphql_query_representation_of_the_selections
          selection_set = SelectionSet.new

          mock_field = Minitest::Mock.new
          mock_field.expect(:to_query, 'query string', [{ indent: '  ' }])

          selection_set.selections << mock_field

          assert_equal 'query string', selection_set.to_query
        end
      end
    end
  end
end