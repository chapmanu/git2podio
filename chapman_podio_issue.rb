require 'active_support'
require 'sinatra'
require 'sinatra/activerecord'
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

	FIELDS_MAP = {title: '72675682', issue_number: '72678301', description: '72676401', project: '72676406', category: '80284837', status: '72676409', assigned_to: '72676405'}

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

	#def get_reported_by
	#	@fields_hash[FIELDS_MAP[:reported_by]] || ""
	#end

	def create_on_github
		title       = get_title
		issue_num   = get_issue_number
		desc        = get_description
		desc        = desc[3..-5]
		repo        = get_repo
		category    = get_category
		status      = get_status
		assigned_to = get_assigned_to
		#reported_by = get_reported_by

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

		#label
		has_label = category["text"] =~ /Bug|Enhancement|Question/
		labels    = has_label ? category["text"].downcase : nil

		#assigned_to
		assignee = assigned_to["name"]

		if assignee == "Meghan Farrington"
			assignee = "megagie"
		elsif assignee == "James Kerr"
			assignee = "jameskerr"
		elsif assignee == "Ben Cole"
			assignee = "bcole808"
		elsif assignee == "Matt Congel"
			assignee = "homeofmatt"
		else
			assignee = nil
		end

		#create issue with current information
		git_issue = @git_client.create_issue(repo, title, desc, {:labels => labels, :assignee => assignee})

		#update the Podio item id with the corresponding github issue id
		Podio::ItemField.update(@item_id, FIELDS_MAP[:issue_number], {:value => git_issue[:number].to_s}, {:hook => false})

		#close the issue on github if the status on Podio is set to complete
		if status["text"] == "Complete"
			@git_client.close_issue(repo, git_issue[:number])
		end

		return git_issue[:number].to_s
	end

	def update_on_github(label, revision)
		#We can only update the title, body, assignee, labels, & status

		if label == "Issue Number"
			# If user tries to change Issue Number, we set it back.
			prev_num = revision[0][:from][0]["value"]["text"]
			Podio::ItemField.update(@item_id, FIELDS_MAP[:issue_number], {:value => prev_num}, {:hook => false})

		elsif label == "Project"
			# Same process as Issue Number, but for Repository
			prev_repo = revision[0][:from][0]["value"]["text"]
			Podio::ItemField.update(@item_id, FIELDS_MAP[:project], {:value => prev_repo}, {:hook => false})

		else
			puts "gimme a minute"
		end
	end

	private :get_title, :get_issue_number, :get_description, :get_category, :get_status, :get_assigned_to
end