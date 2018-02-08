require 'pheromone/publishable'
require 'pheromone/config'
require 'pheromone/messaging/message'
require 'pheromone/frameworks/rspec'
require 'rails/railtie'
require 'waterdrop'

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

