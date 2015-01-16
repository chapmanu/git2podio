# PASTE IN UNDER CONFIG INIT; USE THIS TO MANUALLY ADD MULTIPLE ISSUES FROM GITHUB

# Github login
client = Octokit::Client.new :login => CONFIG["git_login"], :password => CONFIG["git_password"]

Podio.setup(:api_key => CONFIG["podio_api_key"], :api_secret => CONFIG["podio_api_secret"])
Podio.client.authenticate_with_app(CONFIG["podio_app_id"], CONFIG["podio_app_token"])

#IdSet.delete_all("repo = 'chapmanu/cu-wp-template'")

GITHUB_MEMBERS = {"megagie" => 109693330, "jameskerr" => 138626396, "bcole808" => 109709529, "homeofmatt" => 147115527}
FIELDS_MAP     = {title: '72675682', issue_number: '72678301', description: '72676401', project: '72676406', category: '80284837', status: '72676409', assigned_to: '72676405'}

#=begin
issues_list = client.list_issues("chapmanu/web-components", :direction => "asc", :page => 1)
for i in 0...issues_list.size
	git_id      = issues_list[i][:number]
	repo        = 'chapmanu/web-components'
	title       = issues_list[i][:title]
	description = issues_list[i][:body]
	description = "<p>#{description}</p>"
	project     = 223898171
	status      = "Current"
	assigned_to = nil

	if !issues_list[i][:assignee].nil?
		assigned_to = issues_list[i][:assignee][:login]
	end

	category = nil
	if issues_list[i][:labels].empty?
		category = "Issue"
	else
		if issues_list[i][:labels][0][:name] =~ /Bug|Enhancement|Question/
			has_cat = issues_list[i][:labels][0][:name] =~ /Bug|Enhancement|Question/
			category = has_cat ? issues_list[i][:labels][0][:name] : "Issue"
		elsif issues_list[i][:labels][0][:name] =~ /bug|enhancement|question/
			has_cat = issues_list[i][:labels][0][:name] =~ /bug|enhancement|question/
			category = has_cat ? issues_list[i][:labels][0][:name].capitalize : "Issue"
		end
	end

	podio_user_name = nil
	if GITHUB_MEMBERS[assigned_to]
		podio_user_name = GITHUB_MEMBERS[assigned_to]
	end

	new_item = Podio::Item.create(CONFIG["podio_app_id"], {fields: {FIELDS_MAP[:title] => title, FIELDS_MAP[:issue_number] => git_id.to_s, FIELDS_MAP[:description] => description, FIELDS_MAP[:project] => project, FIELDS_MAP[:category] => category, FIELDS_MAP[:status] => status, FIELDS_MAP[:assigned_to] => podio_user_name}}, {:hook => false})
	pod_id = new_item["item_id"]

	id_set = IdSet.new(pod_id: pod_id, git_id: git_id, repo: repo)
	id_set.save

end

#=end