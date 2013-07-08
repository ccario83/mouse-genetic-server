require 'test_helper'

class GroupTest < ActiveSupport::TestCase
	should have_many(:memberships)
	should have_many(:users).through(:memberships)
	should belong_to(:creator)

	# Validations
	should validate_presence_of(:name)
	should validate_presence_of(:description)
	should validate_presence_of(:creator_id)
	
	context "Creating context for groups" do
		setup do
			create_user_context
		end

		teardown do
			remove_user_context
		end

		should "verify that memberships are destroyed when their group is destroyed" do
    		new_group = FactoryGirl.build(:group, name: "New Group", description: "New Group", creator_id: @jack)
    		new_group_id = new_group.id
    		membership1 = FactoryGirl.build(:membership, group_id: new_group, user_id: @jill)
    		membership2 = FactoryGirl.build(:membership, group_id: new_group, user_id: @john)
    		new_group.destroy
    		assert_nil Membership.find_by_group_id(new_group_id)
    	end

	end
end
