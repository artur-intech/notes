# frozen_string_literal: true

class PgUserNotes
  include Enumerable

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

  def each
    pg_connection.exec_params('SELECT * FROM notes WHERE user_id = $1 ORDER BY position DESC', [user_id]) do |result|
      result.each do |pg_row|
        yield note_by_id.call(pg_row['id'])
      end
    end
  end

  def json
    map(&:json_hash).to_json
  end

  def updated_at
    result = []

    pg_connection.exec('SELECT id, updated_at FROM notes') do |pg_result|
      pg_result.each do |row|
        result << { id: row['id'], updated_at: row['updated_at'] }
      end
    end

    result
  end

  private

  attr_reader :pg_connection, :note_by_id, :user_id
end
