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

##### From Podio to Github #####
class ChapmanPodioIssue
	def initialize(item_id, issue, client)
		@item_id = item_id
		@git_client = client

		@curr_rev = issue.attributes[:current_revision]['revision']

		@fields_hash = {}

		issue.attributes[:fields].each do |field|
			field_id = field["field_id"].to_s
			@fields_hash[field_id] = field["values"][0]["value"]
		end

	end

	FIELDS_MAP = {title: '72675682', issue_number: '72678301', description: '72676401', project: '72676406', category: '80284837', status: '72676409', assigned_to: '72676405'}
	PODIO_MEMBERS = {"Meghan Farrington" => "megagie", "James Kerr" => "jameskerr", "Ben Cole" => "bcole808", "Matt Congel" => "homeofmatt"}

	##### Get all individual fields #####
	def get_title
		@fields_hash[FIELDS_MAP[:title]] || ""
	end

	def get_issue_number
		@fields_hash[FIELDS_MAP[:issue_number]] || ""
	end

	def get_description
		@fields_hash[FIELDS_MAP[:description]] || ""
	end

	def get_repo
		@fields_hash[FIELDS_MAP[:project]] || ""
	end

	def get_category
		@fields_hash[FIELDS_MAP[:category]] || ""
	end

	def get_status
		@fields_hash[FIELDS_MAP[:status]] || ""
	end

	def get_assigned_to
		@fields_hash[FIELDS_MAP[:assigned_to]] || ""
	end

	def map_repo_to_git(repo)
		case repo
			when 'Social', 'Inside', 'Events'
				repo = "chapmanu/inside"
			when 'Blogs'
				repo = "chapmanu/blogs"
			when 'Homepage', 'Web Components'
				repo = "chapmanu/web-components"
			else
				repo = "chapmanu/git2podio"
		end

		return repo
	end

	def create_on_github
		title       = get_title
		issue_num   = get_issue_number
		desc        = get_description
		desc        = desc[3..-5]
		repo        = get_repo
		category    = get_category
		status      = get_status
		assigned_to = get_assigned_to

		# Determine which repo to send issue to
		repo = map_repo_to_git(repo["title"])
		if repo == "chapmanu/git2podio"
			puts "Invalid/Miscellaneous Podio issue made: #{title}. Will be located in chapmanu/git2podio."
		end
 		
 		# Create issue in github and give it correct tag
		git_issue = nil

		# Label
		has_label = category["text"] =~ /Bug|Enhancement|Question/
		value     = has_label ? category["text"].downcase : nil

		# Assignee
		assignee = assigned_to["name"]

		# If name not in hash, leave as nil
		github_user_name = nil
		if PODIO_MEMBERS[assignee]
			github_user_name = PODIO_MEMBERS[assignee]
		end

		# Create issue with current information
		git_issue = @git_client.create_issue(repo, title, desc, {:labels => value, :assignee => github_user_name})

		# Update the Podio item id with the corresponding github issue id
		git_id = git_issue[:number].to_s
		Podio::ItemField.update(@item_id, FIELDS_MAP[:issue_number], {:value => git_id}, {:hook => false})

		# Close the issue on github if the status on Podio is set to complete
		if status["text"] == "Complete"
			@git_client.close_issue(repo, git_id.to_i)
		end

		# Return git id and repo
		return_hash = {id: git_id, repo: repo}
		return return_hash
	end

	def update_on_github(label, revision)
		# Grab database info on issue
		db_record = IdSet.where(pod_id: @item_id).first

		if label == "Issue Number"
			# If user tries to change Issue Number, we set it back.
			prev_num = revision[0][:from][0]["value"]
			Podio::ItemField.update(@item_id, FIELDS_MAP[:issue_number], {:value => prev_num}, {:hook => false})

		elsif label == "Project"
			# Check project name in podio against prev project name
			new_repo  = revision[0][:to][0]["value"]["title"]

			# Translate new podio repo name to github repo name
			new_repo = map_repo_to_git(new_repo)

			# Determine if issue should be moved
			if db_record.repo != new_repo
				# Get github issue
				old_git_issue = @git_client.issue(db_record.repo, db_record.git_id)

				# Get information from old issue
				title    = old_git_issue[:title]
				desc     = old_git_issue[:body]
				label    = old_git_issue[:labels][0][:name]
				status   = old_git_issue[:state]
				assignee = old_git_issue[:assignee][:login]

				# Add comment to old issue on github and close issue
				@git_client.add_comment(db_record.repo, db_record.git_id, "Issue moved to: #{new_repo}")
				@git_client.close_issue(db_record.repo, db_record.git_id)

				# Create new issue in new repository & close if prev issue was closed
				git_issue = @git_client.create_issue(new_repo, title, desc, {:labels => label, :assignee => assignee})
				if status != "open"
					@git_client.close_issue(new_repo, git_issue[:number])
				end

				# Update the Podio item id with the corresponding github issue id
				Podio::ItemField.update(@item_id, FIELDS_MAP[:issue_number], {:value => git_issue[:number].to_s}, {:hook => false})

				# Update database 
				db_record.repo   = new_repo
				db_record.git_id = git_issue[:number]
				db_record.save
			end

		elsif label == "Issue" || label == "Description"
			# Update title and/or description if changed
			title = get_title
			desc  = get_description
			desc  = desc[3..-5]

			@git_client.update_issue(db_record.repo, db_record.git_id, title, desc)

		elsif label == "Category"
			# Update label
			category  = get_category

			has_label = category["text"] =~ /Bug|Enhancement|Question/
			value = has_label ? category["text"].downcase : nil

			@git_client.update_issue(db_record.repo, db_record.git_id, :labels => [value])

		elsif label == "Status"
			# Update status
			status = get_status
			git_issue = @git_client.issue(db_record.repo, db_record.git_id)
			old_git_issue = @git_client.issue(db_record.repo, db_record.git_id)
			prev_status   = old_git_issue[:state]

			# Because 'Backlog' and 'Current' translate to 'open' on github, a switch between the two is ignored
			if status["text"] != "Complete" && prev_status != "open"
				@git_client.reopen_issue(db_record.repo, db_record.git_id)
			elsif status["text"] == "Complete" && prev_status == "open"
				@git_client.close_issue(db_record.repo, db_record.git_id)
			end

		elsif label == "Assigned To"
			# Update assignee
			assigned_to = get_assigned_to
			assignee = assigned_to["name"]

			# If name not in hash, leave as nil
			github_user_name = nil
			if PODIO_MEMBERS[assignee]
				github_user_name = PODIO_MEMBERS[assignee]
			end

			@git_client.update_issue(db_record.repo, db_record.git_id, :assignee => github_user_name)
		end
	end

	private :get_title, :get_issue_number, :get_description, :get_category, :get_status, :get_assigned_to, :map_repo_to_git
end