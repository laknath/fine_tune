[![Build Status](https://travis-ci.org/laknath/fine_tune.svg?branch=master)](https://travis-ci.org/laknath/fine_tune)

# FineTune - a flexible rate limiting/monitoring library

FineTune can be used to limit the rate of any given activity/event 
stream such as outgoing emails for a user. It's not fixed on a
particular implementation of throttling, rather it provides a framework
to add custom implementations/algorithms.

The main difference with other rate limiting libraries is the
flexibility of using custom throttling algorithms and external
data/cache stores. Also it doesn't need to be configured first, all
options can be passed in each throttling request.

## Installation

    $ gem install fine_tune

## Usage

Throttle represents an occurrence of a defined event. It will return true
if the threshold has reached. If not the count will be increased by one
and will return false.

  ```
  $ FineTune.throttle(:transactions_per_hour, user_id, options)
  ```

  * :transactions_per_hour - the name for the event
  * user_id - some unique identifier for a resource (ie: user)
  * options - configurations for the throttling implementation

An additional block can be passed, which will be called with event
details. ie:

  ```
  $ FineTune.throttle(:transactions_per_hour, user_id, options) do 
                                | count, comparison, id, strategy, options |
        #something...
    end
  ```
  
In addition, there's a more charged version - throttle! which will raise
a MaxRateError when reached the threshold. Same as throttle, it takes a 
block.

  ```
  $ FineTune.throttle!(:transactions_per_hour, user_id, options)
  ```

To get the current count of events:

  ```
  $ FineTune.count(:emails_per_day, user_id, options)
  ```

To check whether threshold has reached:

  ```
  $ FineTune.rate_exceeded?(:emails_per_day, user_id, options)
  ```

To reset the count of events for a resource:

  ```
  $ FineTune.reset(:emails_per_day, user_id, options)
  ```

###(Optional)

To configure default options:

  ```
    $ FineTune.add_limit(:hourly_emails, window: 3600, limit: 25)
  ```
Options passed here will be overridden by any options passed in
the individual calls.

To remove a pre-defined rule:

  ```
    $ FineTune.remove_limit(:hourly_emails, window: 3600, limit: 25)
  ```

###Supported implementations:

  * [Leaky Bucket algorithm](https://en.wikipedia.org/wiki/Leaky_bucket)


## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake test` to run the tests. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/laknath/fine_tune. This project
is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to 
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Credits

Some of the behaviours were inspired by [Props](https://github.com/zendesk/prop). 

Thanks you!


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
