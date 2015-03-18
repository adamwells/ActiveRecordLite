require_relative 'db_connection'
require 'active_support/inflector'
require_relative '02_searchable'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    self_with_columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    self_with_columns.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method("#{column}") do
        @attributes[column]
      end

      define_method("#{column}=") do |value|
        @attributes ||= {}
        @attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    unless table_name == 'humen'
      @table_name = table_name
    else
      @table_name = 'humans'
    end
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    object_hashes = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    self.parse_all(object_hashes)
  end

  def self.parse_all(results)
    sql_objects = []
    results.each do |result|
      sql_objects << self.new(result)
    end
    sql_objects
  end

  def self.find(id)
    object_hash = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    self.parse_all(object_hash).first
  end

  def initialize(params = {})
    params.each do |key, value|
      unless self.class.columns.include?(key.to_sym)
        raise "unknown attribute '#{key}'"
      end
      self.send "#{key}=", value
    end
  end

  def attributes
    @attributes
  end

  def attribute_values
    @attributes.values
  end

  def insert
    sanitize = (["?"] * attribute_values.size).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{@attributes.keys.join(', ')})
      VALUES
        (#{sanitize})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_string = []
    @attributes.keys.each do |key|
      set_string << "#{key} = ?"
    end


    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_string.join(', ')}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    unless @attributes && !@attributes[:id].nil?
      insert
    else
      update
    end
  end
end
