require 'pheromone/version'
require 'pheromone/options_validator'
require 'active_support'
require 'waterdrop'
# Usage: For publishing messages to kafka, include this concern
# in the model and then add
#
#  include Publishable
#  publish message_options: [
#            {
#              topic: :topic1,
#              event_types: [:create, :update],
#              message: { a: 1, b: 2 }
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
module Pheromone
  extend ActiveSupport::Concern

  # class methods for the model including Publishable
  module ClassMethods
    def publish(message_options)
      errors = OptionsValidator.new(message_options).validate
      raise "Errors: #{errors}" unless errors.empty?
      __send__(:after_commit, proc { dispatch_messages(message_options: message_options) })
    end
  end

  def dispatch_messages(message_options:)
    message_options.each do |options|
      next unless check_conditions(options)
      begin
        send_message(options)
      rescue => error
        puts error
      end
    end
  end

  private

  def check_conditions(options)
    condition_callback = options[:if]
    return check_event(options) unless condition_callback
    call_proc_or_instance_method(condition_callback)
  end

  def check_event(options)
    options[:event_types].any? { |event| event == current_event }
  end

  def send_message(options)
    WaterDrop::Message.new(
      options[:topic],
      message_meta_data.merge!(blob: message_blob(options)).to_json
    ).send!
  end

  def message_meta_data
    {
      event: current_event,
      entity: self.class.name,
      timestamp: Time.now
    }
  end

  def current_event
    id_previously_changed? ? :create : :update
  end

  def message_blob(options)
    message = options[:message]
    return call_proc_or_instance_method(message) if message
    options[:serializer].new(self, options[:serializer_options] || {}).serializable_object
  end

  # This method has the :reek:ManualDispatch smell,
  # which is difficult to avoid since it handles
  # either a lambda/Proc or a named method from the including
  # class.
  def call_proc_or_instance_method(proc_or_symbol)
    return proc_or_symbol.call(self) if proc_or_symbol.respond_to?(:call)
    unless respond_to? proc_or_symbol
      raise "Method #{proc_or_symbol} not found for #{self.class.name}"
    end
    __send__(proc_or_symbol)
  end
end
