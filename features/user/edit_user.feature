Feature: Editing a user
  As a user of AntCat
  I want to edit my password and email
  So that I can use a password that makes sense
    And so I can use a different email than what I was signed up with

  Scenario: Changing my password
    Given I am logged in

    When I go to the main page
    And I follow the first "Brian Fisher"
    Then I should be on the edit user page

    When I fill in "user_password" with "new password"
    And I fill in "user_password_confirmation" with "new password"
    And I fill in "user_current_password" with "secret"
    And I press "Save"
    Then I should be on the main page
    And I should see "Your account has been updated"

  #Scenario: Logging in with changed password
    When I follow the first "Logout"
    Then I should not see "Brian Fisher"

    When I follow the first "Login"
      And I fill in the email field with my email address
      And I fill in "user_password" with "new password"
    And I press the first "Login"
    Then I should be on the main page
    And I should see "Brian Fisher"

  Scenario: Changing my user name
    Given I am logged in

    When I go to the main page
    Then I should see "Brian Fisher"
    And I should not see "Mark Wilden"

    When I follow the first "Brian Fisher"
    And I fill in "user_name" with "Mark Wilden"
    And I fill in "user_current_password" with "secret"
    And I press "Save"
    Then I should be on the main page
    And I should see "Mark Wilden"
    And I should not see "Brian Fisher"
