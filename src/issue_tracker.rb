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
		puts "Item updated!"

		client.org_members('chapmanu').each do |member|
			if member['login']
				puts member['login']
		end

	when 'item.delete'
		puts "Item deleted"
	else
		puts "Invalid hook verify: #{params.inspect}"
	end
end