# frozen_string_literal: true

require 'yaml'

class Fixtures
  def initialize(file_path, pg_connection)
    @file_path = file_path
    @pg_connection = pg_connection
  end

  def to_hash
    parsed_yaml = YAML.load_file(file_path)
    parsed_yaml.transform_keys!(&:to_sym)

    parsed_yaml.each do |table, name_columns_values|
      name_columns_values.transform_keys!(&:to_sym)

      name_columns_values.each do |name, columns_values|
        columns_values.each do |column, value|
          parsed_yaml[table][name][column] = type_casted_value(value)
        end

        parsed_yaml[table][name] = OpenStruct.new(columns_values)

        sql = sql(table, columns_values.keys, columns_values.values.count)
        id = pg_connection.exec_params(sql, columns_values.values).getvalue(0, 0)
        parsed_yaml[table][name].id = id
      end
    end

    parsed_yaml
  end

  private

  attr_reader :file_path, :pg_connection

  def type_casted_value(value)
    return value unless value.is_a?(String)

    datetime = /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\Z/

    if value.match?(datetime)
      Time.parse(value)
    else
      value
    end
  end

  def sql(table, columns, value_count)
    formatted_columns = columns.join(', ')
    value_placeholders = value_count.times.map { |i| "$#{i.next}" }.join(', ')

    "INSERT INTO #{table} (#{formatted_columns}) VALUES (#{value_placeholders}) RETURNING id"
  end
end
