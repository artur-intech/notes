# frozen_string_literal: true

class PgUserNotes
  def initialize(user_id, pg_connection, note_by_id = proc { |id| PgNote.new(id, pg_connection) })
    @user_id = user_id
    @pg_connection = pg_connection
    @note_by_id = note_by_id
  end

  def add(text, position)
    raise ArgumentError, 'Text cannot be nil' if text.nil?
    raise ArgumentError, 'Text cannot be empty' if text.empty?
    raise ArgumentError, 'Position cannot be negative' if position.negative?

    sql = 'INSERT INTO notes (text, position, user_id) VALUES ($1, $2, $3) RETURNING id'
    pg_connection.exec_params(sql, [text, position, user_id]) do |result|
      id = result.getvalue(0, 0)
      id
    end
  end

  def fetch
    result = pg_connection.exec_params('SELECT * FROM notes WHERE user_id = $1 ORDER BY position DESC', [user_id])

    result.map do |pg_row|
      note_by_id.call(pg_row['id'])
      end
    end

    notes
  end

  def json
    fetch.map(&:json_hash).to_json
  end

  def ids
    result = pg_connection.exec('SELECT id FROM notes WHERE user_id = $1', [user_id])
    result.map { |row| row['id'] }
  end

  def updated_since?(moment)
    result = pg_connection.exec_params('SELECT COUNT(*) FROM notes WHERE user_id = $1 AND updated_at >= $2',
                                       [user_id, moment])
    !result.getvalue(0, 0).to_i.zero?
  end

  private

  attr_reader :pg_connection, :note_by_id, :user_id
end
