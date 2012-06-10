# coding: UTF-8
require 'spec_helper'

describe Genus do

  it "should have a tribe" do
    attini = FactoryGirl.create :tribe, name_object: FactoryGirl.create(:name, name: 'Attini'), :subfamily => FactoryGirl.create(:subfamily, name_object: FactoryGirl.create(:name, name: 'Myrmicinae'))
    FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Atta'), :tribe => attini
    Genus.find_by_name('Atta').tribe.should == attini
  end

  it "should have species, which are its children" do
    atta = FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Atta')
    FactoryGirl.create :species, name_object: FactoryGirl.create(:name, name: 'robusta'), :genus => atta
    FactoryGirl.create :species, name_object: FactoryGirl.create(:name, name: 'saltensis'), :genus => atta
    atta = Genus.find_by_name('Atta')
    atta.species.map(&:name).should =~ ['robusta', 'saltensis']
    atta.children.should == atta.species
  end

  it "should have subspecies" do
    genus = FactoryGirl.create :genus
    FactoryGirl.create :subspecies, :species => FactoryGirl.create(:species, :genus => genus)
    genus.should have(1).subspecies
  end

  it "should have subgenera" do
    atta = FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Atta')
    FactoryGirl.create :subgenus, name_object: FactoryGirl.create(:name, name: 'robusta'), :genus => atta
    FactoryGirl.create :subgenus, name_object: FactoryGirl.create(:name, name: 'saltensis'), :genus => atta
    atta = Genus.find_by_name('Atta')
    atta.subgenera.map(&:name).should =~ ['robusta', 'saltensis']
  end

  describe "Full name" do

    it "is the genus name" do
      taxon = FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Atta'), :subfamily => FactoryGirl.create(:subfamily, name_object: FactoryGirl.create(:name, name: 'Dolichoderinae'))
      taxon.full_name.should == 'Atta'
    end

    it "is just the genus name if there is no subfamily" do
      taxon = FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Atta'), :subfamily => nil
      taxon.full_name.should == 'Atta'
    end

  end

  describe "Full label" do

    it "is the genus name" do
      taxon = FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Atta'), :subfamily => FactoryGirl.create(:subfamily, name_object: FactoryGirl.create(:name, name: 'Dolichoderinae'))
      taxon.full_label.should == '<i>Atta</i>'
    end

    it "is just the genus name if there is no subfamily" do
      taxon = FactoryGirl.create :genus, name_object: FactoryGirl.create(:name, name: 'Atta'), :subfamily => nil
      taxon.full_label.should == '<i>Atta</i>'
    end

  end

  describe "Statistics" do

    it "should handle 0 children" do
      genus = FactoryGirl.create :genus
      genus.statistics.should == {}
    end

    it "should handle 1 valid species" do
      genus = FactoryGirl.create :genus
      species = FactoryGirl.create :species, :genus => genus
      genus.statistics.should == {:extant => {:species => {'valid' => 1}}}
    end

    it "should handle 1 valid species and 2 synonyms" do
      genus = FactoryGirl.create :genus
      FactoryGirl.create :species, :genus => genus
      2.times {FactoryGirl.create :species, :genus => genus, :status => 'synonym'}
      genus.statistics.should == {:extant => {:species => {'valid' => 1, 'synonym' => 2}}}
    end

    it "should handle 1 valid species with 2 valid subspecies" do
      genus = FactoryGirl.create :genus
      species = FactoryGirl.create :species, :genus => genus
      2.times {FactoryGirl.create :subspecies, :species => species}
      genus.statistics.should == {:extant => {:species => {'valid' => 1}, :subspecies => {'valid' => 2}}}
    end

    it "should be able to differentiate extinct species and subspecies" do
      genus = FactoryGirl.create :genus
      species = FactoryGirl.create :species, :genus => genus
      fossil_species = FactoryGirl.create :species, :genus => genus, :fossil => true
      FactoryGirl.create :subspecies, :species => species, :fossil => true
      FactoryGirl.create :subspecies, :species => species
      FactoryGirl.create :subspecies, :species => fossil_species, :fossil => true
      genus.statistics.should == {
        :extant => {:species => {'valid' => 1}, :subspecies => {'valid' => 1}},
        :fossil => {:species => {'valid' => 1}, :subspecies => {'valid' => 2}},
      }
    end

    it "should be able to differentiate extinct species and subspecies" do
      genus = FactoryGirl.create :genus
      species = FactoryGirl.create :species, :genus => genus
      fossil_species = FactoryGirl.create :species, :genus => genus, :fossil => true
      FactoryGirl.create :subspecies, :species => species, :fossil => true
      FactoryGirl.create :subspecies, :species => species
      FactoryGirl.create :subspecies, :species => fossil_species, :fossil => true
      genus.statistics.should == {
        :extant => {:species => {'valid' => 1}, :subspecies => {'valid' => 1}},
        :fossil => {:species => {'valid' => 1}, :subspecies => {'valid' => 2}},
      }
    end

  end

  describe "Without subfamily" do
    it "should just return the genera with no subfamily" do
      cariridris = FactoryGirl.create :genus, :subfamily => nil
      atta = FactoryGirl.create :genus
      Genus.without_subfamily.all.should == [cariridris]
    end
  end

  describe "Without tribe" do
    it "should just return the genera with no tribe" do
      tribe = FactoryGirl.create :tribe
      cariridris = FactoryGirl.create :genus, :tribe => tribe, :subfamily => tribe.subfamily
      atta = FactoryGirl.create :genus, :subfamily => tribe.subfamily, :tribe => nil
      Genus.without_tribe.all.should == [atta]
    end
  end

  describe "Siblings" do

    it "should return itself when there are no others" do
      FactoryGirl.create :genus
      tribe = FactoryGirl.create :tribe
      genus = FactoryGirl.create :genus, :tribe => tribe, :subfamily => tribe.subfamily
      genus.siblings.should == [genus]
    end

    it "should return itself and its tribe's other genera" do
      FactoryGirl.create :genus
      tribe = FactoryGirl.create :tribe
      genus = FactoryGirl.create :genus, :tribe => tribe, :subfamily => tribe.subfamily
      another_genus = FactoryGirl.create :genus, :tribe => tribe, :subfamily => tribe.subfamily
      genus.siblings.should =~ [genus, another_genus]
    end

    it "when there's no subfamily, should return all the genera with no subfamilies" do
      FactoryGirl.create :genus
      genus = FactoryGirl.create :genus, :subfamily => nil, :tribe => nil
      another_genus = FactoryGirl.create :genus, :subfamily => nil, :tribe => nil
      genus.siblings.should =~ [genus, another_genus]
    end

    it "when there's no tribe, return the other genera in its subfamily without tribes" do
      subfamily = FactoryGirl.create :subfamily
      tribe = FactoryGirl.create :tribe, :subfamily => subfamily
      FactoryGirl.create :genus, :tribe => tribe, :subfamily => subfamily
      genus = FactoryGirl.create :genus, :subfamily => subfamily, :tribe => nil
      another_genus = FactoryGirl.create :genus, :subfamily => subfamily, :tribe => nil
      genus.siblings.should =~ [genus, another_genus]
    end

  end

  describe "Importing" do

    it "should work" do
      subfamily = FactoryGirl.create :subfamily
      reference = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
      genus = Genus.import(
        subfamily: subfamily,
        genus_name: 'Atta',
        fossil: true,
        protonym: {genus_name: "Atta",
                   authorship: [{author_names: ["Latreille"], year: "1809", pages: "124"}]},
        type_species: {genus_name: 'Atta', species_epithet: 'major',
                          texts: [{text: [{phrase: ', by monotypy'}]}]},
        taxonomic_history: ["Atta as genus", "Atta as species"]
      ).reload
      genus.name.should == 'Atta'
      genus.should_not be_invalid
      genus.should be_fossil
      genus.subfamily.should == subfamily
      genus.taxonomic_history_items.map(&:taxt).should == ['Atta as genus', 'Atta as species']
      genus.type_taxon_taxt.should == ', by monotypy'

      protonym = genus.protonym
      protonym.name.should == 'Atta'

      authorship = protonym.authorship
      authorship.pages.should == '124'

      authorship.reference.should == reference
    end

    it "save the subgenus part correctly" do
      FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
      genus = Genus.import({
        genus_name: 'Atta',
        protonym: {genus_name: "Atta", authorship: [{author_names: ["Latreille"], year: "1809", pages: "124"}]},
        type_species: {genus_name: 'Atta', subgenus_epithet: 'Solis', species_epithet: 'major',
                          texts: [{text: [{phrase: ', by monotypy'}]}]},
        taxonomic_history: [],
      })
      ForwardReference.fixup
      genus.reload.type_taxon_name.should == 'Atta (Solis) major'
    end

    it "should not mind if there's no type" do
      reference = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
      genus = Genus.import({
        :genus_name => 'Atta',
        :protonym => {
          :genus_name => "Atta",
          :authorship => [{:author_names => ["Latreille"], :year => "1809", :pages => "124"}],
        },
        :taxonomic_history => ["Atta as genus", "Atta as species"]
      }).reload
      ForwardReference.fixup
      genus.type_taxon_taxt.should be_nil
    end

    it "should make sure the type-species is fixed up to point to the genus and not just to any genus with the same name" do
      reference = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'

      genus = Genus.import({
        :genus_name => 'Myrmicium',
        :protonym => {
          :genus_name => "Myrmicium",
          :authorship => [{:author_names => ["Latreille"], :year => "1809", :pages => "124"}],
        },
        :type_species => {:genus_name => 'Myrmicium', :species_epithet => 'heeri'},
        :taxonomic_history => []
      })
      ForwardReference.fixup
      genus.reload.type_taxon_name.should == 'Myrmicium heeri'
      genus.reload.type_taxon_rank.should == 'species'
    end

  end

end
