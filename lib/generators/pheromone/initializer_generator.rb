require 'rails/generators'
module Pheromone
  # creates job depedency initializer
  class InitializerGenerator < Rails::Generators::Base
    def create_initializer
      create_file(
          'config/initializers/pheromone.rb',
          "Pheromone.setup do |config|\n"\
          "  # config.background_processor.name = ':resque / :sidekiq'\n"\
          "  # config.background_processor.klass = 'BackgroundWorker'\n"\
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
      )
    end
  end
end