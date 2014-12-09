require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    cols = DBConnection.execute2(<<-SQL)
    SELECT
    *
    FROM
    #{table_name}
    SQL

    cols[0].each_with_index { |string, i| cols[0][i] = string.to_sym }
    cols[0]
  end

  def self.finalize!
    self.columns.each do |col|
      define_method "#{col}" do
        var_name = "#{col}"
        attributes[var_name.to_sym]
      end

      define_method "#{col}=" do |val|
        var_name = "#{col}"
        attributes[var_name.to_sym] = val
      end
    end
  end


  def self.table_name=(table_name)
    @table_name = self.class.to_s.tableize if table_name.nil?
    @table_name = table_name if table_name
  end

  def self.table_name
    @table_name || self.name.tableize
  end

  def self.all
    parse_all(DBConnection.execute(<<-SQL
      SELECT
      *
      FROM
      "#{table_name}"
      SQL
      )
    )
  end

  def self.parse_all(results)
    array_of_objects = []
    results.each do |params|
      array_of_objects << self.new(params)
    end
    array_of_objects
  end

  def self.find(id)
    arr = DBConnection.execute(
      "SELECT
      *
      FROM
      #{table_name}
      WHERE
      id = ?", id)
    params = arr[0]
    self.new(params)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr_name| self.send(attr_name) }
  end

  def insert
    # col_names = []
    # question_marks = []
    # self.class.columns.each do |val|
    #   col_names << (val.to_s) << ", "
    # end
    # num_question_marks = attributes.keys.count
    # num_question_marks.times { question_marks << "?, " }
    # question_marks << "?"

    col_names = self.class.columns.map(&:to_s).join(", ")
    question_marks = (["?"] * self.class.columns.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{ self.class.table_name } (#{ col_names })
      VALUES
      (#{ question_marks })

      SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.map{ |attr_name| "#{attr_name} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    UPDATE
      #{ self.class.table_name }
      SET
      #{ col_names }
      WHERE
      id = ?
      SQL
  end

  def save
    if id.nil?
      insert self
    else
      update self
    end
  end
end
