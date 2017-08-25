require 'pheromone/exceptions/unsupported_message_format'
module Pheromone
  module Messaging
    class MessageFormatter
      SUPPORTED_MESSAGE_FORMATS = [:json].freeze

      def initialize(message)
        @message = message
      end

      def format
        if Pheromone.config.message_format == :json
          convert_to_time_format.to_json
        elsif !SUPPORTED_MESSAGE_FORMATS.include?(Pheromone.config.message_format)
          raise Pheromone::Exceptions::UnsupportedMessageFormat.new
        end
      end

      private

      # recursively converts time to the timezone set in configuration
      def convert_to_time_format
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