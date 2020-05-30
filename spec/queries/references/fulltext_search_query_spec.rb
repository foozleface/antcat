# frozen_string_literal: true

require 'rails_helper'

describe References::FulltextSearchQuery, :search do
  describe "#call" do
    describe 'searching with keywords' do
      describe 'keyword: `title`' do
        let!(:pescatore_reference) { create :any_reference, title: 'Pizza Pescatore' }
        let!(:capricciosa_reference) { create :any_reference, title: 'Pizza Capricciosa' }

        before do
          Sunspot.commit
        end

        specify do
          expect(described_class[title: 'Pescatore']).to eq [pescatore_reference]
          expect(described_class[title: 'Capricciosa']).to eq [capricciosa_reference]
          expect(described_class[title: 'pizza']).to match_array [pescatore_reference, capricciosa_reference]
        end
      end

      describe 'keyword: `author`' do
        let!(:bolton_reference) { create :any_reference, author_string: 'Bolton' }
        let!(:fisher_reference) { create :any_reference, author_string: 'Fisher' }

        before do
          Sunspot.commit
        end

        specify do
          expect(described_class[author: 'Bolton']).to eq [bolton_reference]
          expect(described_class[author: 'Fisher']).to eq [fisher_reference]
        end
      end

      describe 'keywords: `start_year`, `end_year` and `year`' do
        before do
          create :any_reference, citation_year: '1994'
          create :any_reference, citation_year: '1995'
          create :any_reference, citation_year: '1996a'
          create :any_reference, citation_year: '1998'
          Sunspot.commit
        end

        it "returns entries in between the start year and the end year" do
          results = described_class[start_year: 1995, end_year: 1996]
          expect(results.map(&:year)).to match_array [1995, 1996]
        end
      end

      describe "keyword: `year`" do
        let!(:reference_2004) { create :any_reference, citation_year: '2004' }
        let!(:reference_2005b) { create :any_reference, citation_year: '2005b' }

        before do
          create :any_reference, citation_year: '2003'
          Sunspot.commit
        end

        specify do
          expect(described_class[year: 2004]).to eq [reference_2004]
          expect(described_class[freetext: '2004']).to eq [reference_2004]

          expect(described_class[year: 2005]).to eq [reference_2005b]
          expect(described_class[freetext: '2005']).to eq [reference_2005b]
          expect(described_class[freetext: '2005b']).to eq [reference_2005b]
        end
      end

      describe 'keyword: `reference_type`' do
        let!(:article) { create :article_reference }
        let!(:nested) { create :nested_reference, nesting_reference: article }

        before do
          Sunspot.commit
        end

        specify do
          expect(described_class[]).to match_array [nested, article]
          expect(described_class[reference_type: 'nested']).to eq [nested]
        end
      end

      describe 'keyword: `doi`' do
        let!(:doi) { "10.11865/zs.201806" }
        let!(:reference) { create :article_reference, doi: doi }

        before do
          create :article_reference # Not matching.
          Sunspot.commit
        end

        specify { expect(described_class[doi: doi]).to eq [reference] }
      end
    end

    describe 'searching with free-form text (`freetext` param)' do
      describe 'notes' do
        let!(:with_public_notes) { create :any_reference, public_notes: 'public' }
        let!(:with_editor_notes) { create :any_reference, editor_notes: 'editor' }
        let!(:with_taxonomic_notes) { create :any_reference, taxonomic_notes: 'taxonomic' }

        before do
          Sunspot.commit
        end

        specify do
          expect(described_class[freetext: 'public']).to eq [with_public_notes]
          expect(described_class[freetext: 'editor']).to eq [with_editor_notes]
          expect(described_class[freetext: 'taxonomic']).to eq [with_taxonomic_notes]
        end
      end

      describe 'author names' do
        context "when author name contains hyphens" do
          let!(:reference) { create :any_reference, author_string: 'Abdul-Rassoul, M. S,' }

          before { Sunspot.commit }

          specify do
            expect(described_class[freetext: 'Abdul-Rassoul']).to eq [reference]
            expect(described_class[freetext: 'Abdul Rassoul']).to eq [reference]
          end
        end

        context "when author name contains Spanish diacritics" do
          let!(:reference) { create :any_reference, author_string: 'Acosta Salmerón, F. J.' }

          before { Sunspot.commit }

          specify do
            expect(described_class[freetext: 'Salmerón']).to eq [reference]
            expect(described_class[freetext: 'Salmeron']).to eq [reference]
          end
        end

        context "when author name contains German diacritics" do
          let!(:reference) { create :any_reference, author_string: 'Hölldobler' }

          before { Sunspot.commit }

          specify { expect(described_class[freetext: 'Hölldobler']).to eq [reference] }
          specify { expect(described_class[freetext: 'holldobler']).to eq [reference] }
        end

        context "when author name contains Hungarian diacritics" do
          let!(:reference) { create :any_reference, author_string: 'Csősz' }

          before { Sunspot.commit }

          specify { expect(described_class[freetext: 'Csősz']).to eq [reference] }
          specify { expect(described_class[freetext: 'csosz']).to eq [reference] }
        end

        # TODO: Investigate if we can use `ApostropheFilterFactory` (Solr 4.8) instead of `generateWordParts="0"`.
        context "when author name contains apostrophes" do
          let!(:reference_1) { create :article_reference, author_string: "Arnol'di, K. V." }
          let!(:reference_2) { create :article_reference, author_string: "Guerau d'Arellano Tur, C." }

          before { Sunspot.commit }

          specify do
            expect(described_class[freetext: "Arnol'di"]).to eq [reference_1]
            expect(described_class[freetext: 'Arnoldi']).to eq [reference_1]

            expect(described_class[freetext: "d'Arellano"]).to eq [reference_2]
            expect(described_class[freetext: "darellano"]).to eq [reference_2]
          end
        end

        context "when common English word contains apostrophes" do
          let!(:reference) { create :article_reference, title: "it's pizza time" }

          before { Sunspot.commit }

          specify do
            expect(described_class[freetext: "it"]).to eq [reference]
            expect(described_class[freetext: "its"]).to eq [reference]
            expect(described_class[freetext: "it's"]).to eq [reference]
          end
        end

        context "when author name contains mixed-case words" do
          let!(:reference) { create :article_reference, author_string: "McArthur" }

          before { Sunspot.commit }

          specify do
            expect(described_class[freetext: "McArthur"]).to eq [reference]
            expect(described_class[freetext: "Mcarthur"]).to eq [reference]
            expect(described_class[freetext: "mcarthur"]).to eq [reference]
            expect(described_class[freetext: "mcArthur"]).to eq [reference]
          end
        end
      end

      describe 'journal names (`ArticleReference`s)' do
        let!(:reference) { create :article_reference, journal: create(:journal, name: 'Abc') }

        before do
          create :article_reference # Not matching.
          Sunspot.commit
        end

        it 'searches in `journals.name`' do
          expect(described_class[freetext: 'Abc']).to eq [reference]
        end
      end

      describe 'publisher name (`BookReference`s)' do
        let!(:reference) { create :book_reference, publisher: create(:publisher, name: 'Abc') }

        before do
          create :book_reference # Not matching.
          Sunspot.commit
        end

        it 'searches in `publishers.name`' do
          expect(described_class[freetext: 'Abc']).to eq [reference]
        end
      end
    end
  end

  describe "ignored characters" do
    context "when search query contains ').'" do
      let!(:title) { 'Tetramoriini (Hymenoptera Formicidae).' }
      let!(:reference) { create :any_reference, title: title }

      before { Sunspot.commit }

      specify do
        expect(described_class[freetext: title]).to eq [reference]
        expect(described_class[title: title]).to eq [reference]
      end
    end

    context "when search query contains '&'" do
      let!(:reference) do
        bolton = create :author_name, name: 'Bolton, B.'
        fisher = create :author_name, name: 'Fisher, B.'

        create :any_reference, author_names: [bolton, fisher], citation_year: '1970a'
      end

      before { Sunspot.commit }

      specify { expect(described_class[freetext: "Fisher & Bolton 1970a"]).to eq [reference] }
    end

    context "when search query contains 'et al.'" do
      let!(:reference) do
        bolton = create :author_name, name: 'Bolton, B.'
        fisher = create :author_name, name: 'Fisher, B.'
        ward = create :author_name, name: 'Ward, P.S.'

        create :any_reference, author_names: [bolton, fisher, ward], citation_year: '1970a'
      end

      before { Sunspot.commit }

      specify { expect(described_class[freetext: "Fisher, et al. 1970a"]).to eq [reference] }
    end

    describe "replacing some characters to make search work" do
      let!(:title) { '*Camponotus piceus* (Leach, 1825), decouverte Viroin-Hermeton' }
      let!(:reference) { create :any_reference, title: title }

      it "handles this reference with asterixes and a hyphen" do
        Sunspot.commit

        expect(described_class[freetext: title]).to eq [reference]
        expect(described_class[title: title]).to eq [reference]
      end
    end
  end

  describe 'extracted keywords integration' do
    context 'when searching for multiple authors' do
      let!(:bolton) { create :author_name, name: "Bolton Barry" }
      let!(:fisher) { create :author_name, name: "Brian Fisher" }
      let!(:reference) { create :any_reference, author_names: [bolton, fisher] }

      before do
        Sunspot.commit
      end

      it "returns references by the authors" do
        fulltext_params = References::Search::ExtractKeywords['author:"Bolton Fisher"']
        expect(described_class[**fulltext_params]).to eq [reference]
      end
    end
  end
end
