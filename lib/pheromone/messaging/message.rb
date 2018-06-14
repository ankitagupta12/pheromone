# Encapsulates WaterDrop::Message
module Pheromone
  module Messaging
    class Message
      def initialize(topic:, blob:, metadata: {}, options: {}, encoder:, message_format:, embed_blob:)
        @topic = topic
        @blob = blob
        @options = options || {}
        @metadata = metadata || {}
        @encoder = encoder
        @message_format = message_format
        @embed_blob = embed_blob
      end

      attr_reader :topic, :blob, :options, :metadata

      def send!
        WaterDrop::SyncProducer.call(
          MessageFormatter.new(
            message,
            @encoder,
            @message_format
          ).format,
          { topic: topic.to_s }.merge!(options)
        )
      end

      private

      def message
        if @embed_blob
          @metadata.merge!(blob: @blob)
        else
          { metadata: @metadata, blob: @blob }
        end
      end
    end
  end
end