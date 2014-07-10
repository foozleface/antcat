# coding: UTF-8
class TaxonMother
  # A TaxonMother is responsible for creating/saving
  # an object web of objects, starting with Taxon

  def initialize id = nil
    @id = id
  end

  def load_taxon
    @taxon = Taxon.find @id
    build_children
    @taxon
  end

  def create_taxon rank, parent
    @taxon = rank.string.titlecase.constantize.new
    @taxon.parent = parent
    build_children
    @taxon
  end

  def save_taxon taxon, params
    Taxon.transaction do
      @taxon = taxon

      update_name                 params.delete :name_attributes
      update_parent               params.delete :parent_name_attributes
      update_current_valid_taxon  params.delete :current_valid_taxon_name_attributes
      update_homonym_replaced_by  params.delete :homonym_replaced_by_name_attributes
      update_protonym             params.delete :protonym_attributes
      update_type_name            params.delete :type_name_attributes
      update_name_status_flags    params

      if @taxon.new_record?
        set_initial_review_state
        @taxon.save!
        save_change
      else
        @taxon.save!
      end
      save_taxon_children @taxon
    end
  end

  def save_change
    change = Change.new
    change.paper_trail_version = @taxon.last_version
    change.save!
  end

  def set_initial_review_state
    @taxon.review_state = :waiting
  end

  ####################################
  def update_name attributes
    attributes[:name_id] = attributes.delete :id
    gender = attributes.delete :gender
    @taxon.name.gender = gender.blank? ? nil : gender
    @taxon.attributes = attributes
  end

  def update_name_status_flags attributes
    attributes[:incertae_sedis_in] = nil unless attributes[:incertae_sedis_in].present?
    @taxon.attributes = attributes
    @taxon.headline_notes_taxt = Taxt.from_editable attributes.delete :headline_notes_taxt
    if attributes[:type_taxt]
      @taxon.type_taxt = Taxt.from_editable attributes.delete :type_taxt
    end
  end

  def update_parent attributes
    return unless attributes
    @taxon.update_parent Taxon.find_by_name_id attributes[:id]
  rescue Taxon::TaxonExists
    @taxon.errors[:base] = "This name is in use by another taxon"
    raise
  end

  def update_homonym_replaced_by attributes
    replacement_id = attributes[:id]
    replacement = replacement_id.present? ? Taxon.find_by_name_id(replacement_id) : nil
    @taxon.homonym_replaced_by = replacement
  end

  def update_current_valid_taxon attributes
    replacement_id = attributes[:id]
    replacement = replacement_id.present? ? Taxon.find_by_name_id(replacement_id) : nil
    @taxon.current_valid_taxon = replacement
  end

  def update_protonym attributes
    attributes[:name_id] = attributes.delete(:name_attributes)[:id]
    update_protonym_authorship attributes.delete :authorship_attributes
    @taxon.protonym.attributes = attributes
  end

  def update_protonym_authorship attributes
    return unless @taxon.protonym.authorship
    attributes[:reference_id] = attributes.delete(:reference_attributes)[:id]
    return if attributes[:reference_id].blank? and @taxon.protonym.authorship.reference.blank?
    if attributes[:notes_taxt]
      @taxon.protonym.authorship.notes_taxt = Taxt.from_editable attributes.delete :notes_taxt
    end
    @taxon.protonym.authorship.attributes = attributes
  end

  def update_type_name attributes
    # ugly way to handle optional, but possibly pre-built, subobject
    if @taxon.type_name && @taxon.type_name.new_record? && (!attributes or attributes[:id] == '')
      @taxon.type_name = nil
      return
    end
    attributes[:type_name_id] = attributes.delete :id
    @taxon.attributes = attributes
  end

  def build_children
    @taxon.build_name                 unless @taxon.name
    @taxon.build_protonym             unless @taxon.protonym
    @taxon.protonym.build_name        unless @taxon.protonym.name
    @taxon.protonym.build_authorship  unless @taxon.protonym.authorship
    @taxon.build_type_name            unless @taxon.type_name
  end

  private

  def save_taxon_children taxon
    return if taxon.kind_of?(Subspecies)
    taxon.children.each do |c|
      c.save!
      save_taxon_children c
    end
  end
end
