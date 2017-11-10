require 'resque'
require 'sidekiq'
require 'spec_helper'
require 'pheromone/messaging/message'
require 'pheromone/config'

describe Pheromone::Messaging::MessageDispatcher do
  let(:message_parameters) do
    {
      topic: :test_topic,
      blob: 'test_message'
    }
  end

  context 'using async dispatch method' do
    context 'using resque' do
      before do
        @klass = @message = nil
        class ResqueJob
          @queue = :low

          def self.perform(topic:, message:, metadata: {}, options: {})
            Pheromone::Messaging::Message.new(
              topic: topic,
              blob: message,
              metadata: metadata,
              options: options
            ).send!
          end
        end
        Pheromone::Config.configure do |config|
          config.background_processor.name = :resque
          config.background_processor.klass = 'ResqueJob'
          config.message_format = :json
        end

        expect(Resque).to receive(:enqueue) do |klass, message|
          @klass = klass
          @message = message
        end
      end

      it 'invokes perform on resque job with message fields' do
        described_class.new(
          message_parameters: message_parameters,
          dispatch_method: :async
        ).dispatch
        expect(@klass).to eq(ResqueJob)
        expect(@message[:topic]).to eq(:test_topic)
        expect(@message[:blob]).to eq('test_message')
        expect(@message[:options]).to eq({})
      end
    end

    context 'using sidekiq' do
      before do
        @message = nil
        class SidekiqWorker
          include Sidekiq::Worker

          def perform(topic:, message:, metadata: {}, options: {})
            Pheromone::Messaging::Message.new(
              topic: topic,
              blob: message,
              metadata: metadata,
              options: options
            ).send!
          end
        end

        Pheromone::Config.configure do |config|
          config.background_processor.name = :sidekiq
          config.background_processor.klass = 'SidekiqWorker'
          config.message_format = :json
        end

        expect(SidekiqWorker).to receive(:perform_async) do |message|
          @message = message
        end
      end
      it 'invokes perform_async on sidekiq job with message fields' do
        described_class.new(
          message_parameters: message_parameters,
          dispatch_method: :async
        ).dispatch
        expect(@message[:topic]).to eq(:test_topic)
        expect(@message[:blob]).to eq('test_message')
        expect(@message[:options]).to eq({})
      end
    end
  end

  context 'using sync dispatch method' do
    before do
      @topic = @message = @options = nil
      instance_double = double(send!: nil)
      Pheromone::Config.configure do |config|
        config.message_format = :json
      end

      expect(WaterDrop::SyncProducer).to receive(:call) do |message, options|
        @topic = options[:topic]
        @message = message
        @options = options.except(:topic)
      end.and_return(instance_double)
    end

    around { |example| Timecop.freeze(Time.local(2015, 7, 14, 10, 10), &example) }

    it 'sends message using waterdrop' do
      described_class.new(
        message_parameters: message_parameters,
        dispatch_method: :sync
      ).dispatch
      expect(@topic).to eq('test_topic')
      expect(@message).to eq(
        "{\"timestamp\":\"2015-07-14T02:10:00.000Z\",\"blob\":\"test_message\"}"
      )
      expect(@options).to eq({})
    end
  end
end
