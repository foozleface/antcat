Feature: Adding a taxon successfully
  Background:
    Given I log in as a catalog editor named "Archibald"
    And this reference exists
      | author | citation_year |
      | Fisher | 2004          |
    And the default reference is "Fisher, 2004"

  @javascript
  Scenario: Adding a genus (with type name)
    Given there is a subfamily "Formicinae"
    And there is a species "Lasius niger"

    When I go to the catalog page for "Formicinae"
    And I follow "Add genus"
    And I set the name to "Atta"
    And I set the protonym name to "Eciton"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"

    When I set the type name to "Lasius niger"
    And I press "Save"
    Then I should be on the catalog page for "Atta"
    And I should see "Eciton" in the protonym
    And I should see "Type-species: Lasius niger"

    When I go to the catalog page for "Formicinae"
    Then I should see "Atta" in the taxon browser

  Scenario: Adding a genus which has a tribe
    Given there is a tribe "Ecitonini"

    When I go to the catalog page for "Ecitonini"
    And I follow "Add genus"
    And I set the name to "Eciton"
    And I set the protonym name to "Eciton"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"
    And I press "Save"
    Then I should be on the catalog page for "Eciton"

  Scenario: Adding a subgenus
    Given there is a genus "Camponotus"

    When I go to the catalog page for "Camponotus"
    And I follow "Add subgenus"
    And I set the name to "Camponotus (Mayria)"
    And I set the protonym name to "Mayria"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"
    And I press "Save"
    Then I should be on the catalog page for "Camponotus (Mayria)"
    And I should see "Mayria" in the protonym

    When I go to the catalog page for "Camponotus"
    And I follow "Subgenera"
    Then I should see "Mayria" in the taxon browser

  Scenario: Adding a species (with edit summary)
    Given there is a genus "Eciton"

    When I go to the catalog page for "Eciton"
    And I follow "Add species"
    And I set the name to "Eciton major"
    And I set the protonym name to "Eciton major"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"
    And I fill in "edit_summary" with "cool new species"
    And I press "Save"
    Then I should be on the catalog page for "Eciton major"
    And I should see "Eciton major" in the protonym
    And I should see "Add another"

    When I go to the activity feed
    Then I should see "Archibald added the species Eciton major to the genus Eciton" and no other feed items
    And I should see the edit summary "cool new species"

  Scenario: Adding a species to a subgenus
    Given there is a subgenus "Dolichoderus (Subdolichoderus)"

    When I go to the catalog page for "Dolichoderus (Subdolichoderus)"
    And I follow "Add species"
    And I set the name to "Dolichoderus major"
    And I set the protonym name to "Dolichoderus major"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"
    And I press "Save"
    Then I should be on the catalog page for "Dolichoderus major"
    And I should see "Dolichoderus major" in the protonym

  Scenario: Adding a subspecies
    Given there is a species "Eciton major" in the genus "Eciton"

    When I go to the catalog page for "Eciton major"
    And I follow "Add subspecies"
    And I set the name to "Eciton major infra"
    And I set the protonym name to "Eciton major infra"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"
    And I press "Save"
    Then I should be on the catalog page for "Eciton major infra"
    And I should see "infra" in the taxon browser
    And I should see "Eciton major infra" in the protonym

  Scenario: Adding a subfamily
    Given the Formicidae family exists

    When I go to the main page
    And I follow "Add subfamily"
    And I set the name to "Dorylinae"
    And I set the protonym name to "Dorylinae"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"
    And I press "Save"
    Then I should be on the catalog page for "Dorylinae"
    And I should see "Dorylinae" in the protonym

    When I follow "Formicidae subfamilies"
    Then I should see "Dorylinae" in the taxon browser

  @javascript
  Scenario: Adding a tribe (and copy name to protonym)
    Given there is a subfamily "Formicinae"

    When I go to the catalog page for "Formicinae"
    And I follow "Add tribe"
    And I set the name to "Dorylini"
    And I click "#copy-name-to-protonym-js-hook"
    And I fill in "taxon_protonym_attributes_authorship_attributes_pages" with "page 35"
    And I press "Save"
    Then I should be on the catalog page for "Dorylini"
    And I should see "Dorylini" in the protonym

    When I go to the catalog page for "Formicinae"
    And I follow "Formicinae tribes"
    Then I should see "Tribe of Formicinae: Dorylini"
