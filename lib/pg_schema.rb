# frozen_string_literal: true

class PgSchema
  attr_reader :path

  def initialize(pg_connection:, path: 'db/schema.sql')
    @path = path
    @pg_connection = pg_connection
  end

  def generate
    host = ENV.fetch('PG_HOST', nil)
    user = ENV.fetch('PG_USER', nil)
    password = ENV.fetch('PG_PASSWORD', nil)

    cmd = %(
      PGPASSWORD="#{password}" pg_dump --host #{host} --username #{user} --no-password --file #{path} #{excluded}
    )
    `#{cmd}`
  end
  alias regenerate generate

  private

  attr_reader :pg_connection

  def excluded_data_tables
    sql = <<-SQL
      SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'
        AND table_name != 'applied_migrations'
    SQL

    tables = []

    result = pg_connection.exec(sql)
    result.each do |row|
      tables << row['table_name']
    end

    tables
  end

  def excluded
    excluded_data_tables.map { |t| "--exclude-table-data=#{t}" }.join("\s")
  end
end
