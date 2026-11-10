Feature: Reason in the actual Reason Commons model
  As a contributor to a commons
  I want an Emacs interface to the same canonical reasoning
  So claims, objections, and prior agreement remain inspectable

  @RC01 @automated
  Scenario: Capture a proposal with attribution
    When I add a node in a supported native tree family
    Then it has a stable native identity and an attributed contribution
    And it is proposed rather than accepted

  @RC02 @automated
  Scenario: Keep joint causes together
    Given two conditions and one effect in the same tree
    When I propose the two conditions together as contributing to the effect
    Then one relationship retains both source identities
    And they are not replaced by two independent sufficient causes

  @RC03 @automated
  Scenario: Require endorsed endpoints
    Given a proposed relationship with proposed endpoints
    When endorsement of the relationship is attempted
    Then it is refused until the endpoints are endorsed

  @RC04 @automated
  Scenario: Challenge an endorsed node
    Given an accepted node with an accepted incident relationship
    When I record a substantive challenge
    Then the node becomes disputed
    And that relationship returns to proposed
    And prior accepted revisions remain in history

  @RC05 @automated
  Scenario: Keep backlog separate from acceptance
    Given an accepted item
    When I add unresolved reasoning work to it
    Then it remains accepted
    And no new accepted semantic revision is invented for the backlog edit

  @RC06 @automated
  Scenario: Refuse a stale edit
    Given the canonical file changed after I inspected it
    When I attempt a mutation with the old digest
    Then the mutation is refused without overwriting the newer file

  @RC07 @automated
  Scenario: Refuse an invented schema interpretation
    Given an unfamiliar schema version or duplicated YAML mapping keys
    When I inspect the file
    Then validation fails without rewriting the file

  @RC08 @automated
  Scenario: Preserve optional structures
    Given optional metadata already in a valid commons
    When I add a proposed node
    Then that optional structure survives serialization

  @RC09 @automated
  Scenario: An assistant cannot endorse for a human
    Given a proposal attributed to assistant
    When assistant is supplied as the endorser
    Then no human acceptance is recorded

  @RC10 @automated
  Scenario: Navigate to a native item from Org
    Given a valid rc link to a native node
    When I follow it
    Then the derived view selects that canonical object's identity

  @RC11 @automated
  Scenario: Distinguish a saved edit from a rendering failure
    When valid YAML is saved but generating its views fails
    Then the result reports the successful save and the view error separately
    And a retry is not implied to be necessary to save the same contribution
