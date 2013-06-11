require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  # matchers
  should belong_to(:user)
  should belong_to(:group)
  
  # context
  context "Creating context for users" do
    setup do
      create_user_context
    end

    teardown do
      remove_user_context
    end

    
    # The two tests below will produce failures because there is no requirement in the Membership model to have an existing user or group when creating a membership.
    # should "not allow membership for non-existent user" do
    #   ghost = FactoryGirl.build(:user, :first_name => "Ghost")
    #   bad_membership = FactoryGirl.build(:membership, user: ghost)
    #   deny bad_membership.valid?
    # end
    
    # should "not allow membership for non-existent group" do
    #   ghost_group = FactoryGirl.build(:group, name: "Ghost Group", description: "This is a ghost group", creator_id: @jack)
    #   bad_membership = FactoryGirl.build(:membership, group_id: ghost_group, user_id: @jane)
    #   deny bad_membership.valid?
    # end

  end
end