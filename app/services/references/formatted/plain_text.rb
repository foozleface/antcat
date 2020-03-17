# Formats the reference as plaintext (with the exception of <i> tags).

module References
  module Formatted
    class PlainText
      include ActionView::Helpers::SanitizeHelper
      include Service

      def initialize reference
        @reference = reference
      end

      def call
        string = sanitize(reference.author_names_string_with_suffix)
        string << ' '
        string << sanitize(reference.citation_year) << '. '
        string << Unitalicize[reference.decorate.format_title] << ' '
        string << AddPeriodIfNecessary[format_plain_text_citation]
        string
      end

      private

        attr_reader :reference

        def format_plain_text_citation
          case reference
          when ::NestedReference
            sanitize "#{reference.pagination} #{References::Formatted::PlainText[reference.nesting_reference]}"
          else
            # `format_italics` + `Unitalicize` is to get rid of "*"-style italics.
            Unitalicize[format_italics(sanitize(format_citation))]
          end
        end

        def format_citation
          case reference
          when ::ArticleReference
            "#{reference.journal.name} #{reference.series_volume_issue}:#{reference.pagination}"
          when ::BookReference
            "#{reference.publisher.display_name}, #{reference.pagination}"
          when ::MissingReference, ::UnknownReference
            reference.citation
          else
            raise
          end
        end

        def format_italics string
          References::FormatItalics[string]
        end
    end
  end
end
