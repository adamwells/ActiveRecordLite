require_relative '02_searchable'
require 'active_support/inflector'

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
    if @name == 'human'
      'humans'
    else
      @name.tableize
    end
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @options = options
    @options[:foreign_key] ||= "#{name}_id".to_sym
    @options[:primary_key] ||= :id
    @options[:class_name] ||= name.to_s.camelcase
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    def table_name
      problem_names = ["Human"]
      unless problem_names.include?(@options[:class_name])
        return @options[:class_name].underscore.pluralize
      else
        case @options[:class_name]
        when 'Human'
          return 'humans'
        end
      end
    end

    def model_class
      @options[:class_name].constantize
    end

    def foreign_key
      @options[:foreign_key]
    end

    def primary_key
      @options[:primary_key]
    end

    def class_name
      @options[:class_name]
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @options = options
    @options[:foreign_key] ||= "#{self_class_name.to_s.underscore}_id".to_sym
    @options[:primary_key] ||= :id
    @options[:class_name] ||= name.to_s.camelcase.singularize
    @options.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    def table_name
      problem_names = ["human"]
      unless problem_names.include?(@options[:class_name])
        return @options[:class_name].underscore.pluralize
      else
        case @options[:class_name]
        when 'Human'
          return 'humans'
        end
      end
    end

    def model_class
      @options[:class_name].constantize
    end

    def foreign_key
      @options[:foreign_key]
    end

    def primary_key
      @options[:primary_key]
    end

    def class_name
      @options[:class_name]
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      return options.model_class.where({options.primary_key => self.send(options.foreign_key)}).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      return options.model_class.where({options.foreign_key => self.send(options.primary_key)})
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
