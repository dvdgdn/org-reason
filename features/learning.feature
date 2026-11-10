Feature: Let outcomes improve the next decision
  As a person learning from experience
  I want original expectations preserved alongside observations
  So I can revise my approach without rewriting what I predicted

  @LRN01 @automated
  Scenario: Preserve a prospective original
    Given I have drafted a prediction before observing its outcome
    When I freeze it and later record an outcome
    Then the original statement and probability remain unchanged
    And a second freeze cannot overwrite that snapshot

  @LRN02 @automated
  Scenario: Exclude retrospective forecasts from calibration
    Given one retrospective resolved event and one prospective unresolved event
    When I inspect calibration
    Then neither contributes a binary event score
    And the prospective unresolved event remains visible in the counts

  @LRN03 @automated
  Scenario: Link one result to the original
    Given a frozen prediction
    When I record its observations and next decision
    Then a result refers to that experiment's stable identity
    And a second programmatic result is refused rather than silently replacing it

  @LRN04 @manual
  Scenario: Practise with feedback and a transfer check
    Given I choose a specific component skill
    When I attempt a small challenge and obtain reliable feedback
    Then I can record an adjustment for the next repetition
    And a real-work transfer check is distinct from the practice score
