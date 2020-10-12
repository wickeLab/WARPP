source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Markdown rendering
gem 'github-markup'
gem 'commonmarker'

# User management
gem 'cancancan'
gem 'devise'

# JQuery libraries
gem 'jquery-rails'
gem 'jquery-slick-rails'

# DataTables
gem 'jquery-datatables'
gem 'ajax-datatables-rails'

# Sprockets (necessary for Bootstrap)
gem 'sprockets-rails', require: 'sprockets/railtie'
# gem 'react-rails'
gem 'sidekiq'

gem 'parallel'
gem 'tre-ruby'

# Bootstrap
gem 'bootstrap', '~> 4.4.1'
gem 'bootstrap-glyphicons'
gem 'bootstrap-select-rails'
gem 'bootstrap-view-helpers'

# React
gem 'react-rails'

# Ancestry for nested TaxonomicLevel model
gem 'ancestry'

# fuzzy database search
gem 'pg_search'

# Gem for e.g. search icon
gem 'font-awesome-sass'

# BioRuby + Nokogiri to fetch+parse taxonomy
gem 'bio'
gem 'nokogiri'

# Visit tracker
gem 'chartkick'
gem 'groupdate'

# RSS Feed
gem 'rss'

# Gem for parsing GBIF Json
gem 'httparty'
gem 'retryable'
gem 'ruby-progressbar'

gem 'carrierwave', '~> 2.0'

# d3
gem 'd3-rails'

# strip_tags for models
gem 'sanitize'

# timed jobs
gem 'whenever', require: false

# use Rails variables in js
gem 'gon'
# use flash messages in js
gem 'toastr-rails'

# Javascript library to help render GBIF maps
gem 'leaflet-rails'

# gem for forms
gem 'simple_form'

# server communication
gem 'net-scp'
gem 'net-sftp'
gem 'net-ssh'

gem 'rubyzip'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'better_errors' # More useful error pages in development
  gem 'bullet' # Checks for n+1 queries
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 4.0.0'
  gem 'rubocop', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Capistrano
  gem 'capistrano',         require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano3-puma', require: false
  gem 'capistrano-sidekiq'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]