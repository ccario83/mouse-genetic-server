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
	end
end
