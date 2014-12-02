require 'active_support'
require 'sinatra'
require 'podio'
require 'octokit'

#podio login & client object setup
Podio.setup(:api_key => 'issues', :api_secret => 'QnVQnkCQkCBBsYiVWcdVpuQS3TlvYaDfc3xacXj9n2bNvULAYCOg4MM9TOV5LGaq')
Podio.client.authenticate_with_app('9343326', '8a6c2571599e470d8dbaae867a70ce94')

#github login
client = Octokit::Client.new \
	:login    => 'CharlesChapman',
	:password => 'M@rket2009'

issue = Podio::Item.find_basic(195879868)
puts issue[:app]

post "/" do
  if issue
  	puts 'hello world'
  else
  	puts 'hello noooo :('
  end

  puts "Parameters: #{params.inspect}"

  case params['type']
	when 'hook.verify'
		# Validate the webhook
		puts "Hook verified!"
		Podio::Hook.validate(params['hook_id'], params['code'])
	when 'item.create'
		puts "Item created!"
	when 'item.update'
		puts "Item updated!"
	when 'item.delete'
		puts "Item deleted"
	else
		puts "Invalid hook verify: #{params.inspect}"
	end
end