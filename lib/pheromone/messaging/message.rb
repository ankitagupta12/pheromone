require 'waterdrop'

# Encapsulates WaterDrop::Message
module Pheromone
  module Messaging
    class Message
      def initialize(topic:, message:, options: {})
        @topic = topic
        @message = MessageFormatter.new(message).format
        @options = options
      end

      attr_reader :topic, :message, :options

      def send!
        ::WaterDrop::Message.new(topic, message, options).send!
      end
    end
  end
end