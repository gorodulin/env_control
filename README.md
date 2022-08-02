# ENV variables contract

> Keywords: #p20220707a #env #variable #contract #ruby #gem

Ruby approach in creating contracts for ENV variables.

## Why are contracts necessary?

Having a contract for ENV vars gives you a number of new benefits:

- You explicitly list all useful variables along with their requirements, so both your developers and devops know exactly which values are acceptable and which are not.
- You prevent your app from starting if there is something wrong with the ENV variables. E.g., you never misuse a production adapter or database in a staging environment (see [best practices](#best-practices)).
- You bring out the implicitly used ENV variables, revealing the hidden expectations of third-party gems. (As we often cannot change the logic of third-party gems, we're supposed to put up with inconsistency assigning, say, `"on"`/`"off"` to some ENV variables they require, `"true"`/`"false"` or `"true"`/`nil` to others, which makes working with ENV vars a poorly documented mess unless we have exposed it all in our contract).
- You explicitly declare unused variables as `:deprecated`, `:irrelevant` or `:ignore`, leaving developers no question about the applicability of a particular variable.

The larger your application, the more useful the ENV contract gets.

## How to use

After [installing](#how-to-install) this gem, define your contract:

```ruby
EnvControl.configuration.contract = {
  MY_UUID_VAR: :uuid,
  ...
}
```

Then validate the ENV variables only *after* they are all set (manually or by [dotenv](https://github.com/bkeepers/dotenv) / [Figaro](https://github.com/laserlemon/figaro)):

```ruby
EnvControl.validate(ENV)
```

If the contract has been breached, the `#validate` method raises exception. This behavior can be [customized](#custom-validation-error-handler) to suit your needs.


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
}
```

The contract is a list of ENV variables and validators you have attached to them.

Validators can be:
- Symbols, that are essentially names of [built-in validators](#built-in-validators).
- String literals that are exact values to compare the value with.
- `nil`, which literally means "we expect this variable to be unset".
- Custom callables (procs, lambdas, any objects that respond to `#call` method)
- a combination of the above as an Array. In this case, the contract will be considered satisfied if *at least one* of the listed validators is satisfied.
- environment-specific contracts.


It is allowed to mix validators of different types:

```ruby
EnvControl.configuration.contract = {
  # Allowed values: "true", "false", "weekly", "daily", "hourly"
  MY_RETRY: [:bool, "weekly", "daily", "hourly"],
}
```

## Built-in validators

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
EnvControl.configuration do |config|
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

### Custom validation error handler
TODO

### environment_name
TODO
### contract
TODO
### validators_allowing_nil
TODO
### on_validation_error
TODO
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
      EnvControl.configuration do |config|
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