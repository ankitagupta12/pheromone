require 'pheromone'
require 'pheromone/messaging/message_formatter'
require 'pheromone/messaging/message'

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
        return unless Pheromone.enabled?
        if @dispatch_method == :sync
          Message.new(
            message_body.merge!(
              encoder: @message_parameters[:encoder],
              message_format: @message_parameters[:message_format]
            )
          ).send!
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
          Resque.enqueue(background_processor_klass, message_body)
        elsif background_processor.name == :sidekiq
          background_processor_klass.perform_async(message_body)
        end
      end

      def message_body
        {
          topic: @message_parameters[:topic],
          blob: @message_parameters[:blob],
          metadata: @message_parameters[:metadata],
          options: @message_parameters[:producer_options] || {},
          embed_blob: @message_parameters[:embed_blob]
        }
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