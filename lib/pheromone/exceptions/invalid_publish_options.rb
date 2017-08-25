module Pheromone
  module Exceptions
    class InvalidPublishOptions < StandardError
      def initialize(msg = 'Message format not supported')
        super
      end
    end
  end
end