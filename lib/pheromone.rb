require 'pheromone/publishable'
require 'pheromone/config'

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

