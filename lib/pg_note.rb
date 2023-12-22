# frozen_string_literal: true

class PgNote
  attr_reader :id

  def initialize(id, pg_connection)
    @id = id
    @pg_connection = pg_connection
  end

  def text
    pg_connection.exec_params('SELECT text FROM notes WHERE id = $1', [id]).getvalue(0, 0)
  end

  def update(text)
    pg_connection.exec_params('UPDATE notes SET text = $2 WHERE id = $1', [id, text])
  end

  def delete
    pg_connection.exec_params('DELETE FROM notes WHERE id = $1', [id])
  end

  def position
    pg_connection.exec_params('SELECT position FROM notes WHERE id = $1', [id]).getvalue(0, 0)
  end

  def swap(target_id)
    src_position = position
    target_position = self.class.new(target_id, pg_connection).position
    pg_connection.exec_params('UPDATE notes SET position = $1 WHERE id = $2', [target_position, id])
    pg_connection.exec_params('UPDATE notes SET position = $1 WHERE id = $2', [src_position, target_id])
  end

  private

  attr_reader :pg_connection
end
