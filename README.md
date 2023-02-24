# Nucleus Rails

[![Gem Version](https://badge.fury.io/rb/nucleus-rails.svg)](https://rubygems.org/gems/nucleus-rails)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-rails/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-rails?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-rails/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-rails)

- [Quick start](#quick-start)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

`nucleus-rails` adapts `nucleus-core` to work with the rails framework.

## Quick start

1. Install the gem

`Gemfile`

```ruby
gem 'nucleus-rails'
```

2. Initialize `nucleus-rails`

`config/initializers/nucleus-rails.rb`

```ruby
require "nucleus-rails"
```

3. Include the `responder` module, then call your business logic using the `execute` block method. Return either a `NucleusView`, a `Nucleus::Operation::Context`, or raise an exception to render a response.

```ruby
class PaymentsController < ApplicationController
  include NucleusRails::Responder

  def create
    execute do |req|
      context, _process = MyWorkflow.call(id: req.parameters[:id])

      return context unless context.success?

      return MyView.new(resource: context.resource)
    end
  end
end
```

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus-rails/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
