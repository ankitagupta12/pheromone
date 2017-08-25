module Pheromone
  module Exceptions
    class UnsupportedMessageFormat < StandardError
      def initialize(msg = 'Message format not supported')
        super
      end
    end
  end
end