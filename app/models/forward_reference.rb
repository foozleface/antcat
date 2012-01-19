# coding: UTF-8
class ForwardReference < ActiveRecord::Base

  def self.fixup
    all.each {|e| e.fixup}
  end

  def fixup
    source = Taxon.find source_id
    target = case source
      when Family
        Genus.create! :name => target_name, :status => 'valid', :fossil => fossil
      when Genus
        Species.create_from_fixup :name => target_name, :fossil => fossil
      else raise
      end
    source.update_attribute :type_taxon, target
  end

end

