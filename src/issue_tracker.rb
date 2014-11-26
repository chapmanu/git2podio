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

get '/' do
  if issue
  	'hello world'
  else
  	'hello noooo :('
  end

  case params['type']
	when 'hook.verify'
		# Validate the webhook
		Podio::Hook.validate(params['hook_id'], params['code'])
	when 'item.create'
		"Item created!"
	when 'item.update'
		"Item updated!"
	when 'item.delete'
		"Item deleted"
	else
		"Invalid hook verify: #{params['type']}"
	end
end