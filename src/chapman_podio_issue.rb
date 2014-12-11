require 'active_support'
require 'sinatra'
require 'podio'
require 'octokit'
require 'pry-byebug'

class ChapmanPodioIssue
	def initialize(item_id, issue, client)
		@item_id = item_id
		@git_client = client

		@fields_hash = {}

		issue.attributes[:fields].each do |field|
			field_id = field["field_id"].to_s
			@fields_hash[field_id] = field["values"][0]["value"]
		end

		puts @fields_hash.inspect
	end

	FIELDS_MAP = {title: '72675682', issue_number: '72678301', description: '72676401', project: '72676406', category: '80284837', status: '72676409', assigned_to: '72676405', reported_by: '72676404'}

	##### Get all individual fields #####
	def get_title
		title = @fields_hash[FIELDS_MAP[:title]]
		if title != nil
			return title
		else
			return ""
		end
	end

	def get_issue_number
		issue_number = @fields_hash[FIELDS_MAP[:issue_number]]
		if issue_number != nil
			return issue_number
		else
			return ""
		end
	end

	def get_description
		description = @fields_hash[FIELDS_MAP[:description]]
		if description != nil
			return description
		else
			return ""
		end
	end

	def get_repo
		repo = @fields_hash[FIELDS_MAP[:project]]
		if repo != nil
			return repo
		else
			return ""
		end
	end

	def get_category
		category = @fields_hash[FIELDS_MAP[:category]]
		if category != nil
			return category
		else
			return ""
		end
	end

	def get_status
		status = @fields_hash[FIELDS_MAP[:status]]
		if status != nil
			return status
		else
			return ""
		end
	end

	def get_assigned_to
		assigned_to = @fields_hash[FIELDS_MAP[:assigned_to]]
		if assigned_to != nil
			return assigned_to
		else
			return ""
		end
	end

	def get_reported_by
		reported_by = @fields_hash[FIELDS_MAP[:reported_by]]
		if reported_by != nil
			return reported_by
		else
			return ""
		end
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
		reported_by = get_reported_by

		#determine which repo to send issue to
		case repo["title"]
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
		case category["text"]
			when 'Bug'
				git_issue = @git_client.create_issue(repo, title, desc, {:labels => ["bug"]})
			when 'Enhancement'
				git_issue = @git_client.create_issue(repo, title, desc, {:labels => ["enhancement"]})
			when 'Question'
				git_issue = @git_client.create_issue(repo, title, desc, {:labels => ["question"]})
			else
				git_issue = @git_client.create_issue(repo, title, desc)
		end

		#update the Podio item id with the corresponding github issue id
		Podio::ItemField.update(@item_id, FIELDS_MAP[:issue_number], {:value => git_issue[:number].to_s}, {:hook => false})

		#close the issue on github if the status on Podio is set to complete
		if status["text"] == "Complete"
			client.close_issue(repo, git_issue[:number])
		end
	end

	private :get_title, :get_issue_number, :get_description, :get_repo, :get_category, :get_status, :get_assigned_to, :get_reported_by
end