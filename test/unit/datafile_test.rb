require 'test_helper'

class DatafileTest < ActiveSupport::TestCase
  # relationships
  should belong_to(:owner)
  # should has_and_belongs_to_many(:groups)
  should have_many(:jobs)

  should validate_presence_of(:owner)
  should validate_presence_of(:filename)

  context "Creating context for datafiles" do
  	setup do
  	  # @datafile0 = Datafile.new()
	  @datafile1 = FactoryGirl.create(:datafile, owner_id: @jack, filename: "PhenotypesA.xls")
	  @datafile2 = FactoryGirl.create(:datafile, owner_id: @jack, filename: "PhenotypesB.xls")
  	end

  	teardown do
  	  # @datafile0.delete
  	  @datafile1.delete
  	  @datafile2.delete
  	end

  # 	should "test that a datafile may have many groups" do
  # 	  4.times { @datafile0.groups << FactoryGirl.create(:group) }
  # 	  assert @datafile0.save
  # 	end

  # 	should "test that a datafile must have at least one group" do
  # 		@datafile0.save
  # 		assert_equal 1, @datafile0.errors.count
  # 		assert_not_nil, @datafile0,erros[:group]
  # 	end

  	should "show proper counts for datafiles" do
      assert_equal 2, @jack.datafiles.size
  	end

  end

end
