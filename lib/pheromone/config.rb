# frozen_string_literal: true
require 'dry-configurable'
module Pheromone
  # configurator for setting up all the configurable settings for pheromone
  class Config
    extend Dry::Configurable
    # accepts message format. Currently only accepts :json as the permitted value
    setting :message_format, :json
    setting :enabled, true
    setting :background_processor do
      # accepts :sidekiq or :resque as a value
      setting :name
      # specify the background job handling message send to kafka
      setting :klass
      # specify custom background job
      setting :custom_processor
    end
    # timezone names should match a valid timezone defined here:
    # http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html
    # accepts a valid timezone name
    setting :timezone, 'UTC'
    class << self
      def setup
        configure do |config|
          yield(config)
        end
      end
    end
  end
end
