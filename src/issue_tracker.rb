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
		puts "Item created!"
		#issue = Podio::Item.find_basic(params['item_id'])

		#title = issue.attributes[:title].to_s
		#desc = issue.attributes[:fields][1]["values"][0]["value"][3..-5].to_s

		#figure out sending podio info to github through project name.
		binding.pry
		#client.create_issue("chapmanu/git2podio", title, desc)
		client.create_issue("chapmanu/git2podio", 'test test', 'the quick brown fox')

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