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
                  "Pheromone.setup do |pheromone_config|\n"\
                  "  # pheromone_config.background_processor.name = ':resque / :sidekiq'\n"\
                  "  # pheromone_config.background_processor.klass = 'BackgroundWorker'\n"\
                  "  # pheromone_config.timezone = 'UTC'\n"\
                  "  pheromone_config.message_format = :json\n"\
                  "  WaterDrop.setup do |waterdrop_config|\n"\
                  "    waterdrop_config.send_messages = Rails.env.production?\n"\
                  "    waterdrop_config.connection_pool.size = 20\n"\
                  "    waterdrop_config.connection_pool.timeout = 1\n"\
                  "    waterdrop_config.kafka.seed_brokers = [Rails.env.production? ? ENV['KAFKA_HOST'] : 'localhost:9092']\n"\
                  "    waterdrop_config.raise_on_failure = Rails.env.production?\n"\
                  "  end\n"\
                  "end"\
    end
  end
end