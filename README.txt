What do these scripts do?

They call the keeper battle log API end-point. The data returned is JSON and
represents a 'snapshot' of a game in progress. This data can be used to track
attendance. However, the data provides more information that might be
interesting to also track: commanders, people joining the server, squads,
scores, individual stats (score, kills, deaths). It also includes the ranks of
the soldiers.

Each call produces a new JSON payload.

I want to save this information in a database both structured and unstructured.

In the domain I defined, Game is the principal object. A Game has two Armies. A
Game has one Map. A Game also has other bits of information.

An Army has Squads. An Army has a Commander. An Army also has other bits of
information.

A Squad has Soldiers.

A Soldier has the following attributes: name, tag, rank, score, kills, deaths,
squad designator, and role designator.

From the 'Game' data, what is unique enough to allow me to know if the data is
new or just updated?

For GC Purposes, we have the added dimension where some rounds of sufficient
length are 'NOT LIVE' and shouldn't be tracked/counted. I don't know if I'll be
able to NOT record the data.

--------------------------------------------------------------------------------
random thoughts:

* a person's best map, worst map
* an army's best map, worst map

- other statistical analysis & reports
--------------------------------------------------------------------------------

The initial web app will display the data like the attendance report. I'll add
other features later.

Should I have a button that, when pressed, produces the Attendance Report and
uploads it to Gist?

Or, can the web app have another interface that lists all the battles it has
stored and, based on a selection, produce the report for the specified round?

This list, which would have to use the same 'unique' attributes used when
recording, would have to display Server-Map-Round_Length.


Utility Models (tables):

Maps, of the Battlefield 4 kind. I'm not sure but the keeper API end-point might
only support BF4 Servers. It is - I just tested it with a BF3 Server UUID.

Servers: A list of the servers, with name and UUID, the app will track.

--------------------------------------------------------------------------------
random thoughts:

* live scoreboard with an image for the selected map
--------------------------------------------------------------------------------

