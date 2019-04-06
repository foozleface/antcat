require "spec_helper"

describe TaxonDecorator::LinkEachEpithet do
  include TestLinksHelpers

  describe "#call" do
    context 'when taxon is above species-rank' do
      let(:taxon) { create :subfamily }

      it 'just links the genus' do
        expect(described_class[taxon]).to eq taxon_link(taxon)
      end
    end

    context 'when taxon is a species`' do
      let(:taxon) { create :species }

      it 'links the genus and species' do
        expect(described_class[taxon]).to eq(
          taxon_link(taxon.genus, "<i>#{taxon.genus.name_cache}</i>") + ' ' +
          taxon_link(taxon, "<i>#{taxon.name.species_epithet}</i>")
        )
      end
    end

    context 'when taxon is a subspecies`' do
      let(:taxon) { create :subspecies }

      context "when taxon has 2 epithets (standard modern subspecies name)" do
        it 'links the genus, species and subspecies' do
          expect(described_class[taxon]).to eq(
            taxon_link(taxon.genus, "<i>#{taxon.genus.name_cache}</i>") + ' ' +
            taxon_link(taxon.species, "<i>#{taxon.species.name.species_epithet}</i>") + ' ' +
            taxon_link(taxon, "<i>#{taxon.name.subspecies_epithets}</i>")
          )
        end
      end

      context "when taxon has more than 3 epithets" do
        let!(:genus) { create_genus 'Formica' }
        let!(:species) { create_species 'rufa', genus: genus }
        let!(:subspecies) do
          major_name = SubspeciesName.create! name: 'NOTUSED NOTUSED pratensis major',
            epithet: 'NOTUSED', epithets: 'NOTUSED'
          create :subspecies, name: major_name, species: species, genus: genus
        end

        specify do
          expect(described_class[subspecies]).to eq(
            taxon_link(genus, '<i>Formica</i>') + ' ' +
            taxon_link(species, '<i>rufa</i>') + ' ' +
            taxon_link(subspecies, '<i>pratensis major</i>')
          )
        end
      end
    end
  end
end
