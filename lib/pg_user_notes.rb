# frozen_string_literal: true

class PgUserNotes
  def initialize(user_id, pg_connection, note_by_id = proc { |id| PgNote.new(id, pg_connection) })
    @user_id = user_id
    @pg_connection = pg_connection
    @note_by_id = note_by_id
  end

  def add(text, position)
    sql = 'INSERT INTO notes (text, position, user_id) VALUES ($1, $2, $3) RETURNING id'
    pg_connection.exec_params(sql, [text, position, user_id]) do |result|
      id = result.getvalue(0, 0)
      id
    end
  end

  def fetch
    notes = []

    pg_connection.exec_params('SELECT * FROM notes WHERE user_id = $1 ORDER BY position DESC', [user_id]) do |result|
      result.each do |pg_row|
        notes << note_by_id.call(pg_row['id'])
      end
    end

    notes
  end

  def json
    fetch.map(&:json_hash).to_json
  end

  private

  attr_reader :pg_connection, :note_by_id, :user_id
end
