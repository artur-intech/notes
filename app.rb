# frozen_string_literal: true

require 'pg'
require 'sinatra'
require 'connection_pool'
require 'rack/unreloader'
require 'ostruct'
require_relative 'lib/pg_note'
require_relative 'lib/pg_notes'

pg_connection = PG::Connection.new(host: ENV['PG_HOST'],
                                   user: ENV['PG_USER'],
                                   password: ENV['PG_PASSWORD'])
pg_connection.type_map_for_results = PG::BasicTypeMapForResults.new(pg_connection)
pg_connection.type_map_for_queries = PG::BasicTypeMapForQueries.new(pg_connection)

$pg_connection_pool = ConnectionPool.new(size: 5, timeout: 5) do
  conn = PG::Connection.open(host: ENV['PG_HOST'],
                             user: ENV['PG_USER'],
                             password: ENV['PG_PASSWORD'])
  conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn)
  conn.type_map_for_queries = PG::BasicTypeMapForQueries.new(conn)
  conn
end

set :default_content_type, :json
set :show_exceptions, false

configure :development do
  Sinatra::Application.reset!
  use Rack::Reloader
end

pg_notes = PgNotes.new(pg_connection)

helpers do
  def escape_html(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  content_type :html
  headers['Content-Security-Policy'] = "default-src 'self'"
  erb :index, locals: { notes: pg_notes }
end

post '/notes' do
  text = params[:text]
  position = params[:position].to_i
  inserted_id = pg_notes.add(text, position)

  pg_note = PgNote.new(inserted_id, pg_connection)
  pg_note.json
end

patch '/notes/:id' do
  pg_note = PgNote.new(params[:id].to_i, pg_connection)
  pg_note.update(params[:text])
  pg_note.json
end

delete '/notes/:id' do
  pg_note = PgNote.new(params[:id], pg_connection)
  pg_note.delete
end

patch '/notes/:id/swap' do
  pg_note = PgNote.new(params[:id], pg_connection)
  pg_note.swap(params[:note_id])
end

get '/notes' do
  $pg_connection_pool.with do |pg_connection|
    pg_notes = PgNotes.new(pg_connection)
    pg_notes.json
  end
end

get '/sse', provides: 'text/event-stream' do # rubocop:disable Metrics/BlockLength
  cache_control :no_cache

  initial_ids = []
  last_updated = Time.now

  $pg_connection_pool.with do |pg_connection|
    pg_connection.exec('SELECT id FROM notes') do |result|
      result.each do |row|
        initial_ids << row['id']
      end
    end
  end

  stream :keep_open do |stream|
    $pg_connection_pool.with do |pg_connection| # Segmentation fault error occurs without this
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
end
