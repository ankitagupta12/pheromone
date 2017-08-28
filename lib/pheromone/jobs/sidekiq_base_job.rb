# Defines base job for sidekiq
module Pheromone
  module Jobs
    class SidekiqBaseJob
      include Sidekiq::Worker

      def perform(message)
        message.send!
      end
    end
  end
end