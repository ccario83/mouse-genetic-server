FactoryGirl.define do
	factory :communication do
		association :recipient, factory: :user
		recipient_type "Group"
		association :micropost
	end

	factory :datafile do
		association :owner, factory: :user
		filename "Samplefile.txt"
		uwf_runnable true
	end

	factory :group do
		name "Sample Group"
		description "This a sample group"
		association :creator, factory: :user
	end

	factory :membership do
		association :user
		association :group
	end

	factory :micropost do
		content "This is a sample micropost."
		association :creator, factory: :user
		recipient_type "Group"
		user_recipients Array.new
		group_recipients Array.new
	end

	factory :task do
		description "Random Task"
		association :creator, factory: :user
		association :group
		association :assignee, factory: :user
		due_date 3.weeks.from_now.to_date
		completed false
	end

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