# frozen_string_literal: true

# This is a dumping ground for temporary code used for cleaning up records.
# No tests is a feature, not a bug, since the only reason we're OK
# with this is because all of it will 100% be removed at some point :)

# :nocov:
module Taxa
  class CleanupTaxon < SimpleDelegator
    ORIGINS = ['hol', 'checked hol', 'migration', 'checked migration']

    # TODO: Experimental.
    def now_taxon
      return self unless current_taxon
      current_taxon.now_taxon
    end

    # TODO: Experimental. Used for expanding type taxa (see `TypeNameDecorator`).
    def most_recent_before_now_taxon
      taxa = []
      iteratred_current_taxon = current_taxon

      while iteratred_current_taxon
        taxa << iteratred_current_taxon
        iteratred_current_taxon = iteratred_current_taxon.current_taxon
      end

      taxa.second_to_last || self
    end

    # TODO: Remove ASAP. Also `#synonyms_history_items_containing_taxon`
    # and `#synonyms_history_items_containing_taxons_protonyms_taxa_except_self`.
    def obsolete_combination_that_is_shady?
      DatabaseScripts::ObsoleteCombinationsWithProtonymsNotMatchingItsCurrentTaxonsProtonym.record_in_results?(self) ||
        DatabaseScripts::ObsoleteCombinationsWithVeryDifferentEpithets.record_in_results?(self)
    end

    # TODO: Remove ASAP.
    def synonyms_history_items_containing_taxon taxon
      history_items.find_by("taxt LIKE ?", "Senior synonym of%#{taxon.id}%")
    end

    # TODO: Remove ASAP.
    def synonyms_history_items_containing_taxons_protonyms_taxa_except_self taxon
      taxon.protonym.taxa.where.not(id: taxon.id).find_each do |protonym_taxon|
        item = history_items.find_by("taxt LIKE ?", "Senior synonym of%#{protonym_taxon.id}%")
        return item if item
      end
      nil
    end

    def combination_in_according_to_history_items
      @_combination_in_according_to_history_items ||= begin
        ids = combination_in_history_items.map(&:ids_from_tax_tags).flatten
        Taxon.where(id: ids)
      end
    end

    private

      # "Combination in {tax 123}".
      # NOTE: Can be removed once we have normalized all 'combination in's.
      def combination_in_history_items
        history_items.where('taxt LIKE ?', "Combination in%")
      end
  end
end
# :nocov:
