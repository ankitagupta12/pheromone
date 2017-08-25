# Pheromone

Pheromones are chemical substances secreted from glands and used as a means of communication.

`pheromone` allows setting up producers that publish `ActiveRecord` updates to Kafka whenever there is a model update and/or create.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pheromone'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pheromone

## Pheromone Setup

Pheromone depends on `waterdrop` to send messages to Kafka. `waterdrop` settings can be added by following the Setup step on [waterdrop](https://github.com/karafka/waterdrop/blob/master/README.md)

In order to setup `pheromone`, both `waterdrop` and `pheromone` need to be setup. Run this to generate `pheromone` configuration:

    $ bundle exec rails generate pheromone:initializer

This will generate the following file in `config/initializers/pheromone.rb`

```
Pheromone.setup do |config|
  #config.background_processor.name = ':resque / :sidekiq'
  #config.background_processor.klass = 'BackgroundWorker'
  config.timezone_format = 'UTC'
  config.message_format = :json
  WaterDrop.setup do |config|
    config.send_messages = Rails.env.production?
    config.connection_pool_size = 20
    config.connection_pool_timeout = 1
    config.kafka.hosts = [Rails.env.production? ? ENV['KAFKA_HOST'] : 'localhost:9092']
    config.raise_on_failure = Rails.env.production?
  end
end
```

Edit this file to modify the default config. The following configuration options are available:


| Option                        | Value type    | Description                      | 
|-------------------------------|---------------|----------------------------------|
| background_processor.name     | Symbol        | Choose :sidekiq or :resque as the background processor only if messages need to be sent to kafka asynchronously |
| background_processor.klass    | String        | Background processor class name that sends messages to kafka |
| timezone_format               | String        | Valid timezone name for timestamps sent to kafka |
| message_format                | Symbol        | Only supports :json format currently |
| send_messages                 | Boolean       | Should we send messages to Kafka |
| kafka.hosts                   | Array<String> | Kafka servers hosts with ports   |
| connection_pool_size          | Integer       | Kafka connection pool size       |
| connection_pool_timeout       | Integer       | Kafka connection pool timeout    |
| raise_on_failure              | Boolean       | Should we raise an exception when we cannot send message to Kafka - if false will silently ignore failures (will just ignore them) |

The timezone setting will transform any timestamp attributes in the message to the specified format.

## Usage

### 1. Sending messages to kafka asynchronously

The underlying Kafka client used by `pheromone` is `ruby-kafka`. This client provides a normal producer that sends messages to Kafka synchronously, and an `async_producer` to send messages to Kafka asynchronously.

It is advisable to use the normal producer in production systems because async producer provides no guarantees that the messages will be delivered. To read more on this, refer the `ruby-kafka` [documentation](https://github.com/zendesk/ruby-kafka#asynchronously-producing-messages)

Even while using a synchronous producer, sometimes there might be a need to run send messages to Kafka in a background task. This is especially true for batch processing tasks that send a high message volume to Kafka. To allow for this, `pheromone` provides an `async` mode that can be specified as an option to `publish` by specifying `dispatch_method` as `:async`. By default, `dispatch_method` will be `:sync`. Specifying `:async` will still use the normal producer and NOT the async_producer.
  
```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:create],
      topic: :topic_test,
      message: ->(obj) { { name: obj.name } },
      dispatch_method: :async
    }
  ]
end
```
The background_processor can be set inside `Pheromone.config.background_processor.name` as either `:resque` or `sidekiq`.

#### 1.a. Using `:resque`

Create a new class and add the name under `Pheromone.config.background_processor.klass`. Implement a class method `perform(message)`, and invoke `message.send!` inside the method as shown below:

```
 class ResqueJob
   @queue = :low

   def self.perform(message)
     message.send!
   end
 end
```
#### 1.b. Using `:sidekiq`
Create a new class and add the name under `Pheromone.config.background_processor.klass`. Implement an instance method `perform_async(message)`, and invoke `message.send!` inside the method as shown below:

```
 class SidekiqJob
   include Sidekiq::Worker
   def perform(message)
     message.send!
   end
 end
```
`pheromone` will invoke the class name specified in the config with the message object. This mode can be used if you don't want to block a request that ends up sending messages to Kafka.

### 2. Supported events
#### 2.a. To send messages for model `create` event, add the following lines to your ActiveRecord model

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:create],
      topic: :topic1,
      message: ->(obj) { { name: obj.name } }
    }
  ]
end
```

#### 2.b. To send messages for model `update` event, specify `update` in the `event_types` array:

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:update],
      topic: :topic1,
      message: ->(obj) { { name: obj.name } }
    }
  ]
end
```

Messages can be published for multiple event types by defining `events_types: [:create, :update]`.

### 3. Supported message formats

#### 3.a. Using a proc in `message`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:create],
      topic: :topic1,
      message: ->(obj) { { name: obj.name } }
    }
  ]
end
```

#### 3.b. Using a defined function in `message`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:update],
      topic: :topic1,
      message: message
    }
  ]

  def message
    { name: self.name }
  end
end
```

#### 3.c. Using a serializer in `message`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:create],
      topic: :topic1,
      serializer: Class.new(BaseSerializer) { attributes :name, :type }
    }
  ]
end
```


### 4. Sending messages conditionally

#### 4.a. Using a proc in `if`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:update],
      topic: :topic1,
      message: message,
      if: ->(data) { data.condition },
    }
  ]

  def message
    { name: self.name }
  end
end
```
#### 4.b. Using a defined function in `if`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:update],
      topic: :topic1,
      message: message,
      if: pre_condition
    }
  ]

  def pre_condition
    name.present?
  end

  def message
    { name: self.name }
  end
end
```

### 5. Specifying the topic

The kafka topic can be specified in the `topic` option to `publish`. To publish to `topic_test`, use the following:


```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:create],
      topic: :topic_test,
      message: ->(obj) { { name: obj.name } }
    }
  ]
end
```

### 6. Specifying producer options

[Ruby-Kafka](https://github.com/zendesk/ruby-kafka) allows sending options to change the behaviour of Kafka Producer.

These can be sent in by passing `producer_options` to the `publish` method:

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
  publish [
    {
      event_types: [:create],
      topic: :topic_test,
      message: ->(obj) { { name: obj.name } },
      producer_options: {
        # The number of retries when attempting to deliver messages. The default is
        # 2, so 3 attempts in total, but you can configure a higher or lower number:
        max_retries: 5,
        # The number of seconds to wait between retries. In order to handle longer
        # periods of Kafka being unavailable, increase this number. The default is
        # 1 second.
        retry_backoff: 5,
        # number of acknowledgements that the client should write to before returning
        # possible values are :all, 0 or 1 and default behaviour is :all, requiring all
        # replicas to acknowledge
        required_acks: 1,
        # compression can be enabled in order to improve bandwidth, and a minimum number
        # of messages that need to be in the buffer before they are compressed can be 
        # specified using compression threshold
        compression_codec: :snappy,
        compression_threshold: 10 
      }
    }
  ]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

=======
# pheromone

