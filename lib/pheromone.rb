require 'pheromone/publishable'
require 'pheromone/config'
require 'pheromone/messaging/message'
require 'rails/railtie'
require 'waterdrop'

module Pheromone
  class << self
    # return config
    def config
      Config.config
    end

    def enabled?
      Pheromone.config.enabled
    end

    # Provides a block to override default config
    def setup(&block)
      Config.setup(&block)
    end
  end
end

