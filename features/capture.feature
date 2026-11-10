Feature: Capture attention before classifying it
  As a person interrupted by a thought or an external source
  I want a safe, quick inbox
  So I can return to the work and clarify later

  @CAP01 @automated
  Scenario: Capture without a taxonomy
    Given a new Org Reason workspace
    When I capture a short thought
    Then it has a stable identity and capture provenance
    And no topic, object type, or next action is required

  @CAP02 @automated
  Scenario: Add the package to an existing capture setup
    Given template r and a browser protocol already exist
    When I enable and disable Org Reason
    Then those existing entries remain unchanged

  @CAP03 @automated
  Scenario: Use ordinary Org capture
    Given the Org Reason capture template was installed
    When I fill and finalize it through Org capture
    Then one identified entry appears in the inbox

  @CAP04 @automated
  Scenario: Repeat drop imports safely
    Given an original file in the drop directory
    When I import the directory twice
    Then the content is captured once
    And the source file remains in place

  @CAP05 @manual
  Scenario: Deliver a browser selection through the operating system
    Given a working macOS org-protocol handler
    When I explicitly click the Org Reason bookmarklet
    Then the selected text and source URL appear in the Org Reason inbox
    And legacy bookmarklets retain their configured destinations
