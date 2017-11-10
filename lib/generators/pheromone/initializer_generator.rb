require 'rails/generators'
module Pheromone
  # creates job depedency initializer
  class InitializerGenerator < Rails::Generators::Base
    def create_initializer
      create_file(
          'config/initializers/pheromone.rb',
          "Pheromone.setup do |pheromone_config|\n"\
          "  # pheromone_config.background_processor.name = ':resque / :sidekiq'\n"\
          "  # pheromone_config.background_processor.klass = 'BackgroundWorker'\n"\
          "  # pheromone_config.timezone = 'UTC'\n"\
          "  pheromone_config.message_format = :json\n"\
          "  WaterDrop.setup do |waterdrop_config|\n"\
          "    waterdrop_config.deliver = Rails.env.production?\n"\
          "    waterdrop_config.kafka.seed_brokers = [Rails.env.production? ? ENV['KAFKA_HOST'] : 'localhost:9092']\n"\
          "  end\n"\
          "end"\
      )
    end
  end
end