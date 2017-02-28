require 'pheromone/version'
require 'waterdrop'
require 'active_record'
require 'active_support'

module Pheromone
  extend ::ActiveSupport::Concern
  # Usage: For publishing messages to kafka, include this concern in the model and then add
  #  include Publishable
  #  publish on: :after_save,
  #          message_options: [
  #            {
  #              topic: :topic1,
  #              event_types: [:create, :update],
  #              serializer: OrderSerializer,
  #              serializer_options: { scope: '' }
  #            },
  #            {
  #              event_types: [:update],
  #              topic: :topic2,
  #              message: :function_name               # specify the name of instance method
  #            }
  #          ]

  NUMBER_RETRIES = 2

  def dispatch_messages(message_options:)
    message_options.each do |options|
      begin
        retries ||= 0
        send_message(options)
      rescue Kafka::DeliveryFailed
        retry if (retries += 1) < NUMBER_RETRIES
      rescue => error
        raise error
      end
    end
  end

  private

  def current_events(event_types)
    event_types.select { |type| event_type[type] }
  end

  def event_type
    {
      create: id_changed?,
      update: changes.present? && !changes.include?(:id)
    }
  end

  def message_meta_data(events)
    {
      event: events.join(','),
      entity: self.class.name,
      timestamp: Time.zone.now
    }
  end

  # This method has the :reek:ManualDispatch smell,
  # which is difficult to avoid since it handles
  # either a lambda/Proc or a named method from the including
  # class.
  def message_blob(options)
    message = options[:message]
    if message
      return message.call(self) if message.respond_to?(:call)
      raise "Method #{message} not found for #{self.class.name}" unless respond_to? :message
      return __send__(message)
    end
    options[:serializer].new(self, options[:serializer_options] || {}).serializable_object
  end

  def send_message(options)
    events = current_events(options[:event_types])
    return unless events.present?
    WaterDrop::Message.new(
      options[:topic],
      message_meta_data(events).merge!(blob: message_blob(options)).to_json
    ).send!
  end

  # class methods for the model including Publishable
  module ClassMethods
    def publish(on:, message_options:)
      errors = PublishableOptionsValidator.new(message_options).validate
      raise "Errors: #{errors}" unless errors.empty?
      __send__(on, proc { dispatch_messages(message_options: message_options) })
    end
  end
end

