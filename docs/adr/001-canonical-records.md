# ADR 001: One canonical record per kind of object

Status: implemented in 0.1.0.

Reason Commons is the organizing discipline and canonical format for formal
reasoning. It is not forced to represent raw audio, a shopping reminder, or every
emotional experience. Those remain identified Org/media records and can connect
to formal reasoning when useful. This follows the conceptual-foundation option
in the supplied design conversation.

Org task state, object type, topic, origin, and epistemic status are separate
dimensions. Views do not duplicate reminders. Frozen forecasts preserve earlier
wording separately from the editable working note; accepted reasoning uses the
upstream history mechanism. No web-service synchronization is assumed.

Consequences: simple capture works without Python or a taxonomy. Formal logic
retains native AND relationships, attribution, challenge, and acceptance. There
are two local record formats, connected by explicit references. Plain file recovery
and coordination are documented; multiwriter transactions and automatic publication
are outside this release.
