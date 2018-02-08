require 'rspec/core'

RSpec.configure do |config|
  config.before(:each) do
    Pheromone.config.enabled = false
  end

  config.before(:each, publishable: true) do
    Pheromone.config.enabled = true
  end
end