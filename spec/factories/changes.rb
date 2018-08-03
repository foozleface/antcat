FactoryBot.define do
  factory :change do
    change_type "create"
  end
end

def setup_version taxon, user
  change = create :change, user_changed_taxon_id: taxon.id, user: user

  create :version,
    item: taxon,
    event: 'create',
    change: change,
    whodunnit: user.id
  change
end

def create_taxon_version_and_change review_state, user = @user, approver = nil, genus_name = 'default_genus'
  name = create :name, name: genus_name
  taxon = create :genus, name: name
  taxon.taxon_state.review_state = review_state

  change = create :change, user_changed_taxon_id: taxon.id, change_type: "create", user: user
  create :version, item: taxon, whodunnit: user.id, change: change

  if approver
    change.update! approver: approver, approved_at: Time.current
  end

  taxon
end
