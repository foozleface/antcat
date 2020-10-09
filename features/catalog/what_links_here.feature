Feature: What links here
  As an editor of AntCat
  I want to see items linked to a taxon or reference

  Background:
    Given I am logged in
    And there is a genus "Atta"
    And there is a genus "Eciton"
    And Eciton has a taxonomic history item that references Atta and a Batiatus reference

  Scenario: See related items (taxa, with detaxed taxt item)
    When I go to the catalog page for "Atta"
    And I follow "What Links Here"
    Then I should see "taxon_history_items"
    And I should see "Eciton"
    And I should see "Atta: Batiatus"

  # TODO: Add after fixing WLHs. [grep:proitem].
  # Scenario: See related items (references, with detaxed taxt item)
  #   When I go to the page of the most recent reference
  #   And I follow "What Links Here"
  #   Then I should see "taxon_history_items"
  #   And I should see "Protonym: Eciton"
  #   And I should see "Atta: Batiatus"
