# frozen_string_literal: true

module References
  class AutocompletesController < ApplicationController
    def show
      render json: serialized_references
    end

    private

      def serialized_references
        references.map do |reference|
          Autocomplete::ReferenceSerializer.new(reference, fulltext_params).as_json
        end
      end

      def references
        Autocomplete::ReferencesQuery[search_query, fulltext_params]
      end

      def search_query
        params[:reference_q]
      end

      def fulltext_params
        @_fulltext_params ||= ::References::Search::ExtractKeywords[search_query]
      end
  end
end
