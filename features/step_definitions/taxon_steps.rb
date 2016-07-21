Given /^there is a family "Formicidae"$/ do
  create_family
end

Given /^the Formicidae family exists$/ do
  reference = create :article_reference,
    author_names: [create(:author_name, name: 'Latreille, I.')],
    citation_year: '1809',
    title: 'Ants'

  protonym = create :protonym,
    name: create(:family_or_subfamily_name, name: "Formicariae"),
    authorship: create(:citation, reference: reference, pages: "124" )

  family = create :family,
    name: create(:family_name, name: "Formicidae"),
    protonym: protonym,
    type_name: create(:genus_name, name: "Formica"),
    history_items: [create(:taxon_history_item)]

  create :taxon_state, taxon_id: family.id
end

#############################
# subfamily
Given /there is a subfamily "([^"]*)" with taxonomic history "([^"]*)"$/ do |taxon_name, history|
  name = create :subfamily_name, name: taxon_name
  taxon = create_taxon_with_state(:subfamily, name)
  taxon.history_items.create! taxt: history
end
Given /there is a subfamily "([^"]*)" with a reference section "(.*?)"$/ do |taxon_name, references|
  name = create :subfamily_name, name: taxon_name
  taxon = create_taxon_with_state(:subfamily, name)
  taxon.reference_sections.create! references_taxt: references
end
Given /there is a subfamily "([^"]*)"$/ do |taxon_name|
  name = create :subfamily_name, name: taxon_name
  @subfamily = create_taxon_with_state(:subfamily, name)
end

Given /^subfamily "(.*?)" exists$/ do |name|
  @subfamily = create_taxon_with_state(:subfamily, create(:subfamily_name, name: name))
  @subfamily.history_items.create! taxt: "#{name} history"
end
Given /^the unavailable subfamily "(.*?)" exists$/ do |name|
  @subfamily = create(:subfamily, status: 'unavailable', name: create(:subfamily_name, name: name))
  create :taxon_state, taxon_id: @subfamily.id
  @subfamily
end

###########################
# tribe
Given /^there is a tribe "([^"]*)"$/ do |name|
  create_tribe name
end
Given /a tribe exists with a name of "(.*?)"(?: and a subfamily of "(.*?)")?(?: and a taxonomic history of "(.*?)")?/ do |taxon_name, parent_name, history|
  subfamily = parent_name && (Subfamily.find_by_name(parent_name) ||
      create_taxon_with_state(:subfamily, name: create(:name, name: parent_name)))
  taxon = create :tribe, name: create(:name, name: taxon_name), subfamily: subfamily
  create :taxon_state, taxon_id: taxon.id

  history = 'none' unless history.present?
  taxon.history_items.create! taxt: history
end
Given /^tribe "(.*?)" exists in that subfamily$/ do |name|
  @tribe = create :tribe, subfamily: @subfamily, name: create(:tribe_name, name: name)
  create :taxon_state, taxon_id: @tribe.id
  @tribe.history_items.create! taxt: "#{name} history"
end

###########################
# subgenus
Given /^subgenus "(.*?)" exists in that genus$/ do |name|
  epithet = name.match(/\((.*?)\)/)[1]
  name = create :subgenus_name, name: name, epithet: epithet

  @subgenus = create :subgenus, subfamily: @subfamily, tribe: @tribe, genus: @genus, name: name
  create :taxon_state, taxon_id: @subgenus.id
  @subgenus.history_items.create! taxt: "#{name} history"
end

#############################
# genus
Given /^there is a genus "([^"]*)"$/ do |name|
  genus = create_genus name
end

Given /^there is a genus "([^"]*)" with taxonomic history "(.*?)"$/ do |name, history|
  genus = create_genus name
  genus.history_items.create! taxt: history
end
Given /^there is a genus "([^"]*)" with protonym name "(.*?)"$/ do |name, protonym_name|
  genus = create_genus name
  genus.protonym.name = Name.find_by_name protonym_name if protonym_name
end
Given /^there is a genus "([^"]*)" without protonym authorship$/ do |name|
  protonym = create :protonym
  genus = create_genus name, protonym: protonym
  genus.protonym.update_attribute :authorship, nil
end
Given /^there is a genus "([^"]*)" with type name "(.*?)"$/ do |name, type_name|
  genus = create_genus name
  genus.type_name = Name.find_by_name type_name
end
Given /^there is a genus "([^"]*)" that is incertae sedis in the subfamily$/ do |name|
  genus = create_genus name
  genus.update_attribute :incertae_sedis_in, 'subfamily'
end
Given /^a genus exists with a name of "(.*?)" and a subfamily of "(.*?)"(?: and a taxonomic history of "(.*?)")?(?: and a status of "(.*?)")?$/ do |taxon_name, parent_name, history, status|
  status ||= 'valid'
  subfamily = parent_name && (Subfamily.find_by_name(parent_name) || create(:subfamily, name: create(:name, name: parent_name)))
  create :taxon_state, taxon_id: subfamily.id
  taxon = create :genus, name: create(:name, name: taxon_name), subfamily: subfamily, tribe: nil, status: status
  create :taxon_state, taxon_id: taxon.id
  history = 'none' unless history.present?
  taxon.history_items.create! taxt: history
end
Given /^a non-displayable genus exists with a name of "(.*?)" and a subfamily of "(.*?)"$/ do |taxon_name, subfamily_name|
  subfamily = (Subfamily.find_by_name(subfamily_name) || create(:subfamily, name: create(:name, name: subfamily_name)))
  create :taxon_state, taxon_id: subfamily.id
  taxon = create :genus, name: create(:name, name: taxon_name), subfamily: subfamily, tribe: nil, status: 'valid', display: false
  create :taxon_state, taxon_id: taxon.id
end
Given /a genus exists with a name of "(.*?)" and no subfamily(?: and a taxonomic history of "(.*?)")?/ do |taxon_name, history|
  another_genus = create(:genus_name, name: taxon_name)
  create :taxon_state, taxon_id: another_genus.id
  genus = create :genus, name: another_genus, subfamily: nil, tribe: nil
  create :taxon_state, taxon_id: genus.id
  history = 'none' unless history.present?
  genus.history_items.create! taxt: history
end
Given /a (fossil )?genus exists with a name of "(.*?)" and a tribe of "(.*?)"(?: and a taxonomic history of "(.*?)")?/ do |fossil, taxon_name, parent_name, history|
  tribe = Tribe.find_by_name(parent_name)
  history = 'none' unless history.present?
  taxon = create :genus, name: create(:name, name: taxon_name), subfamily: tribe.subfamily, tribe: tribe, fossil: fossil.present?
  create :taxon_state, taxon_id: taxon.id
  taxon.history_items.create! taxt: history
end
Given /^genus "(.*?)" exists in that tribe$/ do |name|
  @genus = create :genus, subfamily: @subfamily, tribe: @tribe, name: create(:genus_name, name: name)
  create :taxon_state, taxon_id: @genus.id
  @genus.history_items.create! taxt: "#{name} history"
end
Given /^genus "(.*?)" exists in that subfamily/ do |name|
  @genus = create :genus, subfamily: @subfamily, tribe: nil, name: create(:genus_name, name: name)
  create :taxon_state, taxon_id: @genus.id
  @genus.history_items.create! taxt: "#{name} history"
end
Given /^there is a genus "([^"]*)" with "([^"]*)" name$/ do |name, gender|
  genus = create_genus name
  genus.name.update_attributes! gender: gender
end

###########################
# species
Given /^there is a species "([^"]*)"$/ do |name|
  create_species name
end
Given /^there is a parentless subspecies "([^"]*)"$/ do |name|
  @subspecies = create_subspecies name
  @subspecies.species_id = nil
  @subspecies.save!(validate: false)
end

Given /a species exists with a name of "(.*?)" and a genus of "(.*?)"(?: and a taxonomic history of "(.*?)")?/ do |taxon_name, parent_name, history|
  genus = Genus.find_by_name(parent_name) || create(:genus, name: create(:genus_name, name: parent_name))
  create :taxon_state, taxon_id: genus.id
  @species = create :species, name: create(:species_name, name: "#{parent_name} #{taxon_name}"), genus: genus
  create :taxon_state, taxon_id: @species.id
  history = 'none' unless history.present?
  @species.history_items.create! taxt: history
end

Given /an imported species exists with a name of "(.*?)" and a genus of "(.*?)"/ do |taxon_name, parent_name|
  genus = Genus.find_by_name(parent_name) || create(:genus, name: create(:genus_name, name: parent_name))
  create :taxon_state, taxon_id: genus.id
  name = create :species_name, name: "#{parent_name} #{taxon_name}", auto_generated: true, origin: 'hol'
  @species = create :species, name: name, genus: genus, auto_generated: true, origin: 'hol'
end

Given /^species "(.*?)" exists in that subgenus$/ do |name|
  @species = create :species, subfamily: @subfamily, genus: @genus, subgenus: @subgenus, name: create(:species_name, name: name)
  create :taxon_state, taxon_id: @species.id
  @species.history_items.create! taxt: "#{name} history"
end
Given /^species "(.*?)" exists in that genus$/ do |name|
  @species = create :species, subfamily: @subfamily, genus: @genus, name: create(:species_name, name: name)
  create :taxon_state, taxon_id: @species.id
  @species.history_items.create! taxt: "#{name} history"
end
Given /^there is an original species "([^"]*)" with genus "([^"]*)"$/ do |species_name, genus_name|
  genus = create_genus genus_name
  create_species species_name, genus: genus, status: Status['original combination'].to_s
end

Given /^there is species "([^"]*)" and another species "([^"]*)" shared between protonym genus "([^"]*)" and later genus "([^"]*)"$/ do
|protonym_species_name, valid_species_name, protonym_genus_name, valid_genus_name|
  proto_genus = create_genus protonym_genus_name
  proto_species = create_species protonym_species_name, genus: proto_genus, status: Status['original combination'].to_s
  later_genus = create_genus valid_genus_name
  create_species valid_species_name, genus: later_genus, status: Status['valid'].to_s, protonym_id: proto_species.id
end

Given /^there is a species "([^"]*)" with genus "([^"]*)"$/ do |species_name, genus_name|
  genus = create_genus genus_name
  create_species species_name, genus: genus
end
Given /^there is a subspecies "([^"]*)" with genus "([^"]*)" and no species$/ do |subspecies_name, genus_name|
  genus = create_genus genus_name
  create_subspecies subspecies_name, genus: genus, species: nil
end
Given /^there is a species "([^"]*)"(?: described by "([^"]*)")? which is a junior synonym of "([^"]*)"$/ do |junior, author_name, senior|
  genus = create_genus 'Solenopsis'
  senior = create_species senior, genus: genus
  junior = create_species junior, status: 'synonym', genus: genus
  Synonym.create! senior_synonym: senior, junior_synonym: junior
  make_author_of_taxon junior, author_name if author_name
end

def make_author_of_taxon taxon, author_name
  author = create :author
  author_name = create :author_name, name: author_name, author: author
  reference = create :article_reference, author_names: [author_name]
  taxon.protonym.authorship.update_attributes! reference: reference
end

###########################
# subspecies
Given /^there is a subspecies "([^"]*)"$/ do |name|
  create_subspecies name
end
Given /^there is a subspecies "([^"]*)" which is a subspecies of "([^"]*)"$/ do |subspecies_name, species_name|
  create_subspecies subspecies_name, species: Species.find_by_name(species_name)
end
Given /^there is a subspecies "([^"]*)" without a species/ do |subspecies_name|
  create_subspecies subspecies_name, species: nil
end
Given /a subspecies exists for that species with a name of "(.*?)" and an epithet of "(.*?)" and a taxonomic history of "(.*?)"/ do |name, epithet, history|
  subspecies = create :subspecies, name: create(:subspecies_name, name: name, epithet: epithet, epithets: epithet), species: @species, genus: @species.genus
  create :taxon_state, taxon_id: subspecies.id
  subspecies.save!
  history = 'none' unless history.present?
  subspecies.history_items.create! taxt: history
end
Given /^subspecies "(.*?)" exists in that species$/ do |name|
  @subspecies = create :subspecies, subfamily: @subfamily, genus: @genus, species: @species, name: create(:subspecies_name, name: name)
  create :taxon_state, taxon_id: @subspecies.id
  @subspecies.save!
  @subspecies.history_items.create! taxt: "#{name} history"
end
Given /^there is a subspecies "([^"]*)" which is a subspecies of "([^"]*)" in the genus "([^"]*)"/ do |subspecies, species, genus|
  genus = create_genus genus
  species = create_species species, genus: genus
  subspecies = create_subspecies subspecies, species: species, genus: genus
end

##################################################

Given /^there is a species name "([^"]*)"$/ do |name|
  find_or_create_name name
end

Then(/^The taxon mouseover should contain "(.*?)"$/) do |arg1|
  find('.reference_key')['title'].should have_content(arg1)
end
