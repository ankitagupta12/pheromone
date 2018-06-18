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

This will generate the following in `config/initializers/pheromone.rb`

```
Pheromone.setup do |pheromone_config|
  # pheromone_config.background_processor.name = ':resque / :sidekiq'
  # pheromone_config.background_processor.klass = 'BackgroundWorker'
  # pheromone_config.timezone = 'UTC'
  pheromone_config.message_format = :json
    WaterDrop.setup do |waterdrop_config|    
      waterdrop_config.deliver = Rails.env.production?
      waterdrop_config.kafka.seed_brokers = [Rails.env.production? ? ENV['KAFKA_HOST'] : 'localhost:9092']
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
| enabled                       | Boolean       | Defaults to true. When this is set to false, no messages will be sent to Kafka |

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

   def self.perform(message_object)
     Pheromone::Messaging::Message.new(
       topic: message_object['topic'],
       metadata: { source: 'application1' },
       blob: message_object['blob'],
       metadata: message_object['metadata'],
       options: message_object['options']
     ).send!
   end
 end
```
#### 1.b. Using `:sidekiq`
Create a new class and add the name under `Pheromone.config.background_processor.klass`. Implement an instance method `perform_async(message)`, and invoke `message.send!` inside the method as shown below:

```
 class SidekiqJob
   include Sidekiq::Worker
   def perform(message_object)
     Pheromone::Messaging::Message.new(
       topic: message_object['topic'],
       blob: message_object['blob'],
       metadata: message_object['metadata'],
       options: message_object['options']
     ).send!
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
      metadata: { source: 'application1' },
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
      metadata: { source: 'application1' },
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
      metadata: { source: 'application1' },
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
      metadata: { source: 'application1' },
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
      metadata: { source: 'application1' },
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
  include Pheromone::Publishable
  publish [
    {
      event_types: [:create],
      topic: :topic_test,
      message: ->(obj) { { name: obj.name } },
      producer_options: {
        key: 'key',
        partition: 1,
        partition_key: 'key'
      }
    }
  ]
end
```

### 7. Specifying message metadata

Pheromone makes it easier to standardise the format of messages sent to Kafka while affording the flexibility to add other custom fields using the metadata option.

By default, the messages sent to Kafka have an event_type and timestamp attached to it as shown below: 
```
  {
    'event_type' => 'create',
    'timestamp' => '2015-07-14T10:10:00.000+08:00',
    'blob' => {
      'message_text' => 'test'
    }
  }.to_json
```

By specifying `metadata` to the `publish` method:

```
class PublishableModel < ActiveRecord::Base
  include Pheromone::Publishable
  publish [
    {
      event_types: [:create],
      topic: :topic_test,
      message: ->(obj) { { name: obj.name } },
      metadata: { source: 'application1' },
      producer_options: {
        key: 'key',
        partition: 1,
        partition_key: 'key'
      }
    }
  ]
end
```

The Kafka message will have the original metadata in addition to the new fields:
 

```
  {
    'event_type' => 'create',
    'timestamp' => '2015-07-14T10:10:00.000+08:00',
    'source' => 'application1',
    'blob' => {
      'message_text' => 'test'
    }
  }.to_json
```

### 8. Sending messages to Kafka directly

`pheromone` provides a custom message object that sends messages to Kafka in a predefined format, to maintain consistency in the message fields.

`Pheromone::Messaging::Message` can be initialized with the following arguments:
 - `topic`: name of the topic to which the message is produced 
 - `blob`: the actual message itself
 - `metadata`: any additional fields that must be sent along with the message
 - `options`: producer options as described in Section 6
 
 Of these fields, only `topic` and `message` are compulsory and the remaining two are optional.
 
 Example usage:
 
 ```
   Pheromone::Messaging::Message.new(
     topic: 'test_topic',
     blob: { message_text: 'test' },
     metadata: { event_type: 'create' },
     producer_options: { max_retries: 5 }
   ).send!
 ```
 
 This will send a message to `test_topic` in Kafka in the following format: 
 
 ```
  {
    'event_type' => 'create',
    'timestamp' => '2015-07-14T10:10:00.000+08:00',
    'blob' => {
      'message_text' => 'test'
    }
  }.to_json
 ```

As seen above `timestamp` will be added automatically to the main attributes along with the message metadata. The actual message will be encapsulated inside a key called `blob`.

### 9. Encoding messages

`pheromone` allows encoding messages using custom encoders. Encoders can be specified by simply specifying a proc to encode the message in any given format.

`publish` takes the `encoder` and `message_format` as options for encoding to be specified. Encoder is called with the entire message object and performs encoding on this message.

```        
  publish(
    [ 
      {
        topic: :test_topic,
        event_types: [:update, :create],
        serializer: TestSerializer,
        message_format: :with_encoding,
        encoder: ->(message) { avro.encode(message, schema_name: 'test') },
        if: ->(object) { object.should_publish_status_update? }
      }
    ]
  )
```

## Message Contents

In versions before `< 0.5`, the metadata keys were present at the top-most level, and the message itself was embedded inside the key `blob`.

The message published to Kafka looks like this:
 ```
 {
   event: 'create',
   entity: 'KlassName',
   timestamp: '2015-07-14T02:10:00.000Z',
   blob: {
     message_contents: 'message_contents'
   }
 }
 ```
 From `0.5` version onwards, the message format looks like this: 
 ```
 {
   metadata: {
     event: 'create',
     entity: 'KlassName',
     timestamp: '2015-07-14T02:10:00.000Z'
   }
   blob: {
     message_contents: 'message_contents'
   }
 }
 ```
 `event`, `entity`, and `timestamp` are determined and added by `pheromone`. `timestamp` will be in UTC by default and will use `timezone_format` value specified in `config/initializers/pheromone.rb`. Contents of `metadata` can be modified by using these [guidelines](https://github.com/ankitagupta12/pheromone#7-specifying-message-metadata). Message contents are placed under the key `blob`.

  In order to use the format with `blob` embedded inside `metadata`, specify option `embed_blob` as `true` inside `publish` options like this:
  
  ```        
  publish(
    [ 
      {
        topic: :test_topic,
        event_types: [:update, :create],
        serializer: TestSerializer,
        message_format: :with_encoding,
        embed_blob: true
        encoder: ->(message) { avro.encode(message, schema_name: 'test') },
        if: ->(object) { object.should_publish_status_update? }
      }
    ]
  )
  ```
## Testing

#### RSpec

`pheromone` makes it easy to control when it is enabled during testing with `pheromone/frameworks/rspec`
 
 ```
 # spec/rails_helper.rb
 require 'rspec/rails'
 # ...
 require 'pheromone/frameworks/rspec'
 
 ```
 
 With this helper, `publishable` is disabled by default. To turn it on, pass `publishable: true` to the spec block like this:
 
 ```
 describe 'PublishableModel' do
   before do
     @invocation_count = 0
     allow(WaterDrop::SyncProducer).to receive(:call) do
     @invocation_count += 1
   end
    
   it 'sends messages to kafka', publishable: true do
     PublishableModel.create
     expect(@invocation_count).to eq(1)
   end
 end
 ```
 Alternatively, `Pheromone.enabled?` can be used to check if `pheromone` is enabled
 
## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

=======
# pheromone

