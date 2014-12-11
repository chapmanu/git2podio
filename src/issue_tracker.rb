require 'active_support'
require 'sinatra'
require 'podio'
require 'octokit'
require 'pry-byebug'
require 'chapman_podio_issue.rb'

post '/' do
  
  #podio login & client object setup
  Podio.setup(:api_key => 'issues', :api_secret => 'QnVQnkCQkCBBsYiVWcdVpuQS3TlvYaDfc3xacXj9n2bNvULAYCOg4MM9TOV5LGaq')
  Podio.client.authenticate_with_app('9343326', '8a6c2571599e470d8dbaae867a70ce94')

  #github login
  client = Octokit::Client.new :login => 'CharlesChapman', :password => 'M@rket2009'

  case params['type']
	when 'hook.verify'
		# Validate the webhook
		puts "Hook verified!"
		Podio::Hook.validate(params['hook_id'], params['code'])

	when 'item.create'
		chapman_issue = ChapmanPodioIssue.new(params['item_id'])
		chapman_issue.create_on_github


		# Step 1 Get issue from podio
		# Step 2 Create issue on github
		# Step 3 Updated github cateog
		# Step 4 Update podio issue
		


		#grab basic info for new podio issue
=begin
		issue = Podio::Item.find_basic(params['item_id'])
		puts issue.attributes[:fields]

		#title and description for issue
		title = issue.attributes[:title]
		desc = issue.attributes[:fields][2]["values"][0]["value"][3..-5]

		#determine which repo to send issue to
		repo = issue.attributes[:fields][3]["values"][0]["value"]["title"]
		case repo
			when 'Social', 'Inside', 'Events'
				repo = "chapmanu/inside"
			when 'Blogs'
				repo = "chapmanu/cu-wp-template"
			when 'Homepage'
				repo = "chapmanu/web-components"
			else
				puts "Invalid Podio issue made: #{title}."
				repo = "chapmanu/git2podio"
			end

		#create issue in github and give it correct tag
		git_issue = nil
		category = issue.attributes[:fields][4]["values"][0]["value"]["text"]
		case category
			when 'Bug'
				git_issue = client.create_issue(repo, title, desc, {:labels => ["bug"]})
			when 'Enhancement'
				git_issue = client.create_issue(repo, title, desc, {:labels => ["enhancement"]})
			when 'Question'
				git_issue = client.create_issue(repo, title, desc, {:labels => ["question"]})
			else
				git_issue = client.create_issue(repo, title, desc)
		end

		#update the Podio item id with the corresponding github issue id
		Podio::ItemField.update(params['item_id'], issue.attributes[:fields][1]["field_id"], {:value => git_issue[:number].to_s}, {:hook => false})
		#Podio::ItemField.update(params['item_id'], issue.attributes[:fields][1]["field_id"], {:config => git_issue[:number].to_s}, {:hook => false})

		#close the issue on github if the status on Podio is set to complete
		status = issue.attributes[:fields][5]["values"][0]["value"]["text"]
		if status == "Complete"
			client.close_issue(repo, git_issue[:number])
		end
=end

	when 'item.update'
		puts "Item updated!"

		issue = Podio::Item.find_basic(params['item_id'])
		

		item_id = params['item_id']
		field_id = issue.attributes[:fields][1]["field_id"]

		Podio::ItemField.update(item_id, field_id, {:value => '30'}, {:hook => false})
		#Podio::ItemField.update(item_id, field_id, {:config => '31'}, {:hook => false})

		puts issue.attributes[:fields]

	when 'item.delete'
		puts "Item deleted"
	else
		puts "Invalid hook verify: #{params.inspect}"
	end
end