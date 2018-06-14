require 'spec_helper'
require 'pheromone/messaging/message'
describe Pheromone::Messaging::Message do
  before do
    Pheromone::Config.configure do |config|
      config.message_format = :json
      config.timezone = 'Singapore'
      WaterDrop::Config.configure do |waterdrop_config|
        waterdrop_config.deliver = false
      end
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
    @options = { key: 'key' }
    @topic = :test
  end

  around { |example| Timecop.freeze(Time.local(2015, 7, 14, 10, 10), &example) }

  context 'no metadata is provided' do
    it 'uses default metadata' do
      message_object = described_class.new(
        topic: @topic,
        blob: @message,
        options: @options,
        encoder: nil,
        message_format: nil
      )
      expect(WaterDrop::SyncProducer).to receive(:call).with(
        {
          'metadata' => {},
          'blob' => {
            'server_time' => nil,
            'message_data' => {
              'event_time' => '2015-07-14T10:10:00.000+08:00',
              'text' => 'message_text'
            }
          }
        }.to_json,
        { topic: 'test' }.merge!(@options)
      )
      message_object.send!
    end
  end

  context 'no options are provided' do
    it 'uses default options' do
      message_object = described_class.new(
        topic: @topic,
        blob: @message,
        metadata: @meta_data,
        encoder: nil,
        message_format: nil
      )
      expect(WaterDrop::SyncProducer).to receive(:call).with(
        {
          'metadata' => { 'event_name' => 'create' },
          'blob' => {
            'server_time' => nil,
            'message_data' => {
              'event_time' => '2015-07-14T10:10:00.000+08:00',
              'text' => 'message_text'
            }
          }
        }.to_json,
        topic: 'test'
      )
      message_object.send!
    end
  end

  context 'both metadata and options are provided' do
    it 'sends all the message data to waterdrop' do
      message_object = described_class.new(
        topic: @topic,
        blob: @message,
        metadata: @meta_data,
        options: @options,
        encoder: nil,
        message_format: nil
      )
      expect(WaterDrop::SyncProducer).to receive(:call).with(
        {
          'metadata' => { 'event_name' => 'create' },
          'blob' => {
            'server_time' => nil,
            'message_data' => {
              'event_time' => '2015-07-14T10:10:00.000+08:00',
              'text' => 'message_text'
            }
          }
        }.to_json,
        { topic: 'test' }.merge!(@options)
      )
      message_object.send!
    end
  end
end