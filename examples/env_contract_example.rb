# frozen_string_literal: true

require "env_control"

EnvControl.configure do |c|
  c.contract = {
    ADMIN_EMAIL: :email,
    CLOUDFLARE_EMAIL: :email,
    CLOUDFLARE_KEY: :hex,
    DATABASE_URL: {
      "staging" => /staging/,
      "default" => :postgres_uri,
    },
    DEVELOPER_MODE: :bool,
    DEBUG: ["true", nil],
    HOST: {
      "production" => :uri,
      "staging" => /^https:\/\/staging/,
      "default" => :string,
    },
    KARAFKA_ROOT_DIR: :existing_folder_path,
    LC_CTYPE: "UTF-8",
    LOG_LEVEL: %w[DEBUG INFO WARN ERROR FATAL],
    LANG: "en_US.UTF-8",
    MYSQL_DEBUG: :deprecated,
    MYSQL_PWD: :deprecated,
    RAILS_ENV: %w[production development test],
    ROLLBAR_ACCESS_TOKEN: :string,
    SAFETY_ASSURED: ["true", :not_set],
    S3_BUCKET: {
      "production" => :string,
      "staging" => /staging/,
      "default" => nil,
    },
    RACK_ENV: {
      "production" => "production",
      "default" => :string,
    },
    TMPDIR: :existing_folder_path,
    WEB_CONCURRENCY: :integer,
  }
end
