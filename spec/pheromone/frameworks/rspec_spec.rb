require 'spec_helper'
require 'active_model_serializers'

describe Pheromone::Publishable do
  class BaseSerializer < ActiveModel::Serializer
    attributes :title

    def title
      'title'
    end
  end

  with_model :PublishableModel do
    table do |t|
      t.string :name
      t.string :type
      t.boolean :condition, default: false
      t.timestamps null: false
    end

    # The model block works just like the class definition.
    model do
      include Pheromone::Publishable

      def message
        { name: name }
      end

      def type
        'mock'
      end

      publish [
        {
          event_types: %i(create update),
          topic: 'topic1',
          message: ->(obj) { { name: obj.name } }
        }
      ]
    end
  end

  context 'publishable is not used' do
    before do
      Pheromone::Config.configure do |config|
        config.message_format = :json
        config.timezone = 'UTC'
      end

      @invocation_count = 0
      allow(WaterDrop::SyncProducer).to receive(:call) do
        @invocation_count += 1
      end
    end

    it 'does not send messages to kafka' do
      PublishableModel.create
      expect(@invocation_count).to eq(0)
    end
  end

  context 'publishable is used' do
    before do
      Pheromone::Config.configure do |config|
        config.message_format = :json
        config.timezone = 'UTC'
      end

      @invocation_count = 0
      allow(WaterDrop::SyncProducer).to receive(:call) do
        @invocation_count += 1
      end
    end

    it 'sends messages to kafka', publishable: true do
      PublishableModel.create
      expect(@invocation_count).to eq(1)
    end
  end
end