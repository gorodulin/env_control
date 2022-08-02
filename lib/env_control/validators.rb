# frozen_string_literal: true

require "uri"

module EnvControl
  module Validators
    class << self

      def bool(val)
        ["true", "false"].include?(val)
      end

      def email(string)
        string.match?(URI::MailTo::EMAIL_REGEXP)
      end

      def empty(string)
        string == ""
      end

      def existing_file_path(path)
        File.file?(path)
      end

      def existing_folder_path(path)
        Dir.exists?(path)
      end

      def existing_path(path)
        File.exists?(path)
      end

      def https_uri(string)
        uri(string) && URI(string).scheme.eql?("https")
      end

      def ignore(string)
        true
      end

      def integer(string)
        string.match?(/\A[-]{,1}\d+\z/)
      end

      def irrelevant(string)
        true
      end

      def not_set(value)
        false
      end

      alias_method :deprecated, :not_set

      def postgres_uri(string)
        uri(string) && URI(string).scheme.eql?("postgres")
      end

      def string(val)
        val.strip.size > 0
      end

      def uri(string)
        string.match?(/\A#{URI::regexp}\z/)
      end

      def uuid(string)
        string.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
      end

      def hex(string)
        string.match?(/\A[a-f0-9]+\z/i)
      end

    end
  end
end
