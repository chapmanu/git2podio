require './issue_tracker'
set :database, ENV['DATABASE_URL'] || 'postgres://localhost/id_sets'
run Sinatra::Application
