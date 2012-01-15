# coding: UTF-8
Factory.define :journal do |journal|
  journal.sequence(:name) {|n| "Ants#{n}"}
end

Factory.define :author do |_|
end

Factory.define :author_name do |author_name|
  author_name.sequence(:name) {|n| "Fisher#{n}, B.L."}
  author_name.association :author
end

Factory.define :publisher do |row|
  row.name  'Wiley'
  row.association :place
end

Factory.define :place do |row|
  row.name  'New York'
end

Factory.define :reference do |reference|
  reference.sequence(:title)  {|n| "Ants are my life#{n}"}
  reference.sequence(:citation_year)       {|n| "201#{n}d"}
  reference.author_names      {[Factory(:author_name)]}
end

Factory.define :article_reference do |reference|
  reference.author_names        {[Factory(:author_name)]}
  reference.sequence(:title)    {|n| "Ants are my life#{n}"}
  reference.sequence(:citation_year)       {|n| "201#{n}d"}
  reference.association         :journal
  reference.sequence(:series_volume_issue) {|n| n}
  reference.sequence(:pagination) {|n| n}
end

Factory.define :book_reference do |reference|
  reference.author_names        {[Factory(:author_name)]}
  reference.sequence(:title)    {|n| "Ants are my life#{n}"}
  reference.sequence(:citation_year)       {|n| "201#{n}d"}
  reference.association         :publisher
  reference.pagination          '22 pp.'
end

Factory.define :unknown_reference do |reference|
  reference.author_names        {[Factory(:author_name)]}
  reference.sequence(:title)    {|n| "Ants are my life#{n}"}
  reference.sequence(:citation_year)       {|n| "201#{n}d"}
  reference.citation            'New York'
end

Factory.define :nested_reference do |reference|
  reference.author_names        {[Factory(:author_name)]}
  reference.sequence(:title)    {|n| "Ants are my life#{n}"}
  reference.sequence(:citation_year)       {|n| "201#{n}d"}
  reference.pages_in            'In: '
  reference.nested_reference    {Factory :book_reference}
end

Factory.define :missing_reference do |reference|
  reference.citation "Bolton, 2005"
  reference.citation_year '2001'
  reference.title '(missing)'
end

def reference_factory attributes = {}
  author_name = Factory(:author_name, name: attributes.delete(:author_name))
  reference = Factory(:reference, attributes.merge(author_names: [author_name]))
  reference
end

Factory.define :user do |user|
  user.sequence(:email) {|n| "mark#{n}@example.com"}
  user.password  'secret'
end

Factory.define :bolton_reference, class: Bolton::Reference do |reference|
  reference.title 'New General Catalog'
  reference.citation_year '2011'
  reference.authors 'Fisher, B.L.'
end

Factory.define :bolton_match, class: Bolton::Match do |bolton_match|
  bolton_match.association :bolton_reference
  bolton_match.association :reference
  bolton_match.similarity 0.9
end

Factory.define :reference_document do |_|
end

Factory.define :taxon do |taxon|
  taxon.status  'valid'
end

Factory.define :subfamily do |subfamily|
  subfamily.sequence(:name) {|n| "Subfamily#{n}"}
  subfamily.status  'valid'
end

Factory.define :tribe do |tribe|
  tribe.sequence(:name) {|n| "Tribe#{n}"}
  tribe.association :subfamily
  tribe.status  'valid'
end

Factory.define :genus do |genus|
  genus.sequence(:name) {|n| "Genus#{n}"}
  genus.association :tribe
  genus.subfamily   {|a| a.tribe && a.tribe.subfamily}
  genus.status  'valid'
end

Factory.define :subgenus do |subgenus|
  subgenus.sequence(:name) {|n| "Subgenus#{n}"}
  subgenus.association :genus
  subgenus.status  'valid'
end

Factory.define :species do |species|
  species.sequence(:name) {|n| "Species#{n}"}
  species.association :genus
  species.status  'valid'
end

Factory.define :subspecies do |subspecies|
  subspecies.sequence(:name) {|n| "Subspecies#{n}"}
  subspecies.status  'valid'
  subspecies.association :species
end
