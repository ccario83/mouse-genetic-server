require 'simplecov'
SimpleCov.start 'rails'
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'


class ActiveSupport::TestCase
  # the following code is commented out because it is not used in testing
  # fixtures :all

  # Method to improve readability of tests
  def deny(condition, msg="")
  	assert !condition, msg
  end

  # Context for users
  def create_user_context
  	@jack = FactoryGirl.create(:user, first_name: "Jack", last_name: "Jones", email: "jack@example.com", institution: "ABC")
    @jill = FactoryGirl.create(:user, first_name: "Jill", last_name: "Jones", email: "jill@example.com", institution: "ABC")
    @john = FactoryGirl.create(:user, first_name: "John", last_name: "Jones", email: "john@example.com", institution: "ABC")
    @jane = FactoryGirl.create(:user, first_name: "Jane", last_name: "Jones", email: "jane@example.com", institution: "ABC")
  end

  def remove_user_context
  	@jack.delete
    @jill.delete
  	@john.delete
  	@jane.delete
  end
  
end
