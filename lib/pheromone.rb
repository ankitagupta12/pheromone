require 'pheromone/publishable'
require 'pheromone/config'
require 'pheromone/jobs/sidekiq_base_job'
require 'pheromone/jobs/resque_base_job'
require 'pheromone/messaging/message'

module Pheromone
  class << self
    # return config
    def config
      Config.config
    end

    # Provides a block to override default config
    def setup(&block)
      Config.setup(&block)
    end
  end
end

