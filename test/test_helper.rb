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

  def create_group_context
    @jackg1 = FactoryGirl.create(:group, name: "Jack - Group1", description: "Jack - Group1", creator_id: @jack)
    @jackg2 = FactoryGirl.create(:group, name: "Jack - Group2", description: "Jack - Group2", creator_id: @jack)
    @jackg3 = FactoryGirl.create(:group, name: "Jack - Group3", description: "Jack - Group3", creator_id: @jack)
    @jackg4 = FactoryGirl.create(:group, name: "Jack - Group4", description: "Jack - Group4", creator_id: @jack)
    @jackg5 = FactoryGirl.create(:group, name: "Jack - Group5", description: "Jack - Group5", creator_id: @jack)
    @jackg6 = FactoryGirl.create(:group, name: "Jack - Group6", description: "Jack - Group6", creator_id: @jack)
  end

  def remove_group_context
    @jackg1.delete
    @jackg2.delete
    @jackg3.delete
    @jackg4.delete
    @jackg5.delete
    @jackg6.delete
  end
  
end
