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

## Waterdrop Setup

Pheromone depends on `waterdrop` to send messages to Kafka. `waterdrop` settings can be added by following the Setup step on [waterdrop](https://github.com/karafka/waterdrop/blob/master/README.md)

WaterDrop has following configuration options:

| Option                  | Value type    | Description                      |
|-------------------------|---------------|----------------------------------|
| send_messages           | Boolean       | Should we send messages to Kafka |
| kafka.hosts             | Array<String> | Kafka servers hosts with ports   |
| connection_pool_size    | Integer       | Kafka connection pool size       |
| connection_pool_timeout | Integer       | Kafka connection pool timeout    |
| raise_on_failure        | Boolean       | Should we raise an exception when we cannot send message to Kafka - if false will silently ignore failures (will just ignore them) |

To apply this configuration, you need to use a *setup* method:

```ruby
WaterDrop.setup do |config|
  config.send_messages = true
  config.connection_pool_size = 20
  config.connection_pool_timeout = 1
  config.kafka.hosts = ['localhost:9092']
  config.raise_on_failure = true
end
```

This configuration can be placed in *config/initializers* and can vary based on the environment:

```ruby
WaterDrop.setup do |config|
  config.send_messages = Rails.env.production?
  config.connection_pool_size = 20
  config.connection_pool_timeout = 1
  config.kafka.hosts = [Rails.env.production? ? 'prod-host:9091' : 'localhost:9092']
  config.raise_on_failure = Rails.env.production?
end
```

## Usage

### 1. Supported events
#### 1.a. To send messages for model `create` event, add the following lines to your ActiveRecord model

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
  publish [
    {
      event_types: [:create],
      topic: :topic1,
      message: ->(obj) { { name: obj.name } }
    }
  ]
end
```

#### 1.b. To send messages for model `update` event, specify `update` in the `event_types` array:

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
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

### 2. Supported message formats

#### 2.a. Using a proc in `message`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
  publish [
    {
      event_types: [:create],
      topic: :topic1,
      message: ->(obj) { { name: obj.name } }
    }
  ]
end
```

#### 2.b. Using a defined function in `message`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
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

#### 2.c. Using a serializer in `message`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
  publish [
    {
      event_types: [:create],
      topic: :topic1,
      serializer: Class.new(BaseSerializer) { attributes :name, :type }
    }
  ]
end
```


### 3. Sending messages conditionally

#### 3.a. Using a proc in `if`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
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
#### 3.b. Using a defined function in `if`

```
class PublishableModel < ActiveRecord::Base
  include Pheromone
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

### 4. Specifying the topic

The kafka topic can be specified in the `topic` option to `publish`. To publish to `topic_test`, use the following:


```
class PublishableModel < ActiveRecord::Base
  include Pheromone
  publish [
    {
      event_types: [:create],
      topic: :topic_test,
      message: ->(obj) { { name: obj.name } }
    }
  ]
end
```

### 5. Specifying producer options

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

