require 'spec_helper'

describe Pheromone do
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
      include Pheromone

      def message
        { name: name }
      end

      def name
        'sample'
      end

      def type
        'mock'
      end

      publish [
        {
          event_types: %i(create update),
          topic: :topic1,
          message: ->(obj) { { name: obj.name } }
        },
        {
          event_types: %i(create update),
          topic: :topic1,
          message: -> {}
        },
        {
          event_types: [:create, :update],
          topic: :topic1,
          serializer: BaseSerializer,
          serlializer_options: { scope: '' }
        },
        {
          event_types: [:create],
          topic: :topic2,
          message: :message
        },
        {
          event_types: [:create],
          topic: :topic3,
          message: :message1
        },
        {
          event_types: [:create],
          topic: :topic4,
          if: ->(data) { data.condition },
          message: :message
        },
        {
          event_types: [:update],
          topic: :topic5,
          if: ->(data) { data.condition },
          message: :message
        }
      ]
    end
  end

  let(:model_create_messages) do
    [
      {
        event: 'create',
        entity: 'PublishableModel',
        timestamp: @timestamp,
        blob: { name: 'sample' }
      }.to_json,
      {
        event: 'create',
        entity: 'PublishableModel',
        timestamp: @timestamp,
        blob: { name: 'sample' }
      }.to_json,
      {
        event: 'create',
        entity: 'PublishableModel',
        timestamp: @timestamp,
        blob: { title: 'title' }
      }.to_json
    ]
  end

  let(:model_update_messages) do
    model_create_messages.concat(
      [
        {
          event: 'update',
          entity: 'PublishableModel',
          timestamp: @timestamp,
          blob: { name: 'sample' }
        }.to_json,
        {
          event: 'update',
          entity: 'PublishableModel',
          timestamp: @timestamp,
          blob: { title: 'title' }
        }.to_json
      ]
    )
  end
  context 'callback chain succeeds' do
    before do
      @invocation_count = 0
      @topics = Set.new
      @messages = []
      allow(WaterDrop::Message).to receive(:new) do |topic, message, _|
        @invocation_count += 1
        @topics << topic
        @messages << message
        double(send!: nil)
      end

      @timestamp = Time.local(2015, 3, 12, 8, 30)
    end

    context 'create' do
      before do
        Timecop.freeze(@timestamp) { @model = PublishableModel.create }
      end

      it 'sends messages on create' do
        expect(@invocation_count).to eq(3)
        expect(@topics).to match_array(%i(topic1 topic2))
        expect(@messages).to match_array(model_create_messages)
      end
    end

    context 'update' do
      before do
        Timecop.freeze(@timestamp) { @model = PublishableModel.create }
      end
      it 'sends messages on update' do
        Timecop.freeze(@timestamp) { @model.update!(name: 'new name') }
        expect(@invocation_count).to eq(5)
        expect(@topics).to match_array([:topic1, :topic2])
        expect(@messages).to match_array(model_update_messages)
      end
    end
    context 'conditional publish' do
      before { Timecop.freeze(@timestamp) { @model = PublishableModel.create(condition: true) } }
      it 'sends an extra message when events and condition matches' do
        expect(@topics).to match_array(%i(topic1 topic2 topic4 topic5))
      end
    end
  end

  context 'callback chain fails' do
    before do
      @invocation_count = 0
      allow(WaterDrop::Message).to receive(:new) do
        @invocation_count += 1
        double(send!: nil)
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
      expect(@invocation_count).to eq(3)
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
end
