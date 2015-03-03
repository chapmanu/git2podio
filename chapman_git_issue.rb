require 'active_support'
require 'sinatra'
require 'sinatra/activerecord'
require 'podio'
require 'octokit'
require 'pry-byebug'

# Models & Objects
require_relative 'id_set'

# Database
require_relative 'db_conn'

class ChapmanGitIssue
	def initialize(client, issue, repo, git_id, app_id)
		@git_client = client
		@issue      = issue
		@repo       = repo
		@git_id     = git_id
		@app_id     = app_id

	end

	FIELDS_MAP     = {title: '72675682', issue_number: '72678301', description: '72676401', project: '72676406', category: '80284837', status: '72676409', assigned_to: '72676405'}
	GITHUB_MEMBERS = {"megagie" => 109693330, "jameskerr" => 138626396, "bcole808" => 109709529, "homeofmatt" => 147115527}
	
	def map_repo_to_podio(repo)
		repo_id = nil
		case repo
			when 'chapmanu/inside'
				repo_id = 223897464 # Project id for Inside
			when 'chapmanu/cu-blogs'
				repo_id = 223897311 # Project id for Blogs
			when 'chapmanu/web-components'
				repo_id = 249847911 # Project id for Web Components
			else
				repo_id = 249860249 # Project id for Miscellaneous
		end

		return repo_id
	end

	def open_issue

		# Check if issue exists on Podio
		if IdSet.exists?(git_id: @git_id, repo: @repo)
			# Issue was closed but not deleted on Podio, so we simply change Podio status
			id_set = IdSet.where(git_id: @git_id, repo: @repo).first
			item_id = id_set[:pod_id]
			Podio::ItemField.update(item_id, FIELDS_MAP[:status], {:value => "Current"}, {:hook => false})

		else # Create a new issue on Podio
			# Get all values and parse them into Podio-readable values
			title       = @issue["issue"]["title"]
			description = @issue["issue"]["body"]
			project     = map_repo_to_podio(@repo)
			status      = "Current"
			assigned_to = nil

			puts @issue["issue"].inspect

			# If there are no labels present on Github
			category = nil
			if @issue["issue"]["labels"].empty?
				category = "Issue"
			else
				has_cat = @issue["issue"]["labels"][-1]["name"] =~ /bug|enhancement|question/
				category = has_cat ? @issue["issue"]["labels"][-1]["name"].capitalize : "Issue"
			end
			
			# If assignee name is not in hash, leave as nil
			podio_user_name = nil
			if @issue["issue"]["assignee"] == nil
				podio_user_name = nil
			else
				assigned_to = @issue["issue"]["assignee"]["login"]
				podio_user_name = GITHUB_MEMBERS[assigned_to]
			end

			# If issue is sent to Miscellaneous, put in the github repo it came from
			if project == 249860249
				repo_name = @repo
				description = "<p>#{description} -----Issue arrived from: #{repo_name}</p>"
			else
				description = "<p>#{description}</p>"
			end

			# Create issue on Podio & get new item id
			new_item = Podio::Item.create(@app_id, {fields: {FIELDS_MAP[:title] => title, FIELDS_MAP[:issue_number] => @git_id.to_s, FIELDS_MAP[:description] => description, FIELDS_MAP[:project] => project, FIELDS_MAP[:category] => category, FIELDS_MAP[:status] => status, FIELDS_MAP[:assigned_to] => podio_user_name}}, {:hook => false})
			pod_id = new_item["item_id"]

			# Add record to database
			id_set = IdSet.new(pod_id: pod_id, git_id: @git_id, repo: @repo)
			id_set.save
		end
	end

	def close_issue
		# Get record from database
		id_set = IdSet.where(git_id: @git_id, repo: @repo).first
		item_id = id_set[:pod_id]

		# Update field
		Podio::ItemField.update(item_id, FIELDS_MAP[:status], {:value => "Complete"}, {:hook => false})
	end

	def label_issue
		# If there are no labels present on Github
		category = nil
		if @issue["issue"]["labels"].empty?
			category = "Issue"
		else # Get the most recent label added, if not a bug, enhancement, or question, labels it Issue
			has_cat = @issue["issue"]["labels"][-1]["name"] =~ /bug|enhancement|question/
			category = has_cat ? @issue["issue"]["labels"][-1]["name"].capitalize : "Issue"
		end

		# Get record from database
		id_set = IdSet.where(git_id: @git_id, repo: @repo).first

		item_id = nil
		if id_set && id_set[:pod_id]
			item_id = id_set[:pod_id]
			# Update field
			Podio::ItemField.update(item_id, FIELDS_MAP[:category], {:value => category}, {:hook => false})
		end
	end

	def assign_issue
		assignee = @issue["issue"]["assignee"]["login"]

		# If assignee name is not in hash, leave as nil
		podio_user = nil
		if GITHUB_MEMBERS[assignee]
			podio_user = GITHUB_MEMBERS[assignee]
		end

		# Get record from database
		id_set = IdSet.where(git_id: @git_id, repo: @repo).first

		item_id = nil
		if id_set && id_set[:pod_id]
			item_id = id_set[:pod_id]
			# Update field
			Podio::ItemField.update(item_id, FIELDS_MAP[:assigned_to], {:value => podio_user}, {:hook => false})
		end
	end

end