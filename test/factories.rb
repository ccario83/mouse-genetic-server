FactoryGirl.define do
	factory :user do
		first_name "Ace"
		last_name "Adams"
		email "ace@example.com"
		password "foobar"
		password_confirmation "foobar"
		admin true
		institution "University of Pittsburgh"
	end

	factory :membership do
		association :user
		association :group
	end

	factory :group do
		name "Sample Group"
		description "This a sample group"
		association :creator, factory: :user
	end
end