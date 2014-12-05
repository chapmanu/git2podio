require 'active_support'
require 'sinatra'
require 'podio'
require 'octokit'
require 'pry-byebug'

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
		#grab basic info for new podio issue
		issue = Podio::Item.find_basic(params['item_id'])
		puts issue.inspect

		#TITLE, ISSUE NUMBER, DESCRIPTON, 
		#title and description for issue
		title = issue.attributes[:title]
		desc = issue.attributes[:fields][2]["values"][0]["value"][3..-5]

		#determine which repo to send issue to
		repo = issue.attributes[:fields][4]["values"][0]["value"]["title"]
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

		#determine if issue is bug or not
		if issue.attributes[:tags].include? 'bug' or issue.attributes[:tags].include? 'Bug'
			git_issue = client.create_issue(repo, title, desc, {:labels => ["bug"]})
		else
			git_issue = client.create_issue(repo, title, desc)
		end

		issue_num = git_issue[:number].to_i
		Podio::Item.update(issue.attributes[:item_id], {:fields => {"fields"[1]["values"][0]["value"] => issue_num}})

	when 'item.update'
		puts "Item updated!"

		issue = Podio::Item.find_basic(params['item_id'])
		pusts issue.inspect

	when 'item.delete'
		puts "Item deleted"
	else
		puts "Invalid hook verify: #{params.inspect}"
	end
end