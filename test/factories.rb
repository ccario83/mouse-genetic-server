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

end