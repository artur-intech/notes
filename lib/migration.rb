# frozen_string_literal: true

class Migration
  class Fake
    def initialize(path: 'test', pending: true)
      @path = path
      @pending = pending
    end

    def apply
      @applied = true
    end

    def pending?
      @pending
    end

    def applied?
      @applied
    end

    def inspect
      path
    end

    def <=>(other)
      path <=> other.path
    end

    attr_reader :path
  end

  class InvalidMigrationError < StandardError; end

  attr_reader :path

  def initialize(path:, pg_connection:)
    @path = path
    @pg_connection = pg_connection
  end

  def apply
    raise InvalidMigrationError, 'Empty file' if file_empty?

    # TODO: Test transaction
    pg_connection.transaction do
      begin
        pg_connection.exec(sql)
      rescue PG::SyntaxError
        raise InvalidMigrationError
      end

      track
    end
  end

  def ==(other)
    self.class == other.class && path == other.path
  end

  def inspect
    id
  end

  def pending?
    raise InvalidMigrationError, 'Invalid filename' if id_invalid?

    pg_connection.exec_params('SELECT COUNT(*) FROM applied_migrations WHERE id = $1', [id]).getvalue(0, 0).to_i.zero?
  end

  def <=>(other)
    path <=> other.path
  end

  def to_s
    path
  end

  private

  attr_reader :pg_connection

  def track
    pg_connection.exec_params('INSERT INTO applied_migrations VALUES ($1)', [id])
  end

  def sql
    File.read(path)
  end

  def id
    Pathname(path).basename('.*').to_s
  end

  def id_invalid?
    id.split('_').size < 2
  end

  def file_empty?
    File.empty?(path)
  end
end
