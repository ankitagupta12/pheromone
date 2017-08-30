require 'waterdrop'

# Encapsulates WaterDrop::Message
module Pheromone
  module Messaging
    class Message
      def initialize(topic:, blob:, metadata: {}, options: {})
        @topic = topic
        @blob = blob
        @options = options || {}
        @metadata = metadata || {}
      end

      attr_reader :topic, :blob, :options, :metadata

      def send!
        ::WaterDrop::Message.new(
          topic,
          MessageFormatter.new(full_message).format,
          options
        ).send!
      end

      private

      def full_message
        @metadata.merge!(
          timestamp: Time.now,
          blob: @blob
        )
      end
    end
  end
end