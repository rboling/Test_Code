class FiltersController < ApplicationController

  def new
    @filter_form = params[:model_name].tableize + "_form"
    @filter = Filter.new(:model_name => params[:model_name])
  end

  def create
    @filter = Filter.new(params[:filter])
    puts "#{@filter}"
    puts "#{@filter.object_name}"
    puts "foofoofoo"
    if @filter.object_name == "Question"
      redirect_to "/#{params[:title]}?#{@filter.query_params}"
    else
    redirect_to @filter.to_query
    end
  end

end
