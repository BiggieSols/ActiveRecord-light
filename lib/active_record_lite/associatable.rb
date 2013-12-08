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
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:other_class_name] || name.to_s.singularize.camelize
    @foreign_key      = params[:foreign_key]      || self_class.foreign_key
    @primary_key      = params[:primary_key]      || :id
  end

  def type
    :has_many
  end
end


module Associatable
  def assoc_params
    @association_params ||= {}
    @association_params
  end

  def belongs_to(name, params = {})
    asn_params = BelongsToAssocParams.new(name, params)
    assoc_params[name] = asn_params

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(asn_params.foreign_key))
        SELECT
          *
        FROM
          #{asn_params.other_table}
        WHERE
          #{asn_params.other_table}.#{asn_params.primary_key} = ?
      SQL
      asn_params.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    asn_params = HasManyAssocParams.new(name, params, self.class.to_s)
    assoc_params[name] = asn_params

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(asn_params.primary_key))
        SELECT
          *
        FROM
          #{asn_params.other_table}
        WHERE
          #{asn_params.other_table}.#{asn_params.foreign_key} = ?
      SQL
    asn_params.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)


    define_method(name) do
      assoc_1 = self.class.assoc_params[assoc1]
      assoc_2 = assoc_1.other_class.assoc_params[assoc2]

      results = DBConnection.execute(<<-SQL, self.send(assoc_1.foreign_key))
        SELECT
          #{assoc_2.other_table}.*
        FROM
          #{assoc_1.other_table}
        JOIN
          #{assoc_2.other_table}
        ON
          #{assoc_2.other_table}.#{assoc_2.primary_key} =
          #{assoc_1.other_table}.#{assoc_2.primary_key}
        WHERE
          #{assoc_1.other_table}.#{assoc_1.primary_key} = ?
      SQL
      assoc_2.other_class.parse_all(results).first
    end
  end
end
