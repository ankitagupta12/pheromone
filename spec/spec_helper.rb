# frozen_string_literal: true

# frozen_string_literal: true
require 'bundler'
Bundler.setup

require 'active_support'
require 'pheromone'
require 'timecop'
require 'with_model'
require 'waterdrop'

RSpec.configure do |config|
  config.extend WithModel
end

is_jruby = RUBY_PLATFORM == 'java'
adapter = is_jruby ? 'jdbcsqlite3' : 'sqlite3'

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
require 'active_record'
ActiveRecord::Base.establish_connection(adapter: adapter, database: ':memory:')

