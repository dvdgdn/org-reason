Feature: Make commitments dependable
  As a person managing commitments
  I want to distinguish outcomes from available physical actions
  So my action list can be trusted in the current context

  @GTD01 @automated
  Scenario: Clarify without creating a duplicate action
    Given one identified inbox entry
    When I clarify it as a next action with context and effort
    Then its identity and body are retained
    And it appears once in the action system
    And it no longer appears in the inbox

  @GTD02 @automated
  Scenario: Review an active project after its next action is completed
    Given a project outcome with one next action
    When that action is completed and no wait or dated commitment remains
    Then the project appears in the missing-next-action audit

  @GTD03 @automated
  Scenario: Delegate with a named waiting-for reminder
    Given an inbox item I have delegated
    When I clarify it with the responsible person's name
    Then the reminder is WAIT with that person and a delegation date
    And no message is sent by clarification

  @GTD04 @automated
  Scenario: Incubate without adding current work
    When I clarify an idea as someday
    Then it appears as SOMEDAY
    And it is absent from the NEXT list

  @GTD05 @automated
  Scenario: Reserve dates for genuine date requirements
    Given an inbox item
    When I clarify it as a calendar commitment without a valid date
    Then clarification is refused and the inbox item is retained

  @GTD06 @automated
  Scenario: Preserve a source when writing the destination fails
    Given a captured item
    When a clarification destination cannot be written
    Then the original source material remains recoverable

  @GTD07 @automated
  Scenario: Return to the same weekly review
    Given I already wrote a decision in this week's review
    When I open the review again
    Then the decision remains

  @GTD08 @manual
  Scenario: Complete a real weekly review
    Given my collection points include paper, email, and an external calendar
    When I complete the review
    Then I inspect those sources as well as the Org Reason lists
    And a completed checkbox is not treated as proof of that inspection

  @GTD09 @automated
  Scenario: Choose available work within the current context and time
    Given short and long computer actions and a call action
    And an action beneath a completed project
    When I choose computer work with fifteen minutes available
    Then the short computer action is shown
    And the longer action, call, and completed-project child are excluded

  @GTD10 @automated
  Scenario: Finish an interrupted clarification
    Given a complete project with a first next action was saved during clarification
    But removing the inbox copy failed
    When I retry the original disposition from the inbox
    Then the inbox copy is removed and the saved project remains with its first action

  @GTD11 @automated
  Scenario: Archive completed single actions
    Given a completed and an open action
    When I archive completed actions
    Then the completed action's ID resolves to its archived subtree
    And the open action remains available

  @GTD12 @automated
  Scenario: Capture and clarify in one step
    When I capture a thought and clarify it immediately
    Then the new entry is the one clarified
    And it appears once in the action system and not in the inbox

  @GTD13 @automated
  Scenario: Explain a clarification prompt
    Given I am answering a clarification prompt
    When I ask for help
    Then I see an explanation with examples for that prompt
