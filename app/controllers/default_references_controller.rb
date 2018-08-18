# TODO namespace under `References`.

class DefaultReferencesController < ApplicationController
  before_action :ensure_can_edit_catalog
  before_action :set_reference, only: :update

  def update
    DefaultReference.set session, @reference

    if request.xhr?
      head :ok
    else
      redirect_back fallback_location: references_path, notice: <<-MSG.squish
          #{@reference.keey} was successfully set as the default reference.
      MSG
    end
  end

  private

    def set_reference
      @reference = Reference.find(params[:id])
    end
end
