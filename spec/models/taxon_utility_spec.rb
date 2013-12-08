# coding: UTF-8
require 'spec_helper'

describe Taxon do

  describe "Import synonyms" do
    it "should create a new synonym if it doesn't exist" do
      senior = create_genus
      junior = create_genus
      junior.import_synonyms senior
      Synonym.count.should == 1
      synonym = Synonym.first
      synonym.junior_synonym.should == junior
      synonym.senior_synonym.should == senior
    end
    it "should not create a new synonym if it exists" do
      senior = create_genus
      junior = create_genus
      Synonym.create! junior_synonym: junior, senior_synonym: senior
      Synonym.count.should == 1

      junior.import_synonyms senior
      Synonym.count.should == 1
      synonym = Synonym.first
      synonym.junior_synonym.should == junior
      synonym.senior_synonym.should == senior
    end
    it "should not try to create a synonym if the senior is nil" do
      senior = nil
      junior = create_genus
      junior.import_synonyms senior
      Synonym.count.should be_zero
    end
  end

  describe "Extracting original combinations" do
    it "should create an 'original combination' taxon when genus doesn't match protonym's genus" do
      nylanderia = create_genus 'Nylanderia'
      paratrechina = create_genus 'Paratrechina'

      recombined_protonym = FactoryGirl.create :protonym, name: create_species_name('Paratrechina minutula')
      recombined = create_species 'Nylanderia minutula', genus: nylanderia, protonym: recombined_protonym

      not_recombined_protonym = FactoryGirl.create :protonym, name: create_species_name('Nylanderia illustra')
      not_recombined = create_species 'Nylanderia illustra', genus: nylanderia, protonym: not_recombined_protonym

      taxon_count = Taxon.count

      Taxon.extract_original_combinations

      Taxon.count.should == taxon_count + 1
      original_combinations = Taxon.where status: 'original combination'
      original_combinations.size.should == 1
      original_combination = original_combinations.first
      original_combination.genus.should == paratrechina
      original_combination.current_valid_taxon.should == recombined
    end
  end

  describe "Setting current valid taxon to the senior synonym" do
    it "should not worry if the field is already populated" do
      senior = create_genus
      current_valid_taxon = create_genus
      taxon = create_synonym senior, current_valid_taxon: current_valid_taxon
      taxon.update_current_valid_taxon
      taxon.current_valid_taxon.should == current_valid_taxon
    end
    it "should find the latest senior synonym" do
      senior = create_genus
      taxon = create_synonym senior
      taxon.update_current_valid_taxon
      taxon.current_valid_taxon.should == senior
    end
    it "should find the latest senior synonym that's valid" do
      senior = create_genus
      invalid_senior = create_genus status: 'homonym'
      taxon = create_synonym invalid_senior
      Synonym.create! senior_synonym: senior, junior_synonym: taxon
      taxon.update_current_valid_taxon
      taxon.current_valid_taxon.should == senior
    end
    it "should handle when none are valid, in preparation for a Vlad run" do
      invalid_senior = create_genus status: 'homonym'
      another_invalid_senior = create_genus status: 'homonym'
      taxon = create_synonym invalid_senior
      Synonym.create! senior_synonym: another_invalid_senior, junior_synonym: taxon
      taxon.update_current_valid_taxon
      taxon.current_valid_taxon.should be_nil
    end
  end

end
