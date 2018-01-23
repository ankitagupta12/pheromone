# Usage: For publishing messages to kafka, include this concern
# in the model and then add
#
#  publish message_options: [
#            {
#              topic: :topic1,
#              producer_options: {
#                max_retries: 5,
#                retry_backoff: 5,
#                compression_codec: :snappy,
#                compression_threshold: 10,
#                required_acks: 1
#              }
#              event_types: [:create, :update],
#              message: { a: 1, b: 2 }
#              dispatch_method: :async
#            },....
#          ]
#
# Each entry in message_options will be registered as a potential
# message to be published to kafka on the after_commit hook of the
# including model. message_options can take an optional if: key which
# accepts either a callback or an instance method name - which can be
# used to decide if the message should be published or not.
#
# To control how the model is serialized before being published to kafka
# either provide a Serializer via the `serializer` key or a callback or instance
# method name via the `message` key
require 'pheromone/validators/options_validator'
require 'pheromone/exceptions/invalid_publish_options'
require 'pheromone/method_invoker'
require 'pheromone/messaging/message_dispatcher'
module Pheromone
  module Publishable
    # class methods for the model including Publishable
    module ClassMethods
      def publish(message_options)
        errors = Pheromone::Validators::OptionsValidator.new(
          message_options
        ).validate
        raise Pheromone::Exceptions::InvalidPublishOptions.new(errors) unless errors.empty?
        __send__(
          :after_commit,
          proc { dispatch_messages(message_options: message_options, current_event: :create) },
          on: :create
        )
        __send__(
          :after_commit,
          proc { dispatch_messages(message_options: message_options, current_event: :update) },
          on: :update
        )
      end
    end

    module InstanceMethods
      include Pheromone::MethodInvoker

      def dispatch_messages(message_options:, current_event:)
        message_options.each do |options|
          next unless check_conditions(options, current_event)
          send_message(options, current_event)
        end
      end

      private

      def check_conditions(options, current_event)
        condition_callback = options[:if]
        result = check_event(options, current_event)
        return result unless condition_callback
        result && call_proc_or_instance_method(condition_callback)
      end

      def check_event(options, current_event)
        options[:event_types].any? { |event| event == current_event }
      end

      # Manages the actual formatting and sending of messages. By default messages are sent in
      # sync mode. To override this, provide dispatch_method as :async
      def send_message(options, current_event)
        Pheromone::Messaging::MessageDispatcher.new(
          message_parameters: {
            topic: options[:topic],
            blob: message_blob(options),
            metadata: message_meta_data(options, current_event),
            producer_options: options[:producer_options]
          },
          dispatch_method: options[:dispatch_method] || :sync
        ).dispatch
      end

      def message_meta_data(options, current_event)
        {
          event: current_event,
          entity: self.class.name
        }.merge(options[:metadata] || {})
      end

      def message_blob(options)
        message = options[:message]
        return call_proc_or_instance_method(message) if message
        options[:serializer].new(self, options[:serializer_options] || {}).serializable_hash
      end
    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end
  end
end