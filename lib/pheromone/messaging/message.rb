# Encapsulates WaterDrop::Message
module Pheromone
  module Messaging
    class Message
      def initialize(topic:, blob:, metadata: {}, options: {}, encoder: nil)
        @topic = topic
        @blob = blob
        @options = options || {}
        @metadata = metadata || {}
        @encoder = encoder
      end

      attr_reader :topic, :blob, :options, :metadata

      def send!
        binding.pry
        WaterDrop::SyncProducer.call(
          MessageFormatter.new({ metadata: @metadata, blob: @blob }, encoder: @encoder).format,
          { topic: topic.to_s }.merge!(options)
        )
      end
    end
  end
end