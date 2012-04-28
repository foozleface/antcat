# coding: UTF-8
class ReferenceFieldsController < ApplicationController

  def show
    params[:search_selector] ||= 'Search for author(s)'

    if params[:id].present?
      @references = Reference.perform_search id: params[:id]
      @current_reference = @references.first
    end

    if params[:q].present?
      params[:q].strip!
      params[:is_author_search] = params[:search_selector] == 'Search for author(s)'
      @references = Reference.do_search params
    end

    render partial: 'show', locals: {current_reference: @current_reference, references: @references}
  end

end
