require 'active_support/inflector'

class Filter

  include ActiveModel::Conversion
  extend ActiveModel::Naming

  # Add an attr accessor for any attribute you want to use in a form
  attr_accessor :model_name, :title, :object, :notebooks, :notes, :created_at, :offering_id, :course_id, :name, :user_ids, :questions, :offerings, :start_date, :end_date

  def initialize(options={})
    options ||= {}
    options.each_pair do |key,value|
      key = "#{key}="
      self.send(key,value) if self.respond_to? key
    end
    newObject if model_name
  end
  
  def newObject
    self.send("object=", Kernel.const_get(model_name).new)
  end

  def persisted?
    false
  end

  def title
    if object_name.pluralize == 'StudySessions'
      "Filter Your StudyHalls"
    else
    "Filter Your #{object_name.pluralize}"
    end
  end
  
  def object_name
    object.class.to_s
  end
  
  def attributes
    attributes = {}
    self.instance_variables.each {|var| attributes[var.to_s.delete("@")] = self.instance_variable_get(var) unless var == :@model_name || var == :@object }
    attributes
  end

  def query_params
    attrs = attributes
    params_for_query = {:filter => {}}
    not_object_attrs = {}
    case object_name
    when "Note" || "Notebook"
      params_for_query[:filter][:note] = {} if attrs["notes"]
      params_for_query[:filter][:notebook] = {} if attrs["notebooks"]
      attrs.each_pair do |k, v|
        unless v.empty?
          params_for_query[:filter][:note][k] = v if attribute_of?(k, Note) && attrs["notes"]
          params_for_query[:filter][:notebook][k] = v if attribute_of?(k, Notebook) && attrs["notebooks"]
          params_for_query[:filter][k] = v if !attribute_of?(k, Note) && !attribute_of?(k, Notebook)
        end
      end
      #params_for_query[:filter][:notebooks] = notebooks
      #params_for_query[:filter][:notes] = notes
    when "StudySession"
      params_for_query[:filter][:study_session] = {}
      attrs.each_pair do |k, v|
        if attribute_of?(k, StudySession)
          params_for_query[:filter][:study_session][k] = v unless v.empty?
        else
          params_for_query[:filter][k] = v 
        end
      end
    when "Question"
      params_for_query[:filter][:question] = {}
      attrs.each_pair do |k, v|
        if attribute_of?(k, Question)
          params_for_query[:filter][:question][k] = v unless v.empty?
        else
          params_for_query[:filter][k] = v 
        end
      end

    when "Offering"
      params_for_query[:filter][:offering] = {}
      attrs.each_pair do |k, v|
        if attribute_of?(k, Offering)
          params_for_query[:filter][:offering][k] = v unless v.empty?
        else
          params_for_query[:filter][k] = v 
        end
      end
    end      
    params_for_query.to_query
  end

  def attribute_of?(attribute, model)
    model.column_names.include?(attribute.to_s)
  end

  def to_query   
    "/#{model_name.tableize}?#{query_params}"
  end
end
