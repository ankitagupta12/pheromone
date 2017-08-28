require 'resque'
require 'sidekiq'
require 'spec_helper'
require 'pheromone/config'
require 'pheromone/messaging/message_dispatcher'
require 'pheromone/jobs/sidekiq_base_job'
require 'pheromone/jobs/resque_base_job'

describe Pheromone::Messaging::MessageDispatcher do
  let(:message_parameters) do
    {
      topic: :test_topic,
      message: 'test_message'
    }
  end

  context 'using async dispatch method' do
    context 'using resque' do
      before do
        @klass = @message = nil

        Pheromone::Config.configure do |config|
          config.background_processor.name = :resque
          config.background_processor.klass = 'Pheromone::Jobs::ResqueBaseJob'
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
        expect(@klass).to eq(Pheromone::Jobs::ResqueBaseJob)
        expect(@message.topic).to eq(:test_topic)
        expect(@message.message).to eq("\"test_message\"")
        expect(@message.options).to eq({})
      end
    end

    context 'using sidekiq' do
      before do
        @message = nil
        Pheromone::Config.configure do |config|
          config.background_processor.name = :sidekiq
          config.background_processor.klass = 'Pheromone::Jobs::SidekiqBaseJob'
          config.message_format = :json
        end

        expect(Pheromone::Jobs::SidekiqBaseJob).to receive(:perform_async) do |message|
          @message = message
        end
      end
      it 'invokes perform_async on sidekiq job with message fields' do
        described_class.new(
          message_parameters: message_parameters,
          dispatch_method: :async
        ).dispatch
        expect(@message.topic).to eq(:test_topic)
        expect(@message.message).to eq("\"test_message\"")
        expect(@message.options).to eq({})
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

      expect(WaterDrop::Message).to receive(:new) do |topic, message, options|
        @topic = topic
        @message = message
        @options = options
      end.and_return(instance_double)
      expect(instance_double).to receive(:send!)
    end

    it 'sends message using waterdrop' do
      described_class.new(
        message_parameters: message_parameters,
        dispatch_method: :sync
      ).dispatch
      expect(@topic).to eq(:test_topic)
      expect(@message).to eq("\"test_message\"")
      expect(@options).to eq({})
    end
  end
end
