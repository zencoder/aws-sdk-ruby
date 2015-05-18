module Aws
  module Api
    module Docs
      class OperationDocumenter

        include Seahorse::Model
        include Utils

        # @param [YARD::CodeObject::Base] namespace
        def initialize(namespace)
          @namespace = namespace
          @optname = 'params'
        end

        # @param [Symbol] method_name
        # @param [Seahorse::Model::Opeation] operation
        def document(method_name, operation)
          m = YARD::CodeObjects::MethodObject.new(@namespace, method_name)
          m.group = 'API Operations'
          m.scope = :instance
          m.parameters << [@optname, '{}']
          m.docstring = operation.documentation
          tags(method_name, operation).each do |tag|
            m.add_tag(tag)
          end
        end

        private

        def tags(method_name, operation)
          tags = []
          tags += param_tags(method_name, operation)
          tags += option_tags(method_name, operation)
          tags += return_tags(method_name, operation)
          tags += example_tags(method_name, operation)
          tags += see_also_tags(method_name, operation)
        end

        def param_tags(method_name, operation)
          []
        end

        def option_tags(method_name, operation)
          if operation.input
            operation.input.shape.members.map do |name, ref|
              req = ref.required ? 'required,' : ''
              type = input_type(ref)
              tag("@option #{@optname} [#{req}#{type}] :#{name} #{ref.documentation}")
            end
          else
            []
          end
        end

        def return_tags(method_name, operation)
          ref = operation.output ? output_type(operation.output) : 'EmptyStructure'
          resp_type = '{Seahorse::Client::Response response}'
          desc = "Returns a #{resp_type} object where the data is a {#{ref}}."
          [tag("@return [#{ref}] #{desc}")]
        end

        def example_tags(method_name, operation)
          [
            RequestSyntaxExample.tag(method_name, operation),
            ResponseStructureExample.tag(method_name, operation),
          ]
        end

        def see_also_tags(method_name, operation)
          []
        end

      end
    end
  end
end