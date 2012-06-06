# coding: UTF-8
require 'asterisk_dagger_formatting'

class Taxon < ActiveRecord::Base
  set_table_name :taxa

  belongs_to  :synonym_of, :class_name => 'Taxon', :foreign_key => :synonym_of_id
  has_one     :homonym_replaced, :class_name => 'Taxon', :foreign_key => :homonym_replaced_by_id
  belongs_to  :protonym, dependent: :destroy
  belongs_to  :homonym_replaced_by, :class_name => 'Taxon'
  has_many    :taxonomic_history_items, order: :position, dependent: :destroy
  has_many    :reference_sections, :order => :position, dependent: :destroy
  belongs_to  :name_object, class_name: 'Name', foreign_key: 'name_id'

  validates_presence_of :name

  scope :valid, where("status = ?", 'valid')
  scope :ordered_by_name, order(:name)
  scope :extant, where(:fossil => false)

  def unavailable?;     status == 'unavailable' end
  def available?;       !unavailable? end
  def invalid?;         status != 'valid' end
  def unidentifiable?;  status == 'unidentifiable' end
  def synonym?;         status == 'synonym' end
  def homonym?;         status == 'homonym' end
  def unresolved_homonym?;status == 'unresolved homonym' end
  def excluded?;        status == 'excluded' end

  def rank
    Rank[self].to_s
  end

  def children
    raise NotImplementedError
  end

  def synonym_of? taxon
    synonym_of == taxon
  end

  def homonym_replaced_by? taxon
    homonym_replaced_by == taxon
  end

  def current_valid_name
    target = self
    target = target.synonym_of while target.synonym_of
    target.name
  end

  def full_name
    name
  end

  def self.find_name name, search_type = 'matching'
    query = ordered_by_name
    names = name.split ' '
    if names.size > 1
      query = query.joins 'JOIN taxa genera ON genera.id = taxa.genus_id'
      query = query.where ['genera.name = ?', names.first]
      name = names.second
    end
    types_sought = ['Subfamily', 'Tribe', 'Genus', 'Species']
    case search_type
    when 'matching'
      query = query.where ['taxa.name = ? AND taxa.type IN (?)', name, types_sought]
    when 'beginning with'
      query = query.where ['taxa.name LIKE ? AND taxa.type IN (?)', name + '%', types_sought]
    when 'containing'
      query = query.where ['taxa.name LIKE ? AND taxa.type IN (?)', '%' + name + '%', types_sought]
    end
    query.all
  end

  def self.statistics
    get_statistics [[Subfamily, :subfamilies], [Genus, :genera], [Species, :species], [Subspecies, :subspecies]]
  end

  def get_statistics ranks
    statistics = {}
    ranks.each do |rank|
      count = send(rank).count :group => [:fossil, :status]
      self.class.massage_count count, rank, statistics
    end
    statistics
  end

  def self.get_statistics ranks
    statistics = {}
    ranks.each do |klass, rank|
      count = klass.count :group => [:fossil, :status]
      massage_count count, rank, statistics
    end
    statistics
  end

  def self.massage_count count, rank, statistics
    count.keys.each do |fossil, status|
      value = count[[fossil, status]]
      extant_or_fossil = fossil ? :fossil : :extant
      statistics[extant_or_fossil] ||= {}
      statistics[extant_or_fossil][rank] ||= {}
      statistics[extant_or_fossil][rank][status] = value
    end
  end

  def convert_asterisks_to_daggers!
    update_attribute :taxonomic_history, taxonomic_history.convert_asterisks_to_daggers if taxonomic_history?
  end

  def incertae_sedis_in? rank
    incertae_sedis_in == rank
  end

  def child_list_query children_selector, conditions = {}
    children = send children_selector
    children = children.where fossil: !!conditions[:fossil] if conditions.key? :fossil
    incertae_sedis_in = conditions[:incertae_sedis_in]
    children = children.where incertae_sedis_in: incertae_sedis_in if incertae_sedis_in
    children = children.where hong: !!conditions[:hong] if conditions.key? :hong
    children = children.where "status = 'valid' OR status = 'unresolved homonym'"
    children
  end

end
