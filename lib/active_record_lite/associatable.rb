require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader(
    :foreign_key,
    :other_class_name,
    :primary_key,
  )

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
    @other_class_name = params[:class_name] || name.to_s.camelcase
    @primary_key = params[:primary_key] || :id
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @foreign_key = (params[:foreign_key] ||
      "#{self_class.name.underscore}_id".to_sym)
    @other_class_name = (params[:class_name] ||
      name.to_s.singularize.camelcase)
    @primary_key = params[:primary_key] || :id
  end

  def type
    :has_many
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.foreign_key))
        SELECT *
          FROM #{aps.other_table}
         WHERE #{aps.other_table}.#{aps.primary_key} = ?
      SQL

      aps.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self)
    assoc_params[name] = aps

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.primary_key))
        SELECT *
          FROM #{aps.other_table}
         WHERE #{aps.other_table}.#{aps.foreign_key} = ?
      SQL

      aps.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]

      pk1 = self.send(params1.foreign_key)
      results = DBConnection.execute(<<-SQL, pk1)
          SELECT #{params2.other_table}.*
          FROM #{params1.other_table}
          JOIN #{params2.other_table}
            ON #{params1.other_table}.#{params2.foreign_key}
                 = #{params2.other_table}.#{params2.primary_key}
         WHERE #{params1.other_table}.#{params1.primary_key}
                 = ?
      SQL

      params2.other_class.parse_all(results).first
    end
  end
end
