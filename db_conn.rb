db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/database')

ActiveRecord::Base.establish_connection(
    :adapter => 'postgresql',
    :host => db.host,
    :username => db.user,
    :database => db.path,
    :port => db.port,
    :encoding => 'utf8'
)