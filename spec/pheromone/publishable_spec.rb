require 'spec_helper'
require 'timecop'
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
        },
        {
          event_types: %i(create update),
          topic: 'topic1',
          message: ->(obj) { { name: obj.name } }
        },
        {
          event_types: [:create, :update],
          topic: 'topic1',
          serializer: BaseSerializer,
          serlializer_options: { scope: '' }
        },
        {
          event_types: [:create],
          topic: 'topic2',
          message: :message
        },
        {
          event_types: [:create],
          topic: 'topic3',
          message: :message
        },
        {
          event_types: [:create],
          topic: 'topic4',
          if: ->(data) { data.condition },
          message: :message,
          producer_options: { required_acks: 1 }
        },
        {
          event_types: [:update],
          topic: 'topic5',
          if: ->(data) { data.condition },
          message: :message
        },
        {
          event_types: [:create],
          topic: 'topic6',
          message: :message,
          metadata: { test: :metadata }
        },
      ]
    end
  end

  let(:create_message) do
    {
      metadata: {
        event: 'create',
        entity: 'PublishableModel',
        timestamp: '2015-03-12T00:30:00.000Z'
      },
      blob: { name: 'sample' }
    }
  end

  let(:update_message) do
    {
      metadata: {
        event: 'update',
        entity: 'PublishableModel',
        timestamp: '2015-03-12T00:30:00.000Z',
      },
      blob: { name: 'new name' }
    }
  end

  let(:metadata_message) do
    {
      metadata: {
        timestamp: '2015-03-12T00:30:00.000Z',
        test: 'metadata'
      },
      blob: { name: 'sample' }
    }
  end

  let(:default_metadata_message) do
    {
      event: :create,
      entity: 'PublishableModel'
    }
  end

  let(:model_create_messages) do
    [
      create_message,
      create_message,
      create_message.merge(blob: { title: 'title' }),
      create_message,
      create_message,
      metadata_message.tap do |message|
        message[:metadata] = default_metadata_message.merge(message[:metadata])
      end
    ].map(&:to_json)
  end

  let(:model_update_messages) do
    [
      create_message,
      create_message,
      create_message.merge(blob: { title: 'title' }),
      create_message,
      create_message,
      create_message,
      metadata_message.tap do |message|
        message[:metadata] = default_metadata_message.merge(message[:metadata])
      end,
      update_message,
      update_message,
      update_message.merge(blob: { title: 'title' }),
      update_message
    ].map(&:to_json)
  end

  before do
    Pheromone::Config.configure do |config|
      config.message_format = :json
      config.timezone = 'UTC'
    end
  end

  context 'callback chain succeeds' do
    let(:timestamp) { Time.local(2015, 3, 12, 8, 30) }
    context 'encoding options are not given' do
      let(:topics) { Set.new }
      let(:messages) { [] }
      let(:producer_options) { [] }

      before do
        Pheromone.config.enabled = true
        @invocation_count = 0
        allow(WaterDrop::SyncProducer).to receive(:call) do |message, options|
          @invocation_count += 1
          topics << options[:topic]
          messages << message
          producer_options << options.except(:topic)
          double(send!: nil)
        end
      end

      context 'create' do
        before do
          Timecop.freeze(timestamp) do
            @model = PublishableModel.create(name: 'sample')
          end
        end

        it 'sends messages on create' do
          expect(@invocation_count).to eq(6)
          expect(topics).to match_array(%w(topic1 topic2 topic3 topic6))
          expect(messages).to match_array(model_create_messages)
        end
      end

      context 'create' do
        before do
          Timecop.freeze(timestamp) do
            @model = PublishableModel.create(name: 'sample')
          end
        end

        it 'sends messages on create' do
          expect(@invocation_count).to eq(6)
          expect(topics).to match_array(%w(topic1 topic2 topic3 topic6))
          expect(messages).to match_array(model_create_messages)
        end
      end

      context 'update' do
        before do
          Timecop.freeze(timestamp) do
            @model = PublishableModel.create(condition: true, name: 'sample')
          end
        end
        it 'sends messages on update' do
          Timecop.freeze(timestamp) { @model.update!(name: 'new name') }
          expect(@invocation_count).to eq(11)
          expect(topics).to match_array(%w(topic1 topic2 topic3 topic4 topic5 topic6))
          expect(messages).to match(model_update_messages)
        end
      end

      context 'conditional publish' do
        before { Timecop.freeze(timestamp) { @model = PublishableModel.create(condition: true) } }
        it 'sends an extra message when events and condition matches' do
          expect(@invocation_count).to eq(7)
          expect(topics).to match_array(%w(topic1 topic2 topic3 topic4 topic6))
          expect(producer_options).to match_array(
            [{}, {}, {}, {}, {}, { required_acks: 1 }, {}]
          )
        end
      end
    end

    context 'encoding options are given' do
      with_model :PublishableModelWithEncoding do
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
              message: ->(obj) { { name: obj.name } },
              encoder: ->(message) { message.to_json },
              message_format: :with_encoding
            }
          ]
        end
      end

      before do
        Pheromone.config.enabled = true
        @messages = []
        allow(WaterDrop::SyncProducer).to receive(:call) do |message, _|
          @messages << message
          double(send!: nil)
        end
        Timecop.freeze(timestamp) { @model = PublishableModelWithEncoding.create(condition: true) }
      end

      it 'sends the specified encoding options to formatter' do
        expect(@messages).to eq([
          "{\"metadata\":{\"event\":\"create\""\
          ",\"entity\":\"PublishableModelWithEncoding\""\
          ",\"timestamp\":\"2015-03-12T00:30:00.000Z\"},\"blob\":{\"name\":null}}"
        ])
      end
    end

    context 'embed_blob option is ' do
      with_model :PublishableModelWithEmbedBlob do
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
              message: ->(obj) { { name: obj.name } },
              encoder: ->(message) { message.to_json },
              embed_blob: true,
              message_format: :with_encoding
            }
          ]
        end
      end

      before do
        Pheromone.config.enabled = true
        @messages = []
        allow(WaterDrop::SyncProducer).to receive(:call) do |message, _|
          @messages << message
          double(send!: nil)
        end
        Timecop.freeze(timestamp) { @model = PublishableModelWithEmbedBlob.create(condition: true) }
      end

      it 'sends the specified encoding options to formatter' do
        expect(@messages).to eq([
          "{\"event\":\"create\",\"entity\":\"PublishableModelWithEmbedBlob\""\
          ",\"timestamp\":\"2015-03-12T00:30:00.000Z\",\"blob\":{\"name\":null}}"
        ])
      end
    end
  end

  context 'callback chain fails' do
    before do
      Pheromone.config.enabled = true
      @invocation_count = 0
      allow(WaterDrop::SyncProducer).to receive(:call) do
        @invocation_count += 1
      end
    end

    it 'sends a message even if one of the after hook fails' do
      PublishableModel.class_eval do
        after_save :after_save_callback

        def after_save_callback
          false
        end
      end
      PublishableModel.create
      expect(@invocation_count).to eq(6)
      expect(PublishableModel.count).to eq(1)
    end

    it 'does not send a message if one of the before hook fails' do
      PublishableModel.class_eval do
        before_save :before_save_callback

        def before_save_callback
          throw :abort
        end
      end
      PublishableModel.create
      expect(PublishableModel.count).to eq(0)
      expect(@invocation_count).to eq(0)
    end
  end

  context 'pheromone is disabled' do
    before do
      Pheromone::Config.configure do |config|
        config.message_format = :json
        config.timezone = 'UTC'
        config.enabled = false
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
end
