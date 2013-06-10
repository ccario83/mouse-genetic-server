require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  # matchers
  should belong_to(:creator)
  should have_many(:communications)
  should have_many(:group_recipients)
  should have_many(:user_recipients)
  
  # context
  context "Creating context for users" do
    setup do
      create_user_context
    end

    teardown do
      remove_user_context
    end

    should "check the creator is a user in the system" do
      ghost = FactoryGirl.create(:user, first_name: "Ghost", last_name: "User", email: "ghost@example.com", institution: "ABC")
      bad_micropost = FactoryGirl.build(:micropost, content: "Bogus micropost", creator_id: ghost)
      deny bad_micropost.valid?
    end
    
  end
end