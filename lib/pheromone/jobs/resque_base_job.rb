# Defines base job for resque
module Pheromone
  module Jobs
    class ResqueBaseJob
      @queue = :low

      def self.perform(message)
        message.send!
      end
    end
  end
end
