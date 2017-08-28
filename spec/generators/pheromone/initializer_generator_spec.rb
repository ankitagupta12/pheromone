require 'generator_spec/test_case'
require 'generators/pheromone/initializer_generator'

describe Pheromone::InitializerGenerator, type: :generator do
  include GeneratorSpec::TestCase
  destination File.expand_path('../tmp', __FILE__)

  after(:all) { prepare_destination }

  context '#create_initializer' do
    before(:all) do
      prepare_destination
      run_generator
    end

    it 'creates pheromone initializer' do
      assert_file 'config/initializers/pheromone.rb',
                  "Pheromone.setup do |config|\n"\
                  "  # config.background_processor.name = ':resque / :sidekiq'\n"\
                  "  # config.background_processor.klass = 'Pheromone::Jobs::ResqueBaseJob'\n"\
                  "  # config.timezone = 'UTC'\n"\
                  "  config.message_format = :json\n"\
                  "  WaterDrop.setup do |config|\n"\
                  "    config.send_messages = Rails.env.production?\n"\
                  "    config.connection_pool_size = 20\n"\
                  "    config.connection_pool_timeout = 1\n"\
                  "    config.kafka.hosts = [Rails.env.production? ? ENV['KAFKA_HOST'] : 'localhost:9092']\n"\
                  "    config.raise_on_failure = Rails.env.production?\n"\
                  "  end\n"\
                  "end"\
    end
  end
end