# coding: UTF-8
class Catalog::IndexController < CatalogController

  def show
    super

    @current_path = index_catalog_path
    @subfamilies = ::Subfamily.ordered_by_name

    @url_parameters = {:q => params[:q], :search_type => params[:search_type], :hide_tribes => params[:hide_tribes]}

    setup_formicidae and return if @search_results.blank? && params[:id].blank?

    if params[:id] =~ /^no_/
      @taxon = params[:id]
    else
      @taxon = Taxon.find params[:id]
      @taxonomic_history = @taxon.taxonomic_history
    end

    case @taxon
    when 'no_subfamily', Subfamily
      @selected_subfamily = @taxon
      if @selected_subfamily == 'no_subfamily'
        setup_formicidae
        @genera = Genus.without_subfamily
      elsif params[:hide_tribes]
        @genera = @selected_subfamily.genera
      else
        @tribes = @selected_subfamily.tribes
      end

    when 'no_tribe', Tribe
      @selected_tribe = @taxon
      if params[:hide_tribes] && @selected_tribe == 'no_tribe'
        @taxon = ::Subfamily.find params[:subfamily]
        @selected_subfamily = @taxon
        @genera = @selected_subfamily.genera
      elsif params[:hide_tribes]
        @taxon = @selected_tribe.subfamily
        @selected_subfamily = @taxon
        @genera = @selected_subfamily.genera
      elsif @selected_tribe == 'no_tribe'
        @selected_subfamily = ::Subfamily.find params[:subfamily]
        @tribes = @selected_subfamily.tribes
        @genera = @selected_subfamily.genera.without_tribe
      else
        @tribes = @selected_tribe.siblings
        @genera = @selected_tribe.genera
        @selected_subfamily = @selected_tribe.subfamily
      end

    when Genus
      @selected_genus = @taxon
      select_subfamily_and_tribes
      select_genera
      @species = @selected_genus.species

    when Species
      @selected_species = @taxon
      @selected_genus = @selected_species.genus
      @species = @selected_species.siblings
      select_subfamily_and_tribes
      select_genera
    end

    @url_parameters[:subfamily] = @selected_subfamily

    @taxon_header_name ||= @taxon.full_label if @taxon.kind_of? Taxon
    @taxon_statistics ||= @taxon.statistics if @taxon.kind_of? Taxon
  end

  def select_subfamily_and_tribes
    @selected_subfamily = @selected_genus.subfamily || 'no_subfamily'
    unless params[:hide_tribes] || @selected_subfamily == 'no_subfamily'
      @selected_tribe = @selected_genus.tribe || 'no_tribe'
      @tribes = @selected_subfamily.tribes
    end
  end

  def select_genera
    if @selected_subfamily == 'no_subfamily'
      @genera = Genus.without_subfamily
    elsif params[:hide_tribes]
      @genera = @selected_subfamily.genera
    else
      @genera = @selected_genus.siblings
    end
  end

  def setup_formicidae
    @taxon_header_name = 'Formicidae'
    @taxon_statistics = Taxon.statistics
  end

  def select_subfamily_and_tribes
    @selected_subfamily = @selected_genus.subfamily || 'no_subfamily'
    unless params[:hide_tribes] || @selected_subfamily == 'no_subfamily'
      @selected_tribe = @selected_genus.tribe || 'no_tribe'
      @tribes = @selected_subfamily.tribes
    end
  end

  def select_genera
    if @selected_subfamily == 'no_subfamily'
      @genera = Genus.without_subfamily
    elsif params[:hide_tribes]
      @genera = @selected_subfamily.genera
    else
      @genera = @selected_genus.siblings
    end
  end

end

