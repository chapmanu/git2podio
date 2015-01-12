require 'active_support'
require 'sinatra'
require 'sinatra/activerecord'
require 'podio'
require 'octokit'
require 'pry-byebug'

# Database 
require_relative 'db_conn'

# Models
require_relative 'id_set'
require_relative 'chapman_podio_issue'

# Initialize Configuration
CONFIG = YAML.load_file('config/setup.yml')

# Main Hook Callback
post '/' do
  
  # Podio login & client object setup
  Podio.setup(:api_key => CONFIG[:podio_api_key], :api_secret => CONFIG[:podio_api_secret])
  Podio.client.authenticate_with_app(CONFIG[:podio_app_id], CONFIG[:podio_app_token])

  # Github login
  client = Octokit::Client.new :login => CONFIG[:git_login], :password => CONFIG[:git_password]

  case params['type']
	when 'hook.verify'
		# Validate the webhook
		puts "Hook verified!"
		Podio::Hook.validate(params['hook_id'], params['code'])

	when 'item.create'
		issue = Podio::Item.find_basic(params['item_id'])
		chapman_issue = ChapmanPodioIssue.new(params['item_id'], issue, client)
		
		# Database entry parameters
		pod_id = params['item_id']
		git_hash = chapman_issue.create_on_github
		git_id = git_hash[:id]
		git_repo = git_hash[:repo]

		id_set = IdSet.new(pod_id: pod_id, git_id: git_id, repo: git_repo)
		id_set.save

	when 'item.update'

		issue = Podio::Item.find_basic(params['item_id'])
		curr_rev = issue.attributes[:current_revision]['revision']

		# An 'unrevised' issue should have a revision level of 1 b/c we revised the issue number when it was created
		if curr_rev > 1
			prev_rev = curr_rev - 1

			# If it's an Issue Number, discard change completely.
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