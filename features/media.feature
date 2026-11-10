Feature: Preserve evidence before interpreting it
  As a person using audio and handwritten notes
  I want originals and interpretations kept separately
  So recognition errors do not silently become accepted evidence

  @MED01 @automated
  Scenario: Import and refile an original
    Given a local original file
    When I import it and clarify its capture as reference
    Then its preserved bytes match the recorded digest
    And the original media link remains usable after refiling
    And the source file remains in place

  @MED02 @automated
  Scenario: Attach machine interpretation
    Given a preserved original
    When machine text is attached as a transcript
    Then it is a separate version marked review pending
    And the original is unchanged

  @MED03 @manual
  Scenario: Record actual audio on the Mac
    Given I use my existing recorder
    When I export a recording and import it
    Then playback of the preserved original works in my local environment

  @MED04 @manual
  Scenario: Review real OCR or speech output
    Given I explicitly configured a local recognition backend
    When I run it on an original
    Then I check its language and fidelity against the original
    And only an explicit review action marks it human-reviewed

  @MED05 @automated
  Scenario: Capture asynchronous adapter output without replacing evidence
    Given a configured synthetic local recognition command
    When I explicitly run it on an imported original
    Then its standard output is preserved as a separate pending interpretation
    And the original digest is unchanged
