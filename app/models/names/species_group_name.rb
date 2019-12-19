class SpeciesGroupName < Name
  include Formatters::ItalicsHelper

  def name_html
    italicize name
  end

  def epithet_html
    italicize epithet
  end

  def genus_epithet
    name_parts[0]
  end

  def species_epithet
    name_parts[1]
  end

  def dagger_html
    italicize super
  end

  private

    def change name_string
      existing_names = Name.where.not(id: id).where(name: name_string)
      raise Taxon::TaxonExists, existing_names if existing_names.any? { |name| !name.what_links_here.empty? }
      self.name = name_string
    end
end
