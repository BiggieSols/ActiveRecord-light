require 'debugger'
require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'


class AssocParams
  attr_accessor :other_class_name, :primary_key, :foreign_key

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params = {})
    @other_class_name = params[:other_class_name] || name.to_s.camelize
    @foreign_key      = params[:foreign_key]      || "#{name.to_s}_id"
    @primary_key      = params[:primary_key]      || :id
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:other_class_name] || name.to_s.singularize.camelize
    @foreign_key      = params[:foreign_key]      || self_class.foreign_key
    @primary_key      = params[:primary_key]      || :id

    puts "other class is #{@other_class_name}"
    puts "foreign  key is #{@foreign_key}"
    puts "primary key is #{@primary_key}"
    puts "other table is #{other_table}"
  end

  def type
  end
end

# dog --> owner


module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    assoc_params = BelongsToAssocParams.new(name, params)

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(assoc_params.foreign_key))
        SELECT
          *
        FROM
          #{assoc_params.other_table}
        WHERE
          #{assoc_params.other_table}.#{assoc_params.primary_key} = ?
      SQL
      assoc_params.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    assoc_params = HasManyAssocParams.new(name, params, self.class.to_s)

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(assoc_params.primary_key))
        SELECT
          *
        FROM
          #{assoc_params.other_table}
        WHERE
          #{assoc_params.other_table}.#{assoc_params.foreign_key} = ?
      SQL

    assoc_params.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
  end
end

# b = BelongsToAssocParams.new("sql_object")

# b.instance_variables.each do |var|
#   puts b.send(var)
# end
#

# p b.other_class_name
# p b.foreign_key
# p b.primary_key
# p b.other_table