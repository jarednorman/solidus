source 'http://rubygems.org'

gem 'rails', '3.1.0.rc5'
gem 'arel', '2.1.4'

gem 'json'
gem 'sqlite3'
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.1.0.rc"
  gem 'coffee-rails', "~> 3.1.0.rc"
  gem 'uglifier'
end

group :test do
  gem 'rspec-rails', '= 2.6.1'
  gem 'factory_girl', '= 1.3.3'
  gem 'factory_girl_rails', '= 1.0.1'
  gem 'rcov'
  gem 'faker'
  gem 'shoulda'
end

group :cucumber do
  gem 'cucumber-rails', '1.0.0'
  gem 'database_cleaner', '= 0.6.7'
  gem 'nokogiri'
  gem 'capybara', '1.0.1'
  gem 'factory_girl', '= 1.3.3'
  gem 'factory_girl_rails', '= 1.0.1'
  gem 'faker'
  gem 'launchy'
end

group :ci do
  gem 'mysql2', '~> 0.3.6'
end

if RUBY_VERSION < "1.9"
  gem "ruby-debug"
else
  gem "ruby-debug19"
end

gem "spree", :path => File.dirname(__FILE__)
#root
