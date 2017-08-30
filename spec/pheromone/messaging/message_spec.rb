require 'spec_helper'
require 'pheromone/messaging/message'
describe Pheromone::Messaging::Message do
  before do
    Pheromone::Config.configure do |config|
      config.message_format = :json
      config.timezone = 'Singapore'
    end
    @message = {
      server_time: Time.zone,
      message_data: {
        event_time: Time.now,
        text: 'message_text'
      }
    }
    @meta_data = {
      event_name: 'create'
    }
    @options = { max_retries: 5 }
    @topic = :test
  end

  around { |example| Timecop.freeze(Time.local(2015, 7, 14, 10, 10), &example) }

  context 'no metadata is provided' do
    it 'uses default metadata' do
      message_object = described_class.new(
        topic: @topic,
        blob: @message,
        options: @options
      )
      expect(WaterDrop::Message).to receive(:new).with(
        :test,
        {
          'timestamp' => '2015-07-14T10:10:00.000+08:00',
          'blob' => {
            'server_time' => nil,
            'message_data' => {
              'event_time' => '2015-07-14T10:10:00.000+08:00',
              'text' => 'message_text'
            }
          }
        }.to_json,
        { max_retries: 5 }
      ).and_return(double(send!: nil))
      message_object.send!
    end
  end

  context 'no options are provided' do
    it 'uses default options' do
      message_object = described_class.new(
        topic: @topic,
        blob: @message,
        metadata: @meta_data
      )
      expect(WaterDrop::Message).to receive(:new).with(
        :test,
        {
          'event_name' => 'create',
          'timestamp' => '2015-07-14T10:10:00.000+08:00',
          'blob' => {
            'server_time' => nil,
            'message_data' => {
              'event_time' => '2015-07-14T10:10:00.000+08:00',
              'text' => 'message_text'
            }
          }
        }.to_json,
        {}
      ).and_return(double(send!: nil))
      message_object.send!
    end
  end

  context 'both metadata and options are provided' do
    it 'sends all the message data to waterdrop' do
      message_object = described_class.new(
        topic: @topic,
        blob: @message,
        metadata: @meta_data,
        options: @options
      )
      expect(WaterDrop::Message).to receive(:new).with(
        :test,
        {
          'event_name' => 'create',
          'timestamp' => '2015-07-14T10:10:00.000+08:00',
          'blob' => {
            'server_time' => nil,
            'message_data' => {
              'event_time' => '2015-07-14T10:10:00.000+08:00',
              'text' => 'message_text'
            }
          }
        }.to_json,
        { max_retries: 5 }
      ).and_return(double(send!: nil))
      message_object.send!
    end
  end
end