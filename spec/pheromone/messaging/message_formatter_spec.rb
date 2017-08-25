require 'spec_helper'
require 'pheromone/config'
require 'pheromone/messaging/message_formatter'

describe Pheromone::Messaging::MessageFormatter do
  context 'unsupported message format' do
    before do
      Pheromone::Config.configure do |config|
        config.message_format = :xml
      end
    end
    it 'raises an error' do
      expect do
        described_class.new('message').format
      end.to raise_error(
        Pheromone::Exceptions::UnsupportedMessageFormat,
        'Message format not supported'
      )
    end
  end

  context 'supported message format' do
    before do
      Pheromone::Config.configure do |config|
        config.message_format = :json
        config.timezone = 'Singapore'
      end
    end
    it 'formats the message to json format' do
      expect(
        described_class.new('{ message: 1 }').format
      ).to eq("\"{ message: 1 }\"")
    end

    let(:result) do
      described_class.new(
        current_time: Time.parse('2017-08-24 09:27:33 UTC'),
        time_array: [ Time.parse('2017-08-24 10:00 UTC') ],
        message: {
          blob: 'blob',
          time: { now: Time.parse('2017-08-24 10:00 UTC') }
        }
      ).format
    end

    it 'transforms all fields to the specified time format' do
      expect(JSON.parse(result)).to eq({
        'current_time' => '2017-08-24T17:27:33.000+08:00',
        'message' => {
          'blob' => 'blob', 'time' => { 'now' => '2017-08-24T18:00:00.000+08:00' } },
        'time_array' => ['2017-08-24T18:00:00.000+08:00'],
      })
    end
  end
end