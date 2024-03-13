# frozen_string_literal: true

class PgUserNotes
  include Enumerable

  def initialize(user_id, pg_connection, pg_note_by_result_row = default_pg_note_by_result_row)
    @user_id = user_id
    @pg_connection = pg_connection
    @pg_note_by_result_row = pg_note_by_result_row
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
        yield pg_note_by_result_row.call(pg_row)
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

  attr_reader :pg_connection, :pg_note_by_result_row, :user_id

  def default_pg_note_by_result_row
    proc { |pg_row| PgNote.new(pg_row['id'], pg_connection) }
  end
end
