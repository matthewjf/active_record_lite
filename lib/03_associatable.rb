require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    "#{model_class}s".to_s.downcase
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default_options = { foreign_key: "#{name}_id".underscore.to_sym,
                        primary_key: :id,
                        class_name: name.to_s.camelcase.singularize }
    opts = default_options.merge(options)

    @foreign_key = opts[:foreign_key]
    @primary_key = opts[:primary_key]
    @class_name = opts[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default_options = { foreign_key: "#{self_class_name}_id".downcase.to_sym,
                        primary_key: :id,
                        class_name: name.to_s.camelcase.singularize }
    opts = default_options.merge(options)

    @foreign_key = opts[:foreign_key]
    @primary_key = opts[:primary_key]
    @class_name = opts[:class_name]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    options = self.assoc_options[name]
    define_method(name) do
      if send(options.foreign_key)
        result = DBConnection.execute(<<-SQL).first
          SELECT
            *
          FROM
            #{options.class_name.constantize.table_name}
          WHERE
            id = #{send(options.foreign_key)}
        SQL

        options.class_name.constantize.new(result)
      else
        nil
      end
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) do
      if send(options.primary_key)
        result = DBConnection.execute(<<-SQL)
          SELECT
            *
          FROM
            #{options.class_name.constantize.table_name}
          WHERE
            #{options.foreign_key} = #{send(options.primary_key)}
        SQL

        options.class_name.constantize.parse_all(result)
      else
        []
      end
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
