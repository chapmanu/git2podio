require 'active_support'
require 'sinatra'
require 'podio'
require 'octokit'
require 'pry-byebug'
require_relative 'chapman_podio_issue'

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
		issue = Podio::Item.find_basic(params['item_id'])
		chapman_issue = ChapmanPodioIssue.new(params['item_id'], issue, client)
		chapman_issue.create_on_github

	when 'item.update'

		puts "Update incomplete atm."

		issue = Podio::Item.find_basic(params['item_id'])
		curr_rev = issue.attributes[:current_revision]['revision']

		# An 'unrevised' issue should have a revision level of 1 b/c we revised the issue number when it was created
		if curr_rev > 1
			prev_rev = curr_rev - 1

			#if it's an Issue Number or a Project, discard change completely.
			revision = Podio::ItemDiff.find_by_item_and_revisions(params['item_id'], prev_rev, curr_rev)
			label = revision[:config]["label"]
			puts label

			chapman_issue = ChapmanPodioIssue.new(params['item_id'], issue, client)
			chapman_issue.update_on_github(label, revision)
		else
			puts "Unrevised post, invalid update."
		end

	when 'item.delete'
		issue = Podio::Item.find_basic(params['item_id'])
		chapman_issue = ChapmanPodioIssue.new(params['item_id'], issue, client)
		chapman_issue.delete_on_github

	else
		puts "Invalid hook verify: #{params.inspect}"
	end
end