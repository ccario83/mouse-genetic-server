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
  	@jack = FactoryGirl.create(:user, first_name: "Jack", last_name: "Jones", email: "jack@example.com", institution: "ABC Inc.")
    @jill = FactoryGirl.create(:user, first_name: "Jill", last_name: "Jones", email: "jill@example.com", institution: "DEF Inc.")
    @john = FactoryGirl.create(:user, first_name: "John", last_name: "Jones", email: "john@example.com", institution: "GHI Inc.")
    @jane = FactoryGirl.create(:user, first_name: "Jane", last_name: "Jones", email: "jane@example.com", institution: "JKL Inc.")
    @joel = FactoryGirl.create(:user, first_name: "Joel", last_name: "Jones", email: "joel@example.com", institution: "MNO Inc.")
    @jess = FactoryGirl.create(:user, first_name: "Jess", last_name: "Jones", email: "jess@example.com", institution: "PQR Inc.")
  end

    def create_group_context
    @group1_jack = FactoryGirl.create(:group, name: "Group1 - Jack", description: "Group1 created by Jack", creator_id: @jack)
    @group2_jack = FactoryGirl.create(:group, name: "Group2 - Jack", description: "Group2 created by Jack", creator_id: @jack)
    @group3_jill = FactoryGirl.create(:group, name: "Group3 - Jill", description: "Group3 created by Jill", creator_id: @jill)
    @group4_john = FactoryGirl.create(:group, name: "Group4 - John", description: "Group4 created by John", creator_id: @john)
    @group5_jane = FactoryGirl.create(:group, name: "Group5 - Jane", description: "Group5 created by Jane", creator_id: @jane)
    @group6_jess = FactoryGirl.create(:group, name: "Group6 - Jess", description: "Group5 created by Jess", creator_id: @jess)
  end

  def create_membership_context
    @membership1_group1 = FactoryGirl.create(:membership, group_id: @group1_jack, user_id: @jack, confirmed: true)
    @membership2_group1 = FactoryGirl.create(:membership, group_id: @group1_jack, user_id: @jill, confirmed: true)
    @membership3_group1 = FactoryGirl.create(:membership, group_id: @group1_jack, user_id: @john, confirmed: true)
    @membership4_group1 = FactoryGirl.create(:membership, group_id: @group1_jack, user_id: @jane, confirmed: true)
    @membership5_group1 = FactoryGirl.create(:membership, group_id: @group1_jack, user_id: @joel, confirmed: true)
    @membership1_group2 = FactoryGirl.create(:membership, group_id: @group2_jack, user_id: @jack, confirmed: true)
    @membership2_group2 = FactoryGirl.create(:membership, group_id: @group2_jack, user_id: @john, confirmed: true)
    @membership3_group2 = FactoryGirl.create(:membership, group_id: @group2_jack, user_id: @joel, confirmed: true)
    @membership1_group3 = FactoryGirl.create(:membership, group_id: @group3_jill, user_id: @jill, confirmed: true)
    @membership2_group3 = FactoryGirl.create(:membership, group_id: @group3_jill, user_id: @jane, confirmed: true)
    @membership3_group3 = FactoryGirl.create(:membership, group_id: @group3_jill, user_id: @jess, confirmed: true)
    @membership1_group4 = FactoryGirl.create(:membership, group_id: @group4_john, user_id: @john, confirmed: true)
    @membership2_group4 = FactoryGirl.create(:membership, group_id: @group4_john, user_id: @jane, confirmed: true)
    @membership3_group4 = FactoryGirl.create(:membership, group_id: @group4_john, user_id: @joel, confirmed: false)
    @membership4_group4 = FactoryGirl.create(:membership, group_id: @group4_john, user_id: @jess, confirmed: true)
    @membership1_group5 = FactoryGirl.create(:membership, group_id: @group5_jane, user_id: @jane, confirmed: true)
    @membership2_group5 = FactoryGirl.create(:membership, group_id: @group5_jane, user_id: @joel, confirmed: true)
    @membership3_group5 = FactoryGirl.create(:membership, group_id: @group5_jane, user_id: @jess, confirmed: false)
    @membership1_group6 = FactoryGirl.create(:membership, group_id: @group6_jess, user_id: @jess, confirmed: true)
    @membership2_group6 = FactoryGirl.create(:membership, group_id: @group6_jess, user_id: @jill, confirmed: true)
    @membership3_group6 = FactoryGirl.create(:membership, group_id: @group6_jess, user_id: @jane, confirmed: true)
     end

def remove_user_context
  	@jack.delete
    @jill.delete
  	@john.delete
  	@jane.delete
    @joel.delete
    @jess.delete
    end

  def remove_group_context
    @group1_jack.delete
    @group2_jack.delete
    @group3_jill.delete
    @group4_john.delete
    @group5_jane.delete
  end
  
  def remove_membership_context
    @membership1_group1.delete
    @membership2_group1.delete
    @membership3_group1.delete
    @membership4_group1.delete
    @membership5_group1.delete
    @membership1_group2.delete
    @membership2_group2.delete
    @membership3_group2.delete
    @membership1_group3.delete
    @membership2_group3.delete
    @membership3_group3.delete
    @membership1_group4.delete
    @membership2_group4.delete
    @membership3_group4.delete
    @membership4_group4.delete
    @membership1_group5.delete
    @membership2_group5.delete
    @membership3_group5.delete
    @membership1_group6.delete
    @membership2_group6.delete
    @membership3_group6.delete
end

end
