# ENV variables contract

> Keywords: #env #variable #contract #ruby #gem #environment #p20220707a

Ruby approach in creating contracts (manifests) for ENV variables.

Contract is a list of all ENV variables your app reads along with their validity criteria. If any of the requirements is not met, a negative scenario will be performed. For example, your application won't be able to start and/or you'll be notified that some ENV variables contain an invalid value. (more on this: [Why are contracts necessary?](#why-are-contracts-necessary))

Highlights:

- This gem *does not* force you to change the way you work with your ENV vars. It does not coerse/change the values of ENV variables.
- Not opinionated, not Rails-specific, can be applied to any [non-]ruby project.
- Customizable and well-tested.

In case you're not sure EnvControl is what you need, consider [alternative gems](#alternative-gems).

## How to use

After [installing](#how-to-install) this gem, create the Contract:

```ruby
EnvControl.configuration.contract = {
  DB_PASSWORD: :string, # any non-empty string
  MY_UUID_VAR: :uuid,   # an UUID string
  ...
}
```

Then validate the ENV variables:


```ruby
EnvControl.validate(ENV)
```

`#validate` method ensures that contract format is valid, and then validates ENV variables against the contract.

In case the contract is breached, [on_validation_error](#on_validation_error) handler will be called with violated parts of contract passed as details. You can customize this  handler to suit your needs.

**Note**: run `validate()` only *after* ENV variables are all set (after [dotenv](https://github.com/bkeepers/dotenv)➚ or [Figaro](https://github.com/laserlemon/figaro)➚)

## Contract format

Consider the following example:

```ruby
EnvControl.configuration.contract = {
  ADMIN_EMAIL: :email,    # any valid email address
  DEBUG: ["true", nil],   # "true" or unset (nil)
  LC_CTYPE: "UTF-8",      # nothing but "UTF-8"
  MY_VAR1: :string,       # any non-empty string
  MY_VAR2: :bool,         # "true" or "false"
  MYSQL_DEBUG: :not_set,  # unset w/o a reason (effectively same as nil)
  MYSQL_PWD: :deprecated, # unset as deprecated (effectively same as nil)
  RAILS_ENV: ["production", "development", "test"], # limited to these 3 options
  TMPDIR: :existing_file_path,
  ...
}
```

A contract is a **list of ENV variables and validators** you have attached to them.

Validators can be:

- String literals that are exact values to compare a value with.

  <details>
    <summary>Examples</summary>

    ```ruby
    EnvControl.configuration.contract = {
      MY_SWITCH: "on",
      MY_BOOL: ["true", "false"], # same as :bool
    }
    ```
  </details>

- `nil`, which literally means "we expect this variable to be unset".

  <details>
    <summary>Examples</summary>

    ```ruby
    EnvControl.configuration.contract = {
      DATABASE_HOST: nil,     # must be unset in preference to DATABASE_URL
      MY_SWITCH: ["on", nil], # "on" OR not set
    }
    ```
  </details>
- Symbols, that are essentially [names of predefined validators](#named-built-in-validators).

  <details>
    <summary>Examples</summary>

    ```ruby
    EnvControl.configuration.contract = {
      MY_VAR2: :bool, # "true" OR "false"
      MYSQL_DEBUG: :not_set,  # same as nil
      MYSQL_PWD: :deprecated, # same as nil
    }
    ```
  </details>

- [Regular expressions](https://ruby-doc.org/core-3.1.2/Regexp.html) ➚ in case strings are not enough.
  <details>
    <summary>Examples</summary>

    ```ruby
    EnvControl.configuration.contract = {
      # same as :integer
      TIME_SHIFT_SEC: /\A[-]{,1}\d+\z/,
      # should not contain "beta" or "dev"
      APP_VERSION: /^(?!.*(beta|dev))/,
    }
    ```
  </details>
- Custom callables (procs, lambdas, any objects that respond to `#call` method) in case regexps are not enough.

  <details>
    <summary>Examples</summary>

    ```ruby
    EnvControl.configuration.contract = {
      FILENAME_FORMAT: CustomFilenameFormatValidator.new,
      DATABASE_NAME: -> { _1.start_with?("production") }
    }
    ```

    Learn more about creating [custom callable validators](#custom-callables).
  </details>

- a combination of the above as an Array. Contract will be considered satisfied if *at least one* of the listed validators is satisfied (logical OR).

  <details>
    <summary>Example</summary>

    ```ruby
    EnvControl.configuration.contract = {
      DLD_RETRY: [:bool, "weekly", "daily", "hourly", /\A\d+H\z/, nil],
    }
    ```
    This example combines validators of different types, allowing only: `"true"` OR `"false"` OR `"weekly"` OR `"daily"` OR `"hourly"` OR number of hours (e.g. `"12H"`) OR `nil`
  </details>

- [environment-specific](#environment-specific-validations) validations.





## Named built-in validators

The EnvControl gem contains several built-in validators that you can use in your contracts.

Built-in validators are simply method names specified as symbols, e.g. `:string`, `:uuid`, `:email` etc.

These methods take ENV variable as input argument and return `true` or `false` depending on its value. Named validators (with some [exceptions](#validatorsallowingnil)) only work with non-nil ENV variables.


List of built-in validators:

| Validator               | Acceptable values     | Comments                  |
|-------------------------|-----------------------|---------------------------|
| `:bool`                 | `"true"`, `"false"`   |                           |
| `:string`               | any non-empty string  | `" "` considered empty    |
| `:email`                | any e-mail address    |                           |
| `:integer`              | any integer string    |                           |
| `:hex`                  | hexadecimal numbers   |                           |
| `:empty`                | `nil` or empty string | Same as `[:not_set, ""]`  |
| `:deprecated`           | `nil` (not set)       | Synonym for `nil`         |
| `:not_set`              | `nil` (not set)       | Synonym for `nil`         |
| `:uri`                  | any uri               |                           |
| `:https_uri`            | any secure http uri   |                           |
| `:postgres_uri`         | any postgres uri      |                           |
| `:uuid`                 | UUID string           |                           |
| `:existing_file_path`   | full file path        | Absolute path             |
| `:existing_folder_path` | full folder path      | Absolute path             |
| `:existing_path`        | file or folder path   | Absolute path             |
| `:irrelevant`           | `nil` / any string    | Literally anything        |
| `:ignore`               | `nil` / any string    | Synonym for `:irrelevant` |


You can create [your own named validators](#custom-named-validators) if needed.

## Environment-specific validations

The requirements for ENV variables may be different when you run your application in different [environments](https://www.onpathtesting.com/blog/understanding-app-environments-for-software-quality-assurance)➚.

*For example, it is important in the development environment to prevent calls to production resources and storages. On the other hand, it makes sense to prohibit the enabling of variables that are responsible for debugging tools in production.*

EnvControl allows you to specify environment-specific sets of validators for any of ENV variables.

```ruby
EnvControl.configure do |config|
  config.environment_name = ENV.fetch('RAILS_ENV')
  config.contract = {
    S3_BUCKET: {
      "production" => :string,  # any non-empty name
      "test" => /test/,         # any name containing 'test' substring
      "default" => :not_set,    # by default the bucket should not be defined
    },
    FILTER_SENSITIVE: {
      "production" => "true",
      "default" => :bool,
    },
    UPLOADS: :existing_folder_path,
    ...
  }
end
```

You don't have to redefine the whole contract for each environment. It is enough to specify options for a particular variable.

Note that environment names *must be strings*.

`"default"` is a special reserved name used to define a fallback value.

## Custom validators

You can create your own validators. There are two approaches available.

### Custom callables

Validators of this kind must respond to the `#call` method, so they can be `Proc`s, `Lambda`s or custom objects.

  ```ruby
  class StrongPasswordValidator
    def self.call(string)
      string.match? A_STRONG_PASSWORD_REGEX
    end
  end

  EnvControl.configuration.contract = {
    DB_PASSWORD: [StrongPasswordValidator, :not_set],
  }
  ```

### Custom named validators

Custom methods to extend `EnvControl::Validators` module. These methods can reuse existing validators, making "AND" logic available to you:

  ```ruby
  module MyContractValidators
    def irc_uri(string)
      uri(string) && URI(string).scheme.eql?("irc")
    end
  end

  EnvControl::Validators.extend(MyContractValidators)

  EnvControl.configuration.contract = {
    IRC_CHANNEL: :irc_uri,
    ...
  }
  ```

## How to install

```bash
gem install env_control
```

or add the gem to your Gemfile and then run `bundle install`:

```ruby
# Gemfile
gem "env_control"
```

## Configuration

`EnvControl.configuration` is a global configuration object. You can set its attributes directly or within `configure` block:

```ruby
require "env_control"

EnvControl.configure do |config|
  config.environment_name = ...
  config.contract = {...}
  config.on_validation_error = MyContractErrorHander
end

EnvControl.validate(ENV)
```

Global configuration settings are not mandatory as you can rely on corresponding keyword attributes in `#validate` method.

<details>
  <summary>Example</summary>

  ```ruby
  contract = {
    ...
  }

  EnvControl.validate(
    ENV,
    environment_name: "review",
    contract: contract,
    on_validation_error: MyContractErrorHander,
  )
  ```
</details>

Configuration settings you can read and write:

- [#environment_name](#environmentname)
- [#contract](#contract)
- [#on_validation_error](#onvalidationerror)
- [#validators_allowing_nil](#validatorsallowingnil)

### #environment_name

Sets the current environment name for [environment-specific validations](#environment-specific-validations).

<details>
  <summary>Example</summary>

  ```ruby
  EnvControl.configure do |config|
    config.environment_name = ENV.fetch('RAILS_ENV')
  end
  ```
</details>

### #contract

A Hash (or a Hash-like structure) that defines the [contract](#contract-format). The keys are variable names, the values are the corresponding validators.

<details>
  <summary>Example</summary>

  ```ruby
  EnvControl.configure do |config|
    config.environment_name = ENV.fetch('RAILS_ENV')
    config.contract = {
      # ...
    }
  end
  ```
</details>

### #on_validation_error

This configuration setting contains a handler that `validate()` method calls as the contract gets breached.

There is a default implementation that raises `EnvControl::BreachOfContractError` exception. You can customize this behavior by assigning a new callable handler:

<details>
  <summary>Example</summary>

  ```ruby
  EnvControl.configure do |config|
    config.on_validation_error = lambda do |report|
      error = BreachOfContractError.new(context: { report: report })
      Rollbar.critical(error)
    end
  end
  ```

  Or, in case you need to get report without raising an error:

  ```ruby
  EnvControl.configuration.on_validation_error = ->(report) { report }

  EnvControl.validate(ENV) # return report as a Hash with no error raised
  ```
</details>


### #validators_allowing_nil

[Named validators](#named-built-in-validators) work only with strings - they usually return `false` when an attempt is made to validate `nil`.

However, in rare cases you may need some validators to return `true` in response to `nil`. There is a list of such validators, which you can extend as needed.

<details>
  <summary>Example</summary>

  ```ruby
  EnvControl.configuration.validators_allowing_nil
  => [:deprecated, :empty, :ignore, :irrelevant, :not_set]

  EnvControl.configuration.validators_allowing_nil << :custom_optional_validator

  EnvControl.configuration.validators_allowing_nil
  => [:deprecated, :empty, :ignore, :irrelevant, :not_set, :custom_optional_validator]
  ```

  As you can see, listed validators are mostly just aliases for `nil` with extra meanings.

  In most scenarios it is better to allow `nil` explicitly:

  ```ruby
  EnvControl.configuration.contract = {
    DLD_RETRY: [:my_custom_validator, nil],
  }
  ```
</details>

## Why are contracts necessary?

Having a contract for ENV vars gives you a number of new benefits:

- You explicitly list all requirements, so both your developers and devops know exactly which values are acceptable and which are not.
- You prevent your app from starting if there is something wrong with the ENV variables. E.g., you never misuse a production adapter or database in a staging environment (see [best practices](#best-practices)).
- You bring out the implicitly used ENV variables, revealing the hidden expectations of third-party gems. (As we often cannot change the logic of third-party gems, we're supposed to put up with inconsistency assigning, say, `"on"`/`"off"` to some ENV variables they require, `"true"`/`"false"` or `"true"`/`nil` to others, which makes working with ENV vars a poorly documented mess unless we have exposed it all in our contract).
- You explicitly declare unused variables as `:deprecated`, `:irrelevant` or `:ignore`, leaving developers no question about the applicability of a particular variable.

The larger your application, the more useful the ENV contract gets.



## Best practices

1. Keep the contract as permissive as possible. Avoid putting sensitive string literals.
2. List variables that are set but not related, marking them as `:irrelevant`. This will remove questions about their applicability.
2. Disallow unused variables that could potentially affect your apps, marking them as `:not_set`. This may require you to search for ENVs throughout your code base.
3. Maintain the ENV contract up to date so that other developers can use it as a source of truth about the ENV variables requirements. Feel free to add comments to the contract.
4. Keep the contract keys alphabetically sorted or group the keys by sub-systems of your application.
5. Some validators like `:deprecated` are effectively equivalent to `nil`. Give them preference when you need to accompany a requirement to have a variable unset with an appropriate reason.
6. Add `:deprecated` to existing validators before proceeding to remove code that uses the variable., e.g.:
    ```ruby
    MY_VAR: [:deprecated, :string]
    ```

7. You may benefit from a contract environment that differs from your app environment. This may be useful if you, say, need to run your review app in "production"-like but restricted environment.

    <details>
      <summary>Example</summary>

      ```ruby
      EnvControl.configure do |config|
        config.environment_name = \
          if [ENV['RAILS_ENV'], ENV['REVIEW']] == ['production', 'true']
            'review' # virtual production-like environment
          else
            ENV.fetch('RAILS_ENV')
          end

        config.contract = {
          S3_BUCKET: {
            "production" => /prod/,
            "review" => /review/, # safe bucket
            "default" => :not_set
          }
        }
      end
      ````
    </details>



## Alternative gems

- [envied](https://gitlab.com/envied/envied) gem

- [env_bang and env_bang-rails](https://github.com/jcamenisch/ENV_BANG)

- [require_env](https://github.com/Aethelflaed/require_env)

- [envi](https://github.com/avdgaag/envi) gem

- [valid-env](https://github.com/mhs/valid-env) gem

- [envvar](https://github.com/brendanstennett/envvar)

- [env-dependencies](https://github.com/lukehorvat/env-dependencies) gem

- [envforcer](https://github.com/mojotech/envforcer) gem

- [env_enforcer](https://www.ruby-toolbox.com/projects/env_enforcer) gem

- [env_lint](https://www.ruby-toolbox.com/projects/env_lint) gem

- [env_vars](https://www.ruby-toolbox.com/projects/env_vars) gem

- [env_inspector](https://www.ruby-toolbox.com/projects/env_inspector) gem

- [environment_config](https://github.com/aroundhome/environment_config) gem

- [env-checker](https://github.com/ryanfox1985/env-checker) gem

- [envdocs-ruby](https://github.com/joerodrig/envdocs-ruby/) gem
  [more](https://www.ruby-toolbox.com/search?display=compact&order=score&page=4&q=env&show_forks=false)


