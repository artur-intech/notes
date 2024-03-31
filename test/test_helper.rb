# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov_json_formatter'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
    # Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter '/test/'
  end
end

ENV['APP_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'capybara/minitest'
require 'rake'
require_relative '../app'
require 'support/assertions'
require 'support/test_case'
require 'support/integration_test_case'
require 'support/system_test_case'
require 'support/fixtures'

Capybara.app = Sinatra::Application
Capybara.server = :puma, { Silent: true }
BCrypt::Engine.cost = 1
Warden.test_mode!

rake_app = Rake::Application.new
rake_app.load_rakefile
