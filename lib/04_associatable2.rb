require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do

      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.class_name.constantize.table_name
      source_table = source_options.class_name.constantize.table_name

      through_class = through_options.class_name.constantize
      source_class = source_options.class_name.constantize
      # byebug
      result = DBConnection.execute(<<-SQL)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
          JOIN #{source_table}
            ON #{source_table}.#{source_options.primary_key} = #{through_table}.#{through_options.primary_key}
        WHERE
          #{through_table}.#{through_options.primary_key} = #{send(through_options.foreign_key)}
      SQL

      source_class.new(result.first)
    end
  end
end
