module Tooltips
  class HistoriesController < ApplicationController
    def show
      @comparer = Tooltip.revision_comparer_for params[:tooltip_id],
        params[:selected_id], params[:diff_with_id]
      @revision_presenter = RevisionPresenter.new(comparer: @comparer, hide_formatted: true)
    end
  end
end
