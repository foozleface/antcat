# frozen_string_literal: true

require 'rails_helper'

describe SubspeciesName do
  describe '#name=' do
    specify do
      name = described_class.new(name: 'Lasius niger fusca')

      expect(name.name).to eq 'Lasius niger fusca'
      expect(name.epithet).to eq 'fusca'
    end

    specify do
      name = described_class.new(name: 'Lasius niger var. fusca')

      expect(name.name).to eq 'Lasius niger var. fusca'
      expect(name.epithet).to eq 'fusca'
    end

    specify do
      name = described_class.new(name: 'Lasius (Austrolasius) niger fusca')

      expect(name.name).to eq 'Lasius (Austrolasius) niger fusca'
      expect(name.epithet).to eq 'fusca'
    end

    specify do
      name = described_class.new(name: 'Lasius (Austrolasius) niger var. fusca')

      expect(name.name).to eq 'Lasius (Austrolasius) niger var. fusca'
      expect(name.epithet).to eq 'fusca'
    end
  end

  describe "name parts" do
    context 'when three name parts' do
      let(:name) { described_class.new(name: 'Atta major minor') }

      specify do
        expect(name.genus_epithet).to eq 'Atta'
        expect(name.species_epithet).to eq 'major'
        expect(name.subspecies_epithets).to eq 'minor'
      end
    end

    context 'when four name parts' do
      let(:name) { described_class.new(name: 'Acus major minor medium') }

      specify { expect(name.subspecies_epithets).to eq 'minor medium' }
    end
  end
end
