require 'active_support/inflector'
require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'



class SQLObject < MassObject
  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    return nil if results.empty?
    parse_all(results).first
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
    instance_vars = self.class.attributes
    instance_var_vals = instance_vars.map { |var| self.send(var) }

    DBConnection.execute(<<-SQL)
    INSERT INTO
      #{self.class.table_name}
      (#{instance_vars.join(", ")})
    VALUES
      (#{instance_var_vals.join(", ")})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    instance_vars = self.class.attributes
    instance_var_vals = instance_vars.map { |var| self.send(var) }

    set_line = []
    instance_vars.each_index do |i|
      set_line << "#{instance_vars[i]} = #{instance_var_vals[i]}"
    end

    p set_line.join(", ")

    DBConnection.execute(<<-SQL, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line.join(", ")}
    WHERE
      id = ?
    SQL
  end

  # call either create or update depending if id is nil.
  def save
    if id.nil?
      create
    else
      update
    end
  end

  # helper method to return values of the attributes.
  def attribute_values
  end
end

# SQLObject.set_table_name("cats")
# p SQLObject.table_name
# SQLObject.all