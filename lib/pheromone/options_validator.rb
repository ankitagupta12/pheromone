# frozen_string_literal: true
# validate message options provided to publish method in Publishable concern
class OptionsValidator
  ACCEPTED_EVENT_TYPES = %i(create update).freeze

  def initialize(message_options)
    @errors = {}
    @message_options = message_options
  end

  def validate
    validate_message_options
    return @errors if @errors.present?
    validate_topic
    validate_event_types
    validate_message_attributes
    @errors
  end

  private

  def validate_message_options
    return if @message_options.is_a?(Array)
    add_error_message(:message_options, 'Message options should be an array')
  end

  def validate_topic
    return if @message_options.all? { |options| options[:topic].present? }
    add_error_message(:topic, 'Topic name missing')
  end

  # :reek:FeatureEnvy
  def validate_event_types
    return if @message_options.all? do |options|
      event_types = options[:event_types]
      next true unless event_types
      event_types.present? &&
        event_types.is_a?(Array) &&
        (event_types - ACCEPTED_EVENT_TYPES).empty?
    end

    add_error_message(
      :event_types,
      "Event types must be a non-empty array with types #{ACCEPTED_EVENT_TYPES.join(',')}"
    )
  end

  def validate_message_attributes
    return if @message_options.all? do |options|
      options[:serializer].present? || options[:message].present?
    end

    add_error_message(:message_attributes, 'Either serializer or message should be specified')
  end

  def add_error_message(key, value)
    @errors.merge!(key => value)
  end
end
