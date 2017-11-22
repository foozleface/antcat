module Autocomplete
  class AutocompleteTaxa
    include Service

    def initialize search_query, rank: nil
      @search_query = search_query
      @rank = rank
    end

    def call
      (exact_id_match || search_results).map do |taxon|
        {
          id: taxon.id,
          name: taxon.name_cache,
          name_html: taxon.name_html_cache,
          name_with_fossil: taxon.name_with_fossil,
          author_citation: taxon.author_citation
        }
      end
    end

    private
      attr_reader :search_query, :rank

      def search_results
        taxa = Taxon.where("name_cache LIKE ?", "%#{search_query}%")
        taxa = taxa.where(type: rank) if rank.present?
        taxa.includes(:name, protonym: { authorship: :reference }).take(10)
      end

      def exact_id_match
        return unless search_query =~ /^\d{6} ?$/

        match = Taxon.find_by id: search_query
        [match] if match
      end
  end
end
