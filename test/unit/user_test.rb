require 'test_helper'

class UserTest < ActiveSupport::TestCase
	# related to microposts
	should have_many(:authored_posts)
	should have_many(:communications)
	should have_many(:received_posts)

	# related to groups or memberships
	should have_many(:memberships)
	should have_many(:groups)

	# related to tasks
	should have_many(:created_tasks)
	should have_many(:assigned_tasks)

	# related to jobs
	should have_many(:jobs)

	# related to data
	should have_many(:datafiles)

	# Validations
	should validate_presence_of(:first_name)
	should validate_presence_of(:last_name)
	should validate_presence_of(:institution)
	should allow_value("some.one@example.com").for(:email)
	should_not allow_value("mi$take@gmail.com").for(:email)
	should validate_presence_of(:password)
	
	context "Creating context for users" do
		setup do
			create_user_context
		end

		teardown do
			remove_user_context
		end

		should "not create a user with duplicate email" do
			invalid_user = FactoryGirl.build(:user, first_name: "Jack", last_name: "Jensen", email: "jack@example.com", institution: "DEF")
			deny invalid_user.valid?
		end

		should "check the total number of microposts received by a user" do
			post1 = FactoryGirl.build(:micropost, content: "Post from Jack to Jill", creator_id: @jack, recipient_type: "User")
			post2 = FactoryGirl.build(:micropost, content: "Post from Jill to John", creator_id: @jill, recipient_type: "User")
			post3 = FactoryGirl.build(:micropost, content: "Post from John to Jane", creator_id: @john, recipient_type: "User")
			post4 = FactoryGirl.build(:micropost, content: "Post from Jill to Jane", creator_id: @jill, recipient_type: "User")
			post5 = FactoryGirl.build(:micropost, content: "Post from Jack to Jane", creator_id: @jack, recipient_type: "User")
			comm1 = FactoryGirl.build(:communication, recipient_id: @jill, recipient_type: "User", micropost_id: post1)
			comm2 = FactoryGirl.build(:communication, recipient_id: @john, recipient_type: "User", micropost_id: post2)
			comm3 = FactoryGirl.build(:communication, recipient_id: @jane, recipient_type: "User", micropost_id: post3)
			comm4 = FactoryGirl.build(:communication, recipient_id: @jane, recipient_type: "User", micropost_id: post4)
			comm5 = FactoryGirl.build(:communication, recipient_id: @jane, recipient_type: "User", micropost_id: post5)
			assert_equal @jane.all_received_posts.size, 3
		end
	end
end
