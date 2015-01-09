require 'active_support'
require 'sinatra'
require 'sinatra/activerecord'
require 'podio'
require 'octokit'
require 'pry-byebug'
require_relative 'chapman_podio_issue'
require_relative 'db_conn'
require_relative 'id_set'

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
		
		pod_id = params['item_id']
		git_id = chapman_issue.create_on_github
		git_repo = chapman_issue.get_repo #if this doesnt work get repo from params.
		
		title =  git_repo['title']

		case title
			when 'Social', 'Inside', 'Events'
				git_repo = "chapmanu/inside"
			when 'Blogs'
				git_repo = "chapmanu/cu-wp-template"
			when 'Homepage'
				git_repo = "chapmanu/web-components"
			else
				git_repo = "chapmanu/git2podio"
		end

		id_set = IdSet.new(pod_id: pod_id, git_id: git_id, repo: git_repo)
		id_set.save

	when 'item.update'

		puts "Update incomplete atm."

		issue = Podio::Item.find_basic(params['item_id'])
		curr_rev = issue.attributes[:current_revision]['revision']

		# An 'unrevised' issue should have a revision level of 1 b/c we revised the issue number when it was created
		if curr_rev > 1
			prev_rev = curr_rev - 1

			# Get the label
			# If it's an Issue Number or a Project, discard change completely.
			revision = Podio::ItemDiff.find_by_item_and_revisions(params['item_id'], prev_rev, curr_rev)
			revision = revision.map{|x| x.attributes}
			label = revision[0][:label]

			chapman_issue = ChapmanPodioIssue.new(params['item_id'], issue, client)
			chapman_issue.update_on_github(label, revision)
		else
			puts "Unrevised post, invalid update."
		end

	when 'item.delete'
		pod_id = params['item_id']
		id_set = IdSet.where(pod_id: pod_id).first
		repo = id_set[:repo]
		git_id = id_set[:git_id]

		client.close_issue(repo, git_id)
		id_set.destroy

	else
		puts "Invalid hook verify: #{params.inspect}"
	end
end