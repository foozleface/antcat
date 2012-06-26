# coding: UTF-8
require 'spec_helper'

describe Species do

  describe "SpeciesGroupTaxon inheritance" do
    it "can have a subfamily" do
      genus = create_genus 'Afropone'
      FactoryGirl.create :species, name: FactoryGirl.create(:name, name: 'championi'), genus: genus
      Species.find_by_name('championi').subfamily.should == genus.subfamily
    end

    it "doesn't have to have a subfamily" do
      FactoryGirl.create(:species, subfamily: nil).should be_valid
    end

    it "must have a genus" do
      species = FactoryGirl.build :species, genus: nil
      species.should_not be_valid
      genus = create_genus 'Afropone'
      species.update_attributes genus: genus
      species = Species.find species
      species.should be_valid
      species.genus.should == genus
    end

    it "can have a subgenus" do
      subgenus = create_subgenus 'Atta (Subatta)'
      FactoryGirl.create :species, name: FactoryGirl.create(:name, name: 'Atta championi'), subgenus: subgenus
      Species.find_by_name('Atta championi').subgenus.should == subgenus
    end

    it "has its subfamily set from its genus" do
      genus = create_genus
      genus.subfamily.should_not be_nil
      species = create_species genus: genus, subfamily: nil
      species.subfamily.should == genus.subfamily
    end

  end

  it "should have subspecies, which are its children" do
    species = FactoryGirl.create :species, name: FactoryGirl.create(:name, name: 'chilensis')
    FactoryGirl.create :subspecies, name: FactoryGirl.create(:name, name: 'robusta'), species: species
    FactoryGirl.create :subspecies, name: FactoryGirl.create(:name, name: 'saltensis'), species: species
    species = Species.find_by_name 'chilensis'
    species.subspecies.map(&:name).map(&:to_s).should =~ ['robusta', 'saltensis']
    species.children.should == species.subspecies
  end

  describe "Name" do
    it "should handle it" do
      subfamily = FactoryGirl.create :subfamily, name: FactoryGirl.create(:subfamily_name, name: 'Dolichoderinae')
      genus = FactoryGirl.create :genus, name: FactoryGirl.create(:genus_name, name: 'Myrmicium'), subfamily: subfamily
      species = FactoryGirl.create :species, name: FactoryGirl.create(:species_name, name: 'Myrmicium shattucki', epithet: 'shattucki'), genus: genus
      species.name.to_s.should == 'Myrmicium shattucki'
    end
  end

  describe "Statistics" do

    it "should handle 0 children" do
      FactoryGirl.create(:species).statistics.should == {}
    end

    it "should handle 1 valid subspecies" do
      species = FactoryGirl.create :species
      subspecies = FactoryGirl.create :subspecies, species: species
      species.statistics.should == {extant: {subspecies: {'valid' => 1}}}
    end

    it "should differentiate between extant and fossil subspecies" do
      species = FactoryGirl.create :species
      subspecies = FactoryGirl.create :subspecies, species: species
      FactoryGirl.create :subspecies, species: species, fossil: true
      species.statistics.should == {
        extant: {subspecies: {'valid' => 1}},
        fossil: {subspecies: {'valid' => 1}},
      }
    end

    it "should differentiate between extant and fossil subspecies" do
      species = FactoryGirl.create :species
      subspecies = FactoryGirl.create :subspecies, species: species
      FactoryGirl.create :subspecies, species: species, fossil: true
      species.statistics.should == {
        extant: {subspecies: {'valid' => 1}},
        fossil: {subspecies: {'valid' => 1}},
      }
    end

    it "should handle 1 valid subspecies and 2 synonyms" do
      species = FactoryGirl.create :species
      FactoryGirl.create :subspecies, species: species
      2.times {FactoryGirl.create :subspecies, species: species, status: 'synonym'}
      species.statistics.should == {extant: {subspecies: {'valid' => 1, 'synonym' => 2}}}
    end

  end

  describe "Siblings" do
    it "should return itself and its subfamily's other tribes" do
      FactoryGirl.create :tribe
      subfamily = FactoryGirl.create :subfamily
      tribe = FactoryGirl.create :tribe, subfamily: subfamily
      another_tribe = FactoryGirl.create :tribe, subfamily: subfamily
      tribe.siblings.should =~ [tribe, another_tribe]
    end
  end

  describe "Importing" do

    it "should work" do
      subfamily = FactoryGirl.create :subfamily
      genus = FactoryGirl.create :genus, name: FactoryGirl.create(:genus_name, name: 'Fiona'), subfamily: subfamily
      reference = FactoryGirl.create :article_reference, bolton_key_cache: 'Latreille 1809'

      species = Species.import(
        genus: genus,
        species_epithet: 'major',
        fossil: true,
        protonym: {genus_name: "Atta", species_epithet: 'major',
                   authorship: [{author_names: ["Latreille"], year: "1809", pages: "124"}]},
        history: ['Atta major as species', 'Atta major as subspecies']
      ).reload
      species.name.to_s.should == 'Fiona major'
      species.should_not be_invalid
      species.should be_fossil
      species.genus.should == genus
      species.subfamily.should == subfamily
      species.taxonomic_history_items.map(&:taxt).should == ['Atta major as species', 'Atta major as subspecies']

      protonym = species.protonym
      protonym.name.to_s.should == 'Atta major'

      authorship = protonym.authorship
      authorship.pages.should == '124'

      authorship.reference.should == reference
    end

    it "should not freak if there is no protonym" do
      genus = create_genus 'Afropone'
      -> {Species.import(
        genus:                  genus,
        species_group_epithet:  'orapa',
        unparseable: '*<i>Afropone</i> (?) <i>orapa</i> Dlussky, Brothers & Rasnitsyn, 2004: 9, fig. 12 (m.) BOTSWANA (Cretaceous).'
      )}.should raise_error Species::NoProtonymError
    end

    describe "Importing subspecies" do
      it "should handle the happy case" do
        genus = create_genus 'Camponotus'
        taxon = Species.import(
          genus:                  genus,
          species_group_epithet:  'refectus',
          protonym: {
            genus_name:           'Camponotus',
            subgenus_epithet:     'Myrmeurynota',
            species_epithet:      'gilviventris',
            subspecies: [{type:   'var.',
              subspecies_epithet: 'refectus',
         }]})
        taxon.should be_kind_of Subspecies
        taxon.name.to_s.should == 'Camponotus (Myrmeurynota) gilviventris var. refectus'
        reference = SpeciesEpithetReference.first
        reference.fixee.should == taxon
        reference.genus.should == genus
        reference.epithet.should == 'gilviventris'
      end
    end
    describe "Importing species that look like subspecies" do
      it "should import a species with a subspecies protonym and a list of subspecies" do
        genus = create_genus 'Aenictus'
        taxon = Species.import(
          genus:                  genus,
          species_group_epithet:  'alluaudi',
          protonym: {
            genus_name:           'Aenictus',
            species_epithet:      'bottegoi',
            subspecies: [{type:   'var.',
              subspecies_epithet: 'alluaudi',
            }]
          },
          raw_history: [{subspecies: [{species_group_epithet: 'falcifer'}]}],
        )
        taxon.should be_kind_of Species
      end

      it "should import a species with a subspecies protonym that was raised to species" do
        genus = create_genus 'Anonychomyrma'
        taxon = Species.import(
          genus:                  genus,
          species_group_epithet:  'malandana',
          protonym: {
            genus_name:           'Iridomyrmex',
            species_epithet:      'innocens',
            subspecies: [{type:   'r.',
              subspecies_epithet: 'malandanus',
            }]
          },
          raw_history: [{raised_to_species: {references:[]}}]
        )
        taxon.should be_kind_of Species
      end

      it "should import a subspecies with a subspecies protonym for a different species than current" do
        genus = create_genus 'Camponotus'
        species_name = FactoryGirl.create :species_name, name: 'Camponotus hova', epithet: 'hova'
        species = FactoryGirl.create :species, name: species_name, genus: genus

        taxon = Species.import(
          genus:                  genus,
          species_group_epithet:  'radamae',
          protonym: {
            genus_name:           'Camponotus',
            species_epithet:      'maculatus',
            subspecies: [{type:   'r.',
              subspecies_epithet: 'radamae',
            }]
          },
          raw_history: [{currently_subspecies_of: {species: {species_epithet: 'hova'}}}]
        )
        ForwardReference.fixup
        taxon = Taxon.find taxon
        taxon.should be_kind_of Subspecies
        taxon.species.name.to_s.should == 'Camponotus hova'
      end
    end

  end

  describe "Setting status from history" do
    it "should handle no history" do
      species = FactoryGirl.create :species
      for history in [nil, []]
        species.set_status_from_history history
        Species.find(species).reload.status.should == 'valid'
      end
    end
    it "should recognize a synonym_of" do
      genus = FactoryGirl.create :genus, name: FactoryGirl.create(:genus_name, name: 'Atta')
      ferox = FactoryGirl.create :species, name: FactoryGirl.create(:name, name: 'Atta ferox'), genus: genus
      species = FactoryGirl.create :species, genus: genus
      history = [{synonym_ofs: [{species_epithet: 'ferox', junior_or_senior: :junior}]}]
      species.set_status_from_history history
      species = Species.find species
      ForwardReference.fixup
      #species.should be_synonym
      #species.synonym_of?(ferox).should be_true
    end
    it "should find the senior synonym using declension rules" do
      genus = FactoryGirl.create :genus, name: FactoryGirl.create(:genus_name, name: 'Atta')
      magna = FactoryGirl.create :species, name: FactoryGirl.create(:species_name, name: 'Atta magna', epithet: 'magna'), genus: genus
      species = FactoryGirl.create :species, genus: genus
      history = [{synonym_ofs: [{species_epithet: 'magnus', junior_or_senior: :junior}]}]
      species.set_status_from_history history
      species = Species.find species
      #species.should be_synonym
      #species.synonym_of?(ferox).should be_true
    end
    it "should recognize a synonym_of even if it's not the first item in the history" do
      genus = FactoryGirl.create :genus, name: FactoryGirl.create(:genus_name, name: 'Atta')
      ferox = FactoryGirl.create :species, name: FactoryGirl.create(:name, name: 'Atta texanus'), genus: genus
      species = FactoryGirl.create :species, genus: genus
      history = 
        [{combinations_in:
          [{genus_name:"Acanthostichus",
            subgenus_epithet:"Ctenopyga",
            references:
              [{author_names:["Emery"],
                year:"1911d",
                pages:"14",
                matched_text:"Emery, 1911d: 14"}]}],
          matched_text:
          " Combination in <i>Acanthostichus (Ctenopyga)</i>: Emery, 1911d: 14."},
        {:synonym_ofs=>
          [{:species_epithet=>"texanus",
            :references=>
              [{:author_names=>["Smith, M.R."],
                :year=>"1955a",
                :pages=>"49",
                :matched_text=>"Smith, M.R. 1955a: 49"}],
            :junior_or_senior=>:junior}],
          :matched_text=>
          " Junior synonym of <i>texanus</i>: Smith, M.R. 1955a: 49."}]

      species.set_status_from_history history
      species.reload.should be_synonym
    end

  end

end
