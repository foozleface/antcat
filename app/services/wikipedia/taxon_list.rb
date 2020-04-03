# frozen_string_literal: true

# Class for generating wiki-formatted lists of tribes, genera and species.

module Wikipedia
  class TaxonList
    include Service

    attr_private_initialize :taxon

    def call
      case taxon
      when Family, Tribe then genera
      when Subfamily     then genera << divider << tribes
      when Genus         then species
      else               "cannot generate children list for this taxon"
      end
    end

    private

      attr_reader :children_rank, :children

      def tribes
        generate :tribes
      end

      def genera
        generate :genera
      end

      def species
        generate :species
      end

      def generate rank
        @children_rank = rank
        @children = @taxon.public_send(@children_rank).valid.order_by_name

        output = []
        output << taxobox_extras
        output << "\n"
        output << list_header

        children.each { |child| output << format_child(child) }

        output << list_footer
        output.join
      end

      def divider
        "\n-------------------\n\n"
      end

      # For https://en.wikipedia.org/wiki/Template:Taxobox
      def taxobox_extras
        string = []
        string << "|diversity_link = ##{children_rank.to_s.capitalize}"
        string << "|diversity = #{children.count} #{children_rank}"
        string << "|diversity_ref = #{Wikipedia::CiteTemplate[taxon]}\n"
        string.join("\n")
      end

      # "==Species== ..."
      def list_header
        "==#{children_rank.to_s.capitalize}==\n{{div col||25em}}\n"
      end

      def list_footer
        "{{div col end}}\n"
      end

      # "* †''[[Atta mexicana]]'' <small>Author, 2005</small>\n"
      def format_child child
        string = []
        string << "* "
        string << taxon_name(child)
        string << " "
        string << author_citation(child)
        string << "\n"
        string.join
      end

      def taxon_name child
        name = child.name_cache.dup
        name = "[[#{name}]]" if wikilink_child? child
        name = "''#{name}''" if Rank.italic?(child.rank)

        "#{dagger if child.fossil}#{name}"
      end

      def dagger
        "†"
      end

      def wikilink_child? child
        # Don't link species in fossil genera per WP:PALEO.
        return false if taxon.fossil? && child.is_a?(Species)

        # Don't link subspecies (we should not have article on these).
        return false if child.is_a? Subspecies

        true
      end

      def author_citation child
        "<small>#{child.author_citation}</small>"
      end
  end
end
