require 'test_helper'

class DatafileTest < ActiveSupport::TestCase
  # relationships
  should belong_to(:owner)
  should have_and_belong_to_many(:groups)
  should have_many(:jobs)

  should validate_presence_of(:owner)
  should validate_presence_of(:filename)

  context "Creating context for datafiles" do
		setup do
			create_user_context
		end

		teardown do
			remove_user_context
		end

  end

end
