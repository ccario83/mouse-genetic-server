source 'https://rubygems.org'

gem 'rails', '3.2.3'
# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'


gem 'mysql'
group :development, :test do
  gem 'sqlite3'
  gem 'debugger'
end

# Gems used only in testing
group :test do
	gem 'shoulda', '3.3.2'
	gem 'shoulda-matchers', '1.4.2'
	gem 'factory_girl_rails', '4.2.1'
	gem 'mocha', '0.10.5'
	gem 'cucumber-rails', '1.3.0', :require => false
	gem 'gherkin' 	# '2.11.6'
	gem 'capybara', '2.0.2'
	gem 'database_cleaner', '0.9.1'
	gem 'launchy', '2.2.0'
	gem 'email_spec', '1.4.0'
	gem 'nokogiri', '1.5.6'
	gem 'simplecov', '0.7.1'
	gem 'tconsole', '1.2.8'
end

# Gems used only in development
group :development do
	gem 'quiet_assets', '1.0.2'
#	gem 'thin', '1.5.0'
	gem 'better_errors', '0.7.0'
	gem 'binding_of_caller', '0.7.1'
	gem 'meta_request', '0.2.2'
	gem 'wirble', '0.1.3'
	gem 'hirb', '0.7.1'
	gem 'populator3', '0.2.7'
#	gem 'faker', '1.1.2'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'less-rails'
  gem 'therubyracer'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end


# Gems for UI (Do manually, way too bloated)
#gem 'less-rails-bootstrap'
#gem 'jquery-ui-rails'
gem 'jquery-rails', '2.0.2'


# Gems required by workflow tools
gem 'redis', '2.2.2'
gem 'simple_form'
gem 'sidekiq'
gem 'sinatra', '1.3.0', :require => nil
gem 'slim'
gem 'gmaps4rails'
gem 'rinruby'

#Gems requied by social site
gem 'bcrypt-ruby', '~> 3.0.0'
gem 'faker', '1.0.1'
gem 'will_paginate', '3.0.3'            # For rails pagination, pajinate bootstrap juggernaut is used when GET REQUESTS cannot be used
gem 'bootstrap-will_paginate', '0.0.6'  # Extends will_paginate stylings to match Bootstrap convention 


# To use Jbuilder templates for JSON
# gem 'jbuilder'


# Use unicorn as the app server
# gem 'unicorn'
# Thin doesn't have the content-length WARN errors
gem 'thin'

# Deploy with Capistrano
# gem 'capistrano'


# To use debugger
#gem 'ruby-debug19', :require => 'ruby-debug'
