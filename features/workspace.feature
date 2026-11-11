Feature: Explore the workspace in Emacs

  @UX01 @automated
  Scenario: Build a dashboard without visiting workspace files
    Given unvisited project files and an open Org buffer with live edits
    When I build the dashboard
    Then unvisited files stay unvisited
    And the view reflects live edits

  @UX02 @automated
  Scenario: Open a worked example without creating records
    When I open the example
    Then I see a read-only Org buffer with the outcome folded
    And I can reveal the outcome with TAB

  @UX03 @automated
  Scenario: Choose my own command prefix
    When I set a custom prefix
    Then it opens the command menu with the question mark key
    And I can disable the package's prefix bindings entirely
