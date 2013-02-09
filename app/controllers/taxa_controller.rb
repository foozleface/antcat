# coding: UTF-8
class TaxaController < ApplicationController
  def new
  end

  def create
  end

  def edit
    @taxon = Taxon.find params[:id]
  end

  def update
    @taxon = Taxon.find params[:id] 
    begin
      update_taxon params.dup[:genus]
    rescue
      render :edit and return
    end
    if Rails.env.test?
      redirect_to catalog_path @taxon
    else
      render :edit and return
    end
  end

  ###################
  def update_taxon attributes
    Taxon.transaction do
      protonym_attributes = attributes.delete :protonym_attributes
      type_name_attributes = attributes.delete :type_name_attributes

      update_name_status_flags attributes
      update_protonym protonym_attributes
      update_type_name type_name_attributes
    end
  end

  def update_name_status_flags attributes
    update_name attributes.delete :name_attributes
    @taxon.attributes = attributes
    # apparently can't just assign this value to the attribute in attributes
    @taxon.headline_notes_taxt = Taxt.from_editable attributes.delete :headline_notes_taxt
    @taxon.save!
  end

  def update_name attributes
    begin
      name = Name.import genus_name: attributes[:name]
    rescue ActiveRecord::RecordInvalid
      @taxon.name.name = attributes[:name]
      @taxon.errors.add :base, "Name can't be blank"
      raise
    end
    @taxon.update_attributes name: name
  end

  def update_protonym attributes
    update_protonym_name attributes.delete :name_attributes
    update_protonym_authorship attributes.delete :authorship_attributes
    @taxon.protonym.update_attributes attributes
  end

  def update_protonym_name attributes
  end

  def update_protonym_authorship attributes
    attributes.delete :reference
    @taxon.protonym.authorship.update_attributes attributes
  end

  def update_type_name attributes
  end

end
