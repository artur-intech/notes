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
      path.to_s
    end

    def <=>(other)
      path <=> other.path
    end

    attr_reader :path
  end

  class EmptyMigrationError < StandardError; end
  class InvalidMigrationError < StandardError; end

  attr_reader :path

  def initialize(path:, pg_connection:)
    @path = path
    @pg_connection = pg_connection
  end

  def apply
    raise EmptyMigrationError if File.empty?(path)

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
    pg_connection.exec_params('SELECT COUNT(*) FROM applied_migrations WHERE id = $1', [id]).getvalue(0, 0).zero?
  end

  def <=>(other)
    path <=> other.path
  end

  def to_s
    id
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
end
