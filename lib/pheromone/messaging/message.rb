# Encapsulates WaterDrop::Message
module Pheromone
  module Messaging
    class Message
      def initialize(topic:, blob:, metadata: {}, options: {}, encoder:, message_format:)
        @topic = topic
        @blob = blob
        @options = options || {}
        @metadata = metadata || {}
        @encoder = encoder
        @message_format = message_format
      end

      attr_reader :topic, :blob, :options, :metadata

      def send!
        WaterDrop::SyncProducer.call(
          MessageFormatter.new(
            { metadata: @metadata, blob: @blob },
            @encoder,
            @message_format
          ).format,
          { topic: topic.to_s }.merge!(options)
        )
      end
    end
  end
end