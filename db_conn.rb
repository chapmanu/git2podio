db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/id_sets')

ActiveRecord::Base.establish_connection(
    :adapter => 'postgresql',
    :host => db.host,
    :username => db.user,
    :database => db.path[1..-1],
    :port => db.port,
    :encoding => 'utf8'
)