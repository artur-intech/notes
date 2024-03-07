# frozen_string_literal: true

require 'pg'
require 'sinatra'
require 'connection_pool'
require 'ostruct'
require 'warden'
require 'bcrypt'
require_relative 'lib/pg_note'
require_relative 'lib/pg_notes'
require_relative 'lib/pg_users'
require_relative 'lib/pg_user'
require_relative 'lib/warden_password_strategy'

def pg_connection
  ConnectionPool::Wrapper.new(size: 5, timeout: 5) do
    pg_connection = PG::Connection.new(host: ENV['PG_HOST'],
                                       user: ENV['PG_USER'],
                                       password: ENV['PG_PASSWORD'])
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

pg_notes = PgNotes.new(pg_connection)

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
  # Sinatra is very sensitive to the request method and
  # since authentication could fail on any type of method, we need
  # to set it for the failure app so it is routed to the correct block.
  env['REQUEST_METHOD'] = 'POST'
end

Warden::Strategies.add(:password, WardenPasswordStrategy)

post '/' do
  env['warden'].authenticate!
  redirect '/'
end

get '/unauthenticated' do
  only_json_accepted = request.accept.size == 1 && request.accept?(Rack::Mime.mime_type('.json'))

  if only_json_accepted
    status :forbidden
  else
    content_type :html
    erb :sign_in
  end
end

post '/unauthenticated' do
  # TODO: Combine get and post
  only_json_accepted = request.accept.size == 1 && request.accept?(Rack::Mime.mime_type('.json'))

  if only_json_accepted
    status :forbidden
  else
    content_type :html
    erb :sign_in
  end
end

get '/sign_out' do
  env['warden'].logout
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
end

get '/' do
  env['warden'].authenticate!
  content_type :html
  headers['Content-Security-Policy'] = "default-src 'self'"
  erb :index, locals: { notes: pg_notes }
end

post '/notes' do
  env['warden'].authenticate!

  text = params[:text]
  position = params[:position].to_i
  inserted_id = pg_notes.add(text, position, env['warden'].user.id)

  pg_note = PgNote.new(inserted_id, pg_connection)
  pg_note.json
end

patch '/notes/:id' do
  env['warden'].authenticate!

  pg_note = PgNote.new(params[:id].to_i, pg_connection)
  pg_note.update(params[:text])
  pg_note.json
end

delete '/notes/:id' do
  env['warden'].authenticate!

  pg_note = PgNote.new(params[:id], pg_connection)
  pg_note.delete
end

patch '/notes/:id/swap' do
  env['warden'].authenticate!

  pg_note = PgNote.new(params[:id], pg_connection)
  pg_note.swap(params[:note_id])
end

get '/notes' do
  env['warden'].authenticate!

  pg_notes = PgNotes.new(pg_connection)
  pg_notes.json
end

get '/sse', provides: 'text/event-stream' do # rubocop:disable Metrics/BlockLength
  env['warden'].authenticate!
  cache_control :no_cache

  initial_ids = []
  last_updated = Time.now

  pg_connection.exec('SELECT id FROM notes') do |result|
    result.each do |row|
      initial_ids << row['id']
    end
  end

  stream :keep_open do |stream|
    pg_result = pg_connection.exec_params('SELECT COUNT(*) FROM notes WHERE updated_at >= $1', [last_updated])
    updated_note_count = pg_result.getvalue(0, 0).to_i

    current_ids = []
    pg_connection.exec('SELECT id FROM notes') do |result|
      result.each do |row|
        current_ids << row['id'].to_i
      end
    end

    if current_ids != initial_ids || !updated_note_count.zero?
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
