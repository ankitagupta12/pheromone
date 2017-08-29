require 'waterdrop'

# Encapsulates WaterDrop::Message
module Pheromone
  module Messaging
    class Message
      def initialize(topic:, message:, metadata: {}, options: {})
        @topic = topic
        @message = message
        @options = options || {}
        @metadata = metadata || {}
      end

      attr_reader :topic, :message, :options, :metadata

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
          blob: @message
        )
      end
    end
  end
end