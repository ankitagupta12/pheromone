require 'pheromone'
require 'pheromone/messaging/message_formatter'
require 'waterdrop'
# This module is used for sending messages to Kafka
# Dispatch method can be :sync or :async
# When dispatch_method is async, the message object is passed to a job
# the job needs to call `send!` on the WaterDrop::Message object
module Pheromone
  module Messaging
    class MessageDispatcher
      def initialize(message_parameters:, dispatch_method:)
        @message_parameters = message_parameters
        @dispatch_method = dispatch_method
      end

      def dispatch
        if @dispatch_method == :sync
          message.send!
        elsif @dispatch_method == :async
          send_message_asynchronously
        end
      end

      private

      # Allows sending messages via resque or sidekiq. WaterDrop::Message object
      # is passed and calling `send!` on the object will trigger producing
      # messages to Kafka
      def send_message_asynchronously
        if background_processor.name == :resque
          Resque.enqueue(background_processor_klass, message)
        elsif background_processor.name == :sidekiq
          background_processor_klass.perform_async(message)
        end
      end

      def message
        ::WaterDrop::Message.new(
          @message_parameters[:topic],
          MessageFormatter.new(
            @message_parameters[:message]
          ).format,
          @message_parameters[:producer_options] || {}
        )
      end

      def background_processor
        Pheromone.config.background_processor
      end

      def background_processor_klass
        @klass ||= background_processor.klass.constantize
      end
    end
  end
end