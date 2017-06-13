# frozen_string_literal: true
require 'spec_helper'

describe OptionsValidator do
  context 'invalid fields' do
    it 'returns an error if message options are not an array' do
      message_options = {}
      expect(
        OptionsValidator.new(message_options).validate
      ).to match(message_options: 'Message options should be an array')
    end

    it 'returns an error message if topic name is missing' do
      message_options = [
        {
          topic: :topic1,
          event_types: %i(create update),
          message: { a: 1 }
        },
        {
          event_types: [:update],
          message: :function_name
        }
      ]
      expect(
        OptionsValidator.new(message_options).validate
      ).to match(topic: 'Topic name missing')
    end

    it 'returns an error message if event types are invalid' do
      message_options = [
        {
          topic: :topic1,
          event_types: %i(create update),
          message: { a: 1 }
        },
        {
          topic: :topic2,
          event_types: [:created],
          message: :function_name
        }
      ]

      expect(
        OptionsValidator.new(message_options).validate
      ).to match(event_types: 'Event types must be a non-empty array with types create,update')
    end

    it 'returns an error message if event types is empty' do
      message_options = [
        {
          topic: :topic1,
          event_types: %i(create update),
          message: { a: 1 }
        },
        {
          topic: :topic2,
          event_types: [],
          message: :function_name
        }
      ]

      expect(
        OptionsValidator.new(message_options).validate
      ).to match(event_types: 'Event types must be a non-empty array with types create,update')
    end

    it 'returns an error message if message attributes are missing' do
      message_options = [
        {
          topic: :topic1,
          event_types: %i(create update),
          message: { a: 1 }
        },
        {
          topic: :topic2,
          event_types: [:create]
        }
      ]

      expect(
        OptionsValidator.new(message_options).validate
      ).to match(message_attributes: 'Either serializer or message should be specified')
    end
  end

  context 'valid fields' do
    it 'returns no errors if topic, event type and message attributes are valid' do
      message_options = [
        {
          topic: :topic1,
          event_types: %i(create update),
          message: { a: 1 }
        },
        {
          topic: :topic2,
          event_types: [:create],
          message: :function_name
        },
        {
          topic: :topic3,
          message: :function_name
        }
      ]

      expect(OptionsValidator.new(message_options).validate).to be_empty
    end
  end
end
