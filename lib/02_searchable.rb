require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    conditions = []
    params.keys.each do |key|
      conditions << "#{key} = ?"
    end

    hash_values = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{conditions.join(' AND ')}
    SQL

    self.parse_all(hash_values)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
