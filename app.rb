# frozen_string_literal: true

require 'bundler/setup'
require 'pg'
require 'sinatra'
require 'connection_pool'
require 'ostruct'
require 'warden'
require 'bcrypt'
require 'pathname'
require_relative 'lib/pg_note'
require_relative 'lib/pg_user_notes'
require_relative 'lib/pg_users'
require_relative 'lib/pg_user'
require_relative 'lib/warden_password_strategy'
require_relative 'lib/owned_note'
require_relative 'lib/migration'
require_relative 'lib/pending_migrations'
require_relative 'lib/clock'
require_relative 'lib/timestamped_id'
require_relative 'lib/pg_schema'
require_relative 'lib/migrations'

def pg_connection
  @pg_connection ||= ConnectionPool::Wrapper.new(size: 5, timeout: 5) do
    pg_connection = PG::Connection.new(host: ENV.fetch('PG_HOST', nil),
                                       user: ENV.fetch('PG_USER', nil),
                                       password: ENV.fetch('PG_PASSWORD', nil))
    pg_connection.type_map_for_results = PG::BasicTypeMapForResults.new(pg_connection)
    pg_connection.type_map_for_queries = PG::BasicTypeMapForQueries.new(pg_connection)
    pg_connection
  end
end

set :default_content_type, :json
set :show_exceptions, false

configure :development do
  Sinatra::Application.reset!
  use Rack::Reloader
end

enable :sessions
use Warden::Manager do |manager|
  manager.failure_app = Sinatra::Application
  manager.default_strategies :password
end

Warden::Manager.serialize_into_session(&:id)

Warden::Manager.serialize_from_session do |id|
  PgUser.new(id, pg_connection)
end

Warden::Manager.before_failure do |env, _opts|
  # Unauthenticated requests always end up in `post /unauthenticated` route no matter
  # what the initial request method
  env['REQUEST_METHOD'] = 'POST'
end

Warden::Strategies.add(:password, WardenPasswordStrategy)

before do
  PendingMigrations.new(Migrations.new(pg_connection:)).ensure_applied unless settings.test?
end

post '/' do
  warden.authenticate!
  redirect '/'
end

post '/unauthenticated' do
  only_json_accepted = request.accept.size == 1 && request.accept?(Rack::Mime.mime_type('.json'))

  if only_json_accepted
    status :forbidden
  else
    content_type :html
    erb :sign_in
  end
end

get '/sign_out' do
  warden.logout
  redirect '/'
end

helpers do
  def escape_html(text)
    Rack::Utils.escape_html(text)
  end

  def body_class
    result = case request.path
             when '/'
               'notes'
             when '/unauthenticated'
               'unauthenticated'
             else
               'unknown'
             end

    "page-#{result}"
  end

  def current_user
    warden.user
  end

  def warden
    env['warden']
  end
end

error OwnedNote::OwnershipError do
  status :not_found
end

error PgNote::NotFoundError do
  status :not_found
end

error PendingMigrations::MigrationsPendingError do
  content_type :text
  env['sinatra.error'].message
end

get '/' do
  warden.authenticate!

  pg_notes = PgUserNotes.new(current_user.id, pg_connection)
  content_type :html
  headers['Content-Security-Policy'] = "default-src 'self'"
  erb :index, locals: { notes: pg_notes.fetch }
end

post '/notes' do
  warden.authenticate!

  pg_notes = PgUserNotes.new(current_user.id, pg_connection)
  text = params[:text]
  position = params[:position].to_i
  inserted_id = pg_notes.add(text, position)

  pg_note = PgNote.new(inserted_id, pg_connection)
  pg_note.json
end

patch '/notes/:id' do
  warden.authenticate!

  note = OwnedNote.new(user: current_user, note: PgNote.new(params[:id], pg_connection))
  note.update(text: params[:text])
  note.json
end

delete '/notes/:id' do
  warden.authenticate!

  pg_note = OwnedNote.new(user: current_user, note: PgNote.new(params[:id], pg_connection))
  pg_note.delete
end

patch '/notes/:id/swap' do
  warden.authenticate!

  pg_note = OwnedNote.new(user: current_user, note: PgNote.new(params[:id], pg_connection))
  target_note = PgNote.new(params[:note_id], pg_connection)
  pg_note.swap(target_note:)
end

get '/notes' do
  warden.authenticate!

  pg_notes = PgUserNotes.new(current_user.id, pg_connection)
  pg_notes.json
end

get '/sse', provides: 'text/event-stream' do
  warden.authenticate!
  cache_control :no_cache
  notes = PgUserNotes.new(current_user.id, pg_connection)

  initial_ids = notes.ids
  last_updated = Time.now

  stream :keep_open do |stream|
    current_ids = notes.ids

    if current_ids != initial_ids || notes.updated_since?(last_updated)
      initial_ids = current_ids
      last_updated = Time.now
      stream << "data: #{{ updated: true }.to_json}\n\n" unless stream.closed?
    else
      stream << "hearbeat:\n\n" unless stream.closed? # SSE does not function without this
    end

    sleep 1
  # Consider catching `Puma::ConnectionError`
  rescue # rubocop:disable Style/RescueStandardError
    stream.close
  end
end

get '/sign_up' do
  content_type :html
  erb :sign_up, locals: { email: nil, password: nil, error_message: nil }
end

post '/sign_up' do
  users = PgUsers.new(pg_connection)

  begin
    id = users.add(email: params[:email], plain_password: params[:password])
    user = PgUser.new(id, pg_connection)
    warden.set_user(user)
    redirect '/'
  rescue PgUsers::ExistingUserError => e
    content_type :html
    erb :sign_up, locals: { email: params[:email], password: params[:password], error_message: e.message }
  end
end
