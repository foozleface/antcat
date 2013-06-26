@javascript
Feature: Changing species
  As an editor of AntCat
  I want to change a subspecies's species
  So that information is kept accurate
  So people use AntCat

  Background:
    Given I am logged in

  Scenario: Changing a subspecies's species
    Given there is a species "Atta major" with genus "Atta"
    And there is a species "Eciton nigra" with genus "Eciton"
    And there is a subspecies "Atta major minor" which is a subspecies of "Atta major"
    When I go to the edit page for "Atta major minor"
    And I click the parent name field
    And I set the parent name to "Eciton nigra"
    And I press "OK"
    When I save my changes
    Then I should be on the catalog page for "Eciton nigra minor"
    And the name in the header should be "Eciton nigra minor"

  Scenario: Parent field not visible for the family
    Given there is a family "Formicidae"
    When I go to the edit page for "Formicidae"
    Then I should not see the parent name field

  Scenario: Parent field not visible while adding
    Given there is a species "Eciton major" with genus "Eciton"
    When I go to the catalog page for "Eciton major"
    And I press "Edit"
    And I press "Add subspecies"
    And I wait for a bit
    Then I should be on the new taxon page
    Then I should not see the parent name field

  Scenario: Fixing a subspecies without a species
    Given there is a species "Crematogaster menilekii"
    And there is a subspecies "Crematogaster menilekii proserpina" without a species
    When I go to the edit page for "Crematogaster menilekii proserpina"
    And I click the parent name field
    And I set the parent name to "Crematogaster menilekii"
    And I press "OK"
    When I save my changes
    Then I should be on the catalog page for "Crematogaster menilekii proserpina"
