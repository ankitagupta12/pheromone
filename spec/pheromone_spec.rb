require 'spec_helper'

describe Pheromone do
  with_model :PublishableModel do
    table do |t|
      t.string :name
      t.string :type
      t.timestamps null: false
    end

    # The model block works just like the class definition.
    model do
      include Publishable
      def message
        { name: name }
      end

      def name
        'sample'
      end

      def type
        'mock'
      end

      publish on: :after_save,
              message_options: [
                {
                  event_types: [:create, :update],
                  topic: :topic1,
                  message: ->(obj) { { name: obj.name } }
                },
                {
                  event_types: [:create, :update],
                  topic: :topic1,
                  message: -> {},
                },
                {
                  event_types: [:create, :update],
                  topic: :topic1,
                  serializer: Class.new(BaseSerializer) { attributes :name, :type },
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
              ]
    end
  end

  let(:model_create_messages) do
    [
      {
        event: 'create',
        entity: 'PublishableModel',
        timestamp: @timestamp,
        blob: { name: 'sample', type: 'mock' }
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
        blob: { name: 'sample' }
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
          blob: { name: 'sample', type: 'mock' }
        }.to_json,
        {
          event: 'update',
          entity: 'PublishableModel',
          timestamp: @timestamp,
          blob: { name: 'sample' }
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

      @timestamp = Time.zone.local(2015, 3, 12, 8, 30)
    end

    context 'create' do
      before do
        expect(Bugsnag).to receive(:notify).twice
        Timecop.freeze(@timestamp) { @model = PublishableModel.create }
      end

      it 'sends messages on create' do
        expect(@invocation_count).to eq(3)
        expect(@topics).to match_array([:topic1, :topic2])
        expect(@messages).to match_array(model_create_messages)
      end
    end

    context 'update' do
      before do
        expect(Bugsnag).to receive(:notify).thrice
        Timecop.freeze(@timestamp) { @model = PublishableModel.create }
      end
      it 'sends messages on update' do
        Timecop.freeze(@timestamp) { @model.update!(name: 'new name') }
        expect(@invocation_count).to eq(5)
        expect(@topics).to match_array([:topic1, :topic2])
        expect(@messages).to match_array(model_update_messages)
      end
    end
  end

  context 'connectivity issues to Kafka' do
    it 'attermpts to reset the waterdrop connection pool' do
      allow(WaterDrop::Message).to receive(:new).and_raise(Kafka::DeliveryFailed)
      expect(WaterDrop::Pool).to receive(:reset_pool).exactly(6).times
      PublishableModel.create
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
