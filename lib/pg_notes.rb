# frozen_string_literal: true

class PgNotes
  include Enumerable

  def initialize(pg_connection)
    @pg_connection = pg_connection
    @pg_note_by_result_row = proc do |pg_row|
      OpenStruct.new(id: pg_row['id'], text: pg_row['text'], position: pg_row['position'])
    end
  end

  def add(text, position)
    # pg_connection.exec_params("INSERT INTO notes (text, position) VALUES ($1, pg_sequence_last_value('notes_id_seq')) RETURNING id", [text]) do |result|
    pg_connection.exec_params('INSERT INTO notes (text, position) VALUES ($1, $2) RETURNING id',
                              [text, position]) do |result|
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

  private

  attr_reader :pg_connection, :pg_note_by_result_row
end
