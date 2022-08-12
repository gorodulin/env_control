# ENV variables contract

> Keywords: #p20220707a #env #variable #contract #ruby #gem

Ruby approach in creating contracts for ENV variables.

Contract is a list of all ENV variables your app reads along with their validity criteria. If any of the requirements is not met, a negative scenario will be performed. For example, your application won't be able to start and/or you'll be notified that some ENV variables contain an invalid value. (more on this: [Why are contracts necessary?](#why-are-contracts-necessary))

Highlights:

- This gem *does not* force you to change the way you work with your ENV vars. It does not coerse/change the values of ENV variables.
- Not opinionated, not Rails-specific, can be applied to any [non-]ruby project.
- Customizable and well-tested.

In case you're not sure EnvControl is what you need, consider [alternative gems](#alternative-gems).

## How to use

After [installing](#how-to-install) this gem, create the contract:

```ruby
EnvControl.configuration.contract = {
  DB_PASSWORD: :string, # any non-empty string
  MY_UUID_VAR: :uuid,   # an UUID string
  ...
}
```

Then validate the ENV variables only *after* they are all set (manually or by [dotenv](https://github.com/bkeepers/dotenv)➚ / [Figaro](https://github.com/laserlemon/figaro)➚):

```ruby
EnvControl.validate(ENV)
```

`#validate` method ensures that contract format is valid, and then validates ENV variables against the contract.

In case the contract is breached, [on_validation_error](#on_validation_error) handler will be called with violated parts of contract passed as details. You can customize this  handler to suit your needs.

## Contract format explained

Consider the following example:

```ruby
EnvControl.configuration.contract = {
  ADMIN_EMAIL: :email,
  DEBUG: ["true", nil],
  LC_CTYPE: "UTF-8",
  MY_VAR1: :string,
  MY_VAR2: :bool,
  MYSQL_DEBUG: :not_set, # same as nil
  MYSQL_PWD: :deprecated,
  RAILS_ENV: ["production", "development", "test"],
  TMPDIR: :existing_file_path,
  APP_VERSION: /^(?!.*(beta|dev))/, # should not contain 'beta' or 'dev'
  ...
}
```

A contract is a list of ENV variables and validators you have attached to them.

Validators can be:
- `nil`, which literally means "we expect this variable to be unset".
- Symbols, that are essentially named [built-in validators](#named-built-in-validators) (see below).
- String literals that are exact values to compare a value with.
- [Regular expressions](https://ruby-doc.org/core-3.1.2/Regexp.html) ➚ in case strings are not enough.
- Custom callables (procs, lambdas, any objects that respond to `#call` method) in case regexps are not enough.
- a combination of the above as an Array. Contract will be considered satisfied if *at least one* of the listed validators is satisfied (logical OR).
- [environment-specific](#environment-specific-validations) validations.

It is allowed to mix validators of different types:

```ruby
EnvControl.configuration.contract = {
  # Allowed values: "true" OR "false" OR "weekly" OR "daily" OR "hourly"
  # OR number of hours (e.g. "12H") OR nil
  DLD_RETRY: [:bool, "weekly", "daily", "hourly", /\A\d+H\z/, nil],
}
```

## Named built-in validators

The EnvControl gem contains several built-in validators that you can use in your contracts.

Built-in validators are simply method names specified as symbols, e.g. `:string`, `:uuid`, `:email` etc.

These methods take ENV variable as input argument and return 'true' or 'false' depending on its value.


List of built-in validators:

| Validator               | Acceptable values     | Comments                 |
|-------------------------|-----------------------|--------------------------|
| `:bool`                 | `"true"`, `"false"`   |                          |
| `:string`               | any non-empty string  | `" "` considered empty   |
| `:email`                | any e-mail address    |                          |
| `:integer`              | any integer string    |                          |
| `:hex`                  | hexadecimal numbers   |                          |
| `:ignore`               | `nil` / any string    | Allows empty `""` value  |
| `:empty`                | `nil` or empty string | Same as `[:not_set, ""]` |
| `:irrelevant`           | `nil` / any string    | Synonym for `:ignore`    |
| `:deprecated`           | `nil` (not set)       | Synonym for `nil`        |
| `:not_set`              | `nil` (not set)       | Synonym for `nil`        |
| `:uri`                  | any uri               |                          |
| `:https_uri`            | any secure http uri   |                          |
| `:postgres_uri`         | any postgres uri      |                          |
| `:uuid`                 | UUID string           |                          |
| `:existing_path`        | file or folder path   | Both files and dirs      |
| `:existing_file_path`   | full file path        |                          |
| `:existing_folder_path` | full folder path      |                          |

You can [create your own](#custom-validators) validators if needed.

**Important:** Validators only work with non-nil ENV variables. If the variable is not set (nil), the validator won't be called.

## Environment-specific validations

The requirements for ENV variables may be different when you run your application in different [environments](https://www.onpathtesting.com/blog/understanding-app-environments-for-software-quality-assurance)➚. For example, it is important in the development environment to prevent calls to the production resources and storages. On the other hand, it makes sense to prohibit the enabling of variables that are responsible for debugging tools in production.

EnvControl allows you to specify environment-specific sets of validators for any of ENV variables.

```ruby
EnvControl.configure do |config|
  config.environment_name = ENV.fetch('RAILS_ENV')
  config.contract = {
    S3_BUCKET: {
      "production" => :string,  # any non-empty name
      "test" => /test/,         # any name, containing 'test' in its name
      "default" => :not_set     # by default the bucket should not be defined
    },
    UPLOADS: :existing_folder_path,
    ...
  }
end
```

You don't have to redefine the whole contract for each environment. It is enough to specify options for a particular variable.

Note that environment names *must be strings*.

`"default"` is a special reserved name used to define the fallback value.

## Custom validators

You can create your own validators. There are two approaches available.

1. Callable objects. Validators of this kind must respond to the `#call` method, so they can be `Proc`s, `Lambda`s or custom objects.

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

2. Custom methods to extend `EnvControl::Validators` module. These methods can reuse existing validators, making "AND" logic available to you:

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

`EnvControl.configuration` is a configuration object that contains the default settings. You can set its attributes directly or within a block:

```ruby
require "env_control"

EnvControl.configure do |config|
  config.environment_name = ...
  config.contract = {...}
  config.on_validation_error = MyContractErrorHander.new
end

EnvControl.validate(ENV)
```

Alternatively, you can provide/override contract using keyword attributes in `#validate` method:

```ruby
EnvControl.validate(
  ENV,
  environment_name: "review",
  contract: contract,
  on_validation_error: MyContractErrorHander.new,
)
```

### #environment_name

Sets the current environment name for [environment-specific validations](#environment-specific-validations).

### #contract

A Hash (or a Hash-like structure) that defines the [contract](#contract-format-explained). The keys are variable names, the values are the corresponding validators.

### #on_validation_error

This configuration settings contains a handler that `validate()` method calls as the contract gets breached.

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

  Or, in case you don't need to raise any errors:

  ```ruby
  EnvControl.configuration.on_validation_error = ->(report) { report }
  EnvControl.validate(ENV) # returns report as a Hash with no error raised
  ```
</details>


### #validators_allowing_nil

When an ENV variable is set, it contains a string value, so validators work only with strings - they throw an exception when an attempt is made to validate `nil`. However, it is required some validators to return `true` in response to `nil`. This configuration setting contains the list of such validators: `:deprecated`, `:empty`, `:ignore`, `:irrelevant`, `:not_set` . As you can see, they are mostly just aliases for `nil` with extra meanings.

```ruby
EnvControl.configuration.validators_allowing_nil << :custom_optional_validator
```



## Why are contracts necessary?

Having a contract for ENV vars gives you a number of new benefits:

- You explicitly list all requirements, so both your developers and devops know exactly which values are acceptable and which are not.
- You prevent your app from starting if there is something wrong with the ENV variables. E.g., you never misuse a production adapter or database in a staging environment (see [best practices](#best-practices)).
- You bring out the implicitly used ENV variables, revealing the hidden expectations of third-party gems. (As we often cannot change the logic of third-party gems, we're supposed to put up with inconsistency assigning, say, `"on"`/`"off"` to some ENV variables they require, `"true"`/`"false"` or `"true"`/`nil` to others, which makes working with ENV vars a poorly documented mess unless we have exposed it all in our contract).
- You explicitly declare unused variables as `:deprecated`, `:irrelevant` or `:ignore`, leaving developers no question about the applicability of a particular variable.

The larger your application, the more useful the ENV contract gets.



## Best practices

1. Maintain the ENV contract up to date so that other developers can use it as a source of truth about the ENV variables requirements. Feel free to add comments to the contract.
2. Keep the contract keys alphabetically sorted or group the keys by sub-systems of your application.
3. Keep the contract as permissive as you can. Avoid putting sensitive string literals.
4. Some validators like `:deprecated` are effectively equivalent to `nil`. Give them preference when you need to accompany a requirement to have a variable unset with an appropriate reason.
5. Add `:deprecated` to existing validators before proceeding to remove code that uses the variable., e.g.:
    ```ruby
    MY_VAR: [:deprecated, :string]
    ```

6. Consider defining "virtual" environments via `environment_name=` without introducing them to the application. This may be useful if you, say, need to run your review app in "production" environment but with a more restricted ENV contract:

    ```ruby
    EnvControl.configure do |config|
      config.environment_name = \
        if [ENV['RAILS_ENV'], ENV['REVIEW']] == ['production', 'true']
          'review' # virtual production-like environment
        else
          ENV['RAILS_ENV']
        end

      config.contract = {
        S3_BUCKET: {
          "production" => :string,
          "review" => "qa_bucket", # safe bucket
          "default" => :not_set
        }
      }
    end
    ````

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


