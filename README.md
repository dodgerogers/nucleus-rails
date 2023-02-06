# Nucleus Rails

[![Gem Version](https://badge.fury.io/rb/nucleus-rails.svg)](https://rubygems.org/gems/nucleus-rails)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-rails/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-rails?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-rails/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-rails)

`nucleus-rails` provides a response adapter to `nucleus-core`.

## Quick start

```
$ gem install nucleus-rails
```

`config/initializers/nucleus-rails.rb`

```ruby
require "nucleus-rails"
```

```ruby
class PaymentsController < ApplicationController
  include NucleusCore::Responder

  before_action do |controller|
    init_responder(
      response_adapter: controller,
      request_format: controller.request&.format
    )
  end

  def create
    handle_response do
      policy.enforce!(:can_write?)

      context, _process = MyWorkflow.call(invoice_params)

      return context if !context.success?

      return MyView.new(cart: context.cart, paid: context.paid)
    end
  end

  private

  def policy
    MyPolicy.new(current_user)
  end

  def invoice_params
    params.slice(:cart_id)
  end
end
```

See [nucleus-core](https://codeclimate.com/github/dodgerogers/nucleus-core) for business logic implementation examples.

---

- [Quick start](#quick-start)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus-rails/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
