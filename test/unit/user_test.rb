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
			post1 = FactoryGirl.create(:micropost, content: "Post from Jack to Jill", creator: @jack, recipient_type: "User", user_recipients: [@jill])
			post2 = FactoryGirl.create(:micropost, content: "Post from Jill to John", creator: @jill, recipient_type: "User", user_recipients: [@john])
			post3 = FactoryGirl.create(:micropost, content: "Post from John to Joel", creator: @john, recipient_type: "User", user_recipients: [@joel])
			post4 = FactoryGirl.create(:micropost, content: "Post from Jill to Joel", creator: @jill, recipient_type: "User", user_recipients: [@joel])
			post5 = FactoryGirl.create(:micropost, content: "Post from Jack to Joel", creator: @jack, recipient_type: "User", user_recipients: [@joel])
			# comm1 = FactoryGirl.create(:communication, recipient: @jill, recipient_type: "User", micropost: post1)
			# comm2 = FactoryGirl.create(:communication, recipient: @john, recipient_type: "User", micropost: post2)
			# comm3 = FactoryGirl.create(:communication, recipient: @joel, recipient_type: "User", micropost: post3)
			# comm4 = FactoryGirl.create(:communication, recipient: @joel, recipient_type: "User", micropost: post4)
			# comm5 = FactoryGirl.create(:communication, recipient: @joel, recipient_type: "User", micropost: post5)
			assert_equal 3, @joel.all_received_posts.size
			post1.delete
			post2.delete
			post3.delete
			post4.delete
			post5.delete
		end

		should "check the total number of microposts received by a user from groups" do
			post1_jack = FactoryGirl.create(:micropost, content: "Post from Jack to Group1", creator: @jack, recipient_type: "Group", user_recipients: [@jack])
			post1_jill = FactoryGirl.create(:micropost, content: "Post from Jack to Group1", creator: @jack, recipient_type: "Group", user_recipients: [@jill])
			post1_john = FactoryGirl.create(:micropost, content: "Post from Jack to Group1", creator: @jack, recipient_type: "Group", user_recipients: [@john])
			post1_jane = FactoryGirl.create(:micropost, content: "Post from Jack to Group1", creator: @jack, recipient_type: "Group", user_recipients: [@jane])
			post1_jess = FactoryGirl.create(:micropost, content: "Post from Jack to Group1", creator: @jack, recipient_type: "Group", user_recipients: [@jess])
			post2_jill = FactoryGirl.create(:micropost, content: "Post from Jill to Group3", creator: @jill, recipient_type: "Group", user_recipients: [@jill])
			post2_jane = FactoryGirl.create(:micropost, content: "Post from Jill to Group3", creator: @jill, recipient_type: "Group", user_recipients: [@jane])
			post2_jess = FactoryGirl.create(:micropost, content: "Post from Jill to Group3", creator: @jill, recipient_type: "Group", user_recipients: [@jess])
			post3_jess = FactoryGirl.create(:micropost, content: "Post from Jess to Group6", creator: @jess, recipient_type: "Group", user_recipients: [@jess])
			post3_jill = FactoryGirl.create(:micropost, content: "Post from Jess to Group6", creator: @jess, recipient_type: "Group", user_recipients: [@jill])
			post3_jane = FactoryGirl.create(:micropost, content: "Post from Jess to Group6", creator: @jess, recipient_type: "Group", user_recipients: [@jane])
			assert_equal 1, @jack.all_received_posts.size
			assert_equal 3, @jane.all_received_posts.size
			assert_equal 0, @joel.all_received_posts.size
			post1_jack.delete
			post1_jill.delete
			post1_john.delete
			post1_jane.delete
			post1_jess.delete
			post2_jill.delete
			post2_jane.delete
			post2_jess.delete
			post3_jess.delete
			post3_jill.delete
			post3_jane.delete
		end

		# should "verify the total number of microposts sent is accurate" do
		# 	assert_equal 9, @jane.all_received_posts.size
		# end

	end
end
