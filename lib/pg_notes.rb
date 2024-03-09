# frozen_string_literal: true

class PgNotes
  include Enumerable

  def initialize(pg_connection)
    @pg_connection = pg_connection
    @pg_note_by_result_row = proc do |pg_row|
      PgNote.new(pg_row['id'], pg_connection)
    end
  end

  def add(text, position, user_id)
    pg_connection.exec_params('INSERT INTO notes (text, position, user_id) VALUES ($1, $2, $3) RETURNING id',
                              [text, position, user_id]) do |result|
      id = result.getvalue(0, 0)
      id
    end
  end

  def each
    pg_connection.exec('SELECT * FROM notes ORDER BY position DESC') do |result|
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

  attr_reader :pg_connection, :pg_note_by_result_row
end
