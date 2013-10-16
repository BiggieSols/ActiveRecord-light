require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  # sets the table_name
  def self.set_table_name(table_name)
  end

  # gets the table_name
  def self.table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
  end

  # call either create or update depending if id is nil.
  def save
  end

  # helper method to return values of the attributes.
  def attribute_values
  end
end
