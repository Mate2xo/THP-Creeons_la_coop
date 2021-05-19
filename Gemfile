# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

# Rails base gems
gem 'bootstrap', '~> 4.3.1'
gem 'image_processing', '~> 1.9', '>= 1.9.3'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.3'
gem 'rails', '~> 5.2'
gem 'sass-rails', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'mini_magick', '~> 4.9.5' # Use ActiveStorage variant

gem 'active_storage_validations'
gem 'activeadmin' # Admin interface
gem 'addressable' # URI manipulations
gem 'aws-sdk-s3', require: false # S3 file upload storage
gem 'bootstrap4-datetime-picker-rails'
gem 'cocoon', '~> 1.2', '>= 1.2.12' # Dynamic nested forms
gem 'devise', '~> 4.7' # Users login/registration management
gem 'devise_invitable', '~> 2.0.0'
gem 'draper' # decorators manager
gem 'dry-transaction'
gem 'enumerize'
gem 'httparty' # Http requests
gem 'ice_cube' # Calendar events recurrence (for Missions)
gem 'js_cookie_rails' # Cookie manager for js
gem 'leaflet-rails' # GeoMap generator
gem 'mailjet' # Production mailer API
gem 'pundit' # Authorization management
gem 'recurring_select' # Events recurrence rules set helper
gem 'thredded', '~> 0.16.16' # Forum engine

group :development, :test do
  gem 'factory_bot_rails', '~> 4.0'
  gem 'faker' # Generate fake data for the seed.rb and spec factories
  gem 'guard-rspec', require: false
  gem 'pry-byebug', '~> 3.6'
  gem 'rspec-rails', '~> 3.7', '>= 3.7.2'
end

group :development do
  gem 'annotate', '~> 2.7', '>= 2.7.4'
  gem 'bullet', group: 'development'
  gem 'letter_opener'
  gem 'solargraph' # LSP provinding app documention through IDE
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'email_spec'
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
  gem 'database_cleaner' # Easy database + association testing
  gem 'rails-controller-testing' # If you are using Rails 5.x
  gem 'shoulda-matchers', '4.0.0.rc1'
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
