# Copyright 2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require 'builder'
require 'base64'

module Aws
  module Xml
    # @api private
    class Builder

      include Seahorse::Model::Shapes

      # @param [Seahorse::Model::Shapes::Shape] rules
      def initialize(rules)
        @xml = []
        @builder = ::Builder::XmlMarkup.new(target: @xml, indent: 2)
        @rules = rules
      end

      # @param [Hash] params
      # @return [String] Returns an XML doc string.
      def to_xml(params)
        structure(@rules.serialized_name, @rules, params)
        @xml.join
      end

      # @param [Seahorse::Model::Shapes::Shape] rules
      # @param [Hash] params
      # @return [String] Returns an XML doc string.
      def self.to_xml(rules, params)
        new(rules).to_xml(params)
      end

      private

      def structure(name, shape, values)
        if values.empty?
         node(name, shape)
        else
          node(name, shape, structure_attrs(shape, values)) do
            shape.members.each_pair do |member_name, member_shape|
              if values.key?(member_name)
                next if xml_attribute?(member_shape)
                mname = member_shape.serialized_name
                member(mname, member_shape, values[member_name])
              end
            end
          end
        end
      end

      def structure_attrs(shape, values)
        shape.members.inject({}) do |attrs, (member_name, member_shape)|
          if xml_attribute?(member_shape) && values.key?(member_name)
            attrs[member_shape.serialized_name] = values[member_name]
          end
          attrs
        end
      end

      def list(name, shape, values)
        if shape.metadata['flattened']
          values.each do |value|
            member(name, shape.members, value)
          end
        else
          node(name, shape) do
            values.each do |value|
              mname = shape.members.serialized_name || 'member'
              member(mname, shape.members, value)
            end
          end
        end
      end

      def member(name, shape, value)
        case shape
        when StructureShape then structure(name, shape, value)
        when ListShape then list(name, shape, value)
        else node(name, shape, format(shape, value))
        end
      end

      def format(shape, value)
        case shape
        when TimestampShape then format_timestamp(shape, value.utc)
        when BlobShape then Base64.strict_encode64(value)
        else value.to_s
        end
      end

      def format_timestamp(shape, value)
        value = case shape
          when Iso8601TimestampShape then value.iso8601
          when Rfc822TimestampShape then value.rfc822
          when UnixTimestampShape then value.to_i
          else raise "invalid timestamp format `#{shape.class.name}'"
        end
      end

      # The `args` list may contain:
      #
      #   * [] - empty, no value or attributes
      #   * [value] - inline element, no attributes
      #   * [value, attributes_hash] - inline element with attributes
      #   * [attributes_hash] - self closing element with attributes
      #
      # Pass a block if you want to nest XML nodes inside.  When doing this,
      # you may *not* pass a value to the `args` list.
      #
      def node(name, shape, *args, &block)
        attrs = args.last.is_a?(Hash) ? args.pop : {}
        attrs = shape_attrs(shape).merge(attrs)
        args << attrs
        @builder.send(name, *args, &block)
      end

      def shape_attrs(shape)
        if xmlns = shape.metadata['xmlns_uri']
          prefix = shape.metadata['xmlns_prefix']
          attribute = 'xmlns'
          attribute += ':' + prefix if prefix
          { attribute => xmlns }
        else
          {}
        end
      end

      def xml_attribute?(shape)
        !!shape.metadata['xmlattribute']
      end

    end
  end
end