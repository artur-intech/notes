# frozen_string_literal: true

require 'pg'
require 'sinatra'
require 'rack/unreloader'
require 'ostruct'
require_relative 'lib/pg_note'
require_relative 'lib/pg_notes'

pg_connection = PG::Connection.new(host: ENV['PG_HOST'],
                                   user: ENV['PG_USER'],
                                   password: ENV['PG_PASSWORD'])
pg_connection.type_map_for_results = PG::BasicTypeMapForResults.new(pg_connection)

set :default_content_type, :json

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
