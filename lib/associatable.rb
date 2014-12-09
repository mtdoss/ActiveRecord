require_relative 'searchable'
require 'active_support/inflector'

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
    self.class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = "#{name}_id".to_sym
    @class_name =  "#{name.capitalize}"
    @primary_key = :id

    @foreign_key = options[:foreign_key] if options[:foreign_key]
    @class_name = options[:class_name] if options[:class_name]
    @primary_key = options[:primary_key] if options[:primary_key]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = (self_class_name.downcase + "_id").to_sym
    @class_name = name.to_s.singularize.camelcase
    @primary_key = :id

    @foreign_key = options[:foreign_key] if options[:foreign_key]
    @class_name = options[:class_name] if options[:class_name]
    @primary_key = options[:primary_key] if options[:primary_key]
  end
end

module Associatable
  # def belongs_to(name, options = {})
  #   options = BelongsToOptions.new(name, options)

  #   define_method(name) do
  #     fkey = self.send(options.foreign_key)
  #     options.model_class.where(options.primary_key => fkey).first
  #   end
  # end
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      fkey = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => fkey).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      fkey = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => fkey)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
