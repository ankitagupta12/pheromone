require 'pheromone/exceptions/unsupported_message_format'
module Pheromone
  module Messaging
    class MessageFormatter
      include Pheromone::MethodInvoker
      SUPPORTED_MESSAGE_FORMATS = [:json, :with_encoding].freeze

      def initialize(message, encoder, format)
        @message = message
        @encoder = encoder
        @message_format = format
      end

      def format
        if message_format == :json
          message_with_time_conversion.to_json
        elsif message_format == :with_encoding
          call_proc_or_instance_method(
            @encoder,
            message_with_time_conversion.with_indifferent_access
          )
        elsif !SUPPORTED_MESSAGE_FORMATS.include?(Pheromone.config.message_format)
          raise Pheromone::Exceptions::UnsupportedMessageFormat.new
        end
      end

      private

      def message_format
        @message_format || Pheromone.config.message_format
      end

      # recursively converts time to the timezone set in configuration
      def message_with_time_conversion
        deep_transform_values!(@message) do |value|
          if value.is_a? Time
            value.in_time_zone(Pheromone.config.timezone)
          else
            value
          end
        end
      end

      # recursively applies a block to a hash
      def deep_transform_values!(object, &block)
        case object
          when Array
            object.map! { |element| deep_transform_values!(element, &block) }
          when Hash
            object.each do |key, value|
              object[key] = deep_transform_values!(value, &block)
            end
          else
            yield object
        end
      end
    end
  end
end