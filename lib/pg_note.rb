# frozen_string_literal: true

class PgNote
  attr_reader :pg_connection

  def initialize(id, pg_connection, user_by_id = default_user_by_id)
    @id = id
    @pg_connection = pg_connection
    @user_by_id = user_by_id
  end

  def id
    @id.to_i
  end

  def text
    pg_connection.exec_params('SELECT text FROM notes WHERE id = $1', [id]).getvalue(0, 0)
  end

  def update(text)
    pg_connection.exec_params('UPDATE notes SET text = $2, updated_at = NOW() WHERE id = $1', [id, text])
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
    pg_connection.exec_params('UPDATE notes SET position = $1, updated_at = NOW() WHERE id = $2', [target_position, id])
    pg_connection.exec_params('UPDATE notes SET position = $1, updated_at = NOW() WHERE id = $2',
                              [src_position, target_id])
  end

  def json_hash
    { id:, text:, position: }
  end

  def json
    json_hash.to_json
  end

  def user
    user_by_id.call(user_id)
  end

  private

  attr_reader :user_by_id

  def user_id
    pg_connection.exec_params('SELECT user_id FROM notes WHERE id = $1', [id]).getvalue(0, 0)
  end

  def default_user_by_id
    proc { |id| PgUser.new(id, pg_connection) }
  end
end
