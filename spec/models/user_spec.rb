require 'spec_helper'

describe User do

  before do
  	@user = User.new(:name => "Example User", :email => "user@example.com",
  					 :password => "foobar", :password_confirmation => "foobar")
  end

  subject { @user }

    it { should respond_to(:name) }
    it { should respond_to(:email) }
    it { should respond_to(:password_digest) }
    it { should respond_to(:password) }
    it { should respond_to(:password_confirmation) }
    it { should respond_to(:remember_token) }
    it { should respond_to(:admin) }
    it { should respond_to(:authenticate) }
    it { should respond_to(:microposts) }
    it { should respond_to(:feed) }


  	it { should be_valid }
    it {should_not be_admin }

    describe "accessible attributes" do
      it "should not allow access to admin" do
        expect do
          User.new(:admin => "1")
        end.should raise_error(ActiveModel::MassAssignmentSecurity::Error)
      end
    end

    describe "with admin attribute set to 'true'" do
      before { @user.toggle!(:admin) }

      it { should be_admin }
    end

  	describe "when name is not present" do
  		before { @user.name = " " }
  		it { should_not be_valid }
  	end

  	describe "when email is not present" do
  		before { @user.email = " " }
  		it { should_not be_valid }
  	end

  	describe "when name is too long" do
  		before { @user.name = "a" * 51 }
  		it { should_not be_valid }
  	end

  	describe "when email format is invalid" do
  		it "should be invalid" do
  			addresses = %w[user@foo,com user_at_foo.org example.user@foo. foo@bar_baz.com foo@bar+baz.com]
  			addresses.each do |invalid_address|
  				@user.email = invalid_address
  				@user.should_not be_valid
  			end
  		end
  	end

  	describe "when email format is valid" do
  		it "should be valid" do
  			addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+be@baz.cn]
  			addresses.each do |valid_address|
  				@user.email = valid_address
  				@user.should be_valid
  			end	
  		end
  	end

  	describe "when email address is already taken" do
  		before do
  			user_with_same_email = @user.dup
  			user_with_same_email.email = @user.email.upcase
  			user_with_same_email.save
  		end

  		it { should_not be_valid }
  	end	

  	describe "when password is not present" do
  		before { @user.password = @user.password_confirmation = " " }
  		it { should_not be_valid }
  	end

  	describe "when password doesn't match confirmation" do
  		before { @user.password_confirmation = "mismatch" }
  		it { should_not be_valid }
  	end

  	describe "when password confirmation is nil" do
  		before { @user.password_confirmation = nil }
  		it { should_not be_valid }
  	end

  	describe "when password is too short" do
  		before { @user.password = @user_password_confirmation = "a" * 5 }
  		it { should_not be_valid }
  	end

  	describe "return value of authenticate method" do
  		before { @user.save }
  		let(:found_user) { User.find_by_email(@user.email) }

  		describe "with valid password" do
  			it { should == found_user.authenticate(@user.password) }
  		end

  		describe "with invalid password" do
  			let(:user_for_invalid_password) { found_user.authenticate("invalid") }

  			it { should_not ==  user_for_invalid_password }
  			specify {user_for_invalid_password.should be_false }
  		end
  	end

    describe "remember token" do
      before { @user.save }
      its(:remember_token) { should_not be_blank }
    end

    describe "micropost associations" do

      before { @user.save }
      let!(:older_micropost) do
        FactoryGirl.create(:micropost, :user => @user, :created_at => 1.day.ago)
      end
      let!(:newer_micropost) do
        FactoryGirl.create(:micropost, :user => @user, :created_at => 1.hour.ago)
      end

      it "should have the right microposts in the right order" do
        @user.microposts.should == [newer_micropost, older_micropost]
      end

      it "should destroy associated microposts" do
        microposts = @user.microposts
        @user.destroy
        microposts.each do |micropost|
          Micropost.find_by_id(micropost.id).should be_nil
        end
      end
    end
end
