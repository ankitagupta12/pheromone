WaterDrop.setup do |config|
  config.send_messages = true
  config.connection_pool_size = ENV['KAFKA_CONNECTION_POOL_SIZE'] || 20
  config.connection_pool_timeout = ENV['KAFKA_CONNECTION_POOL_TIMEOUT'] || 1
  config.kafka.hosts = (ENV['KAFKA_HOSTS'] || '').split(',')
  config.raise_on_failure = true
end
