
## Round 1

Q1:

b) it is synonymous with the websocket connection. Every new websocket
connection gets a new sentinel id. (The websocket connection is the sentinel)


Q2:

it's a little bit of b and c. I do not want our software to fail in the case
that a computer fails and the student has to use another one. The experience
should also be flawless - the student does not have to do anything and just logs
in as if the test just started and the teacher doesn't have to do anything.

I already serve sentinel status like disconnected etc. so the teacher will be
informed for a sentinel disconnect.


Followup: The session should just continue and be one single video (i will store
the breakup internally and show it on the timeline etc.)


## Round 2


Q3:

The teacher watches live and should have the option to watch it after again. The
video should only be associated to a student.

The live view is the selling point of our product so the new stream should
attach just fine.

I also currently don't have a subscription model as a scraped it and just have
the sentinel part of the new model.

Q4:

Saved on a single server on disk.


Q5:

This is a large point which i have thought about many times but haven't come up
with a concrete solution yet.

I am not sure if i am locking the session to the exam status like a start. i am
also not sure if the exam should have a preparation phase and outside of
preparation phase and running phase, students aren't allowed to make a session
with the exam. this was the closest thing as the teacher can see all the
students bevore starting the exam. Streams should start like 5 minutes bevore
exam starts etc so the actual flow extends beyond the running exam.

If the teacher end the exam though, sentinel session is invalidated and the
sentinel is not allowed to be connected anymore.

I am not sure how to define this preparation phase as there will be problems if
teachers are not sticking to the fixed schedule. we currently have a schedule
start and end but also store the startedAt and endedAt values.

The are also different kinds of teachers, one would like to manage everything
manually and want to have control but other teachers are not that smart and
every extra interaction that seems unnecessary, is like a burden so a start
preparation phase button sounds weird. Maybe a big information like "allow
students to join" and pre preparation phase the exam has a note that students
currently can't join etc.

You can see my thought process ping ponging between stuff so i need you to
research or propose a nice structured idea so we can build upon that.

The subquestion: Because the main thing isn't even defined conretely, i just
want students to be allowed to leave early without the teacher having to
explicitly aprove it. The Live session for the teacher is rather just an
informational thing and they will be informed of the leave anyways. what would
be nice though would be like a kick so the student can't connect anymore and
clutter the session.

### Round 3

Q6:

in the previous websocket protocol i just forwarded the stream on the websocket
connection. the new protocol has two websockets, one control and the other data
to not block responsive control flow via large data. I will handle it with a
subscription model again somehow but a more robust one where "control"
subscribes and over "data" a stream is sent.


Q7:

So i think the storage layout doesn't really matter because i will support that
the sentinel sends multiple streams like on extremely fast and low quality live
stream, another stream for just persistence and then archival viewing with 2
second segments. Some streams will have persistence support on the server and
will get persisted, archival viewing will also not run over websockets but
somethine else entirely which we do not discuss here. The only thing that is
important is live encoding where i will use fmp4 for.

For the persistence stream each segment would be its own file (when live
streaming we create 2s seconds with a iframe only when a new viewer wants to
join). The live is not persisted.


## Round 4 PRE correction

A correction on the archival part. The livestream is correct.

For archiving we send a 2s per segment high quality stream where each segment is
its own file so i am open to use DASH or something alike to just have it
available for preview later.

## Round 4

Q8:

For live applications, the subscription should still exist.

So we have to make a decision now. I originally wanted to work on sentinel alone
but there seem to be some proctor related things too so now just add proctor too.

For proctor a session is a single websocket connection that lives and dies with
the proctor websocket connection. On destroy a completely new one has to be
built with new subscriptions etc. A proctor also only registers to a single exam
to proctor.

What my plan is to make subscriptions per student (session) and not sentinel id.
The proctor then receives stream source signals from the server like:

Proctor subscibes to student a.
Server has nothing yet.

Student a logs in.
Server pushes to proctor: open a new stream (with streamID) for subscription to
student A.

The proctor can now expect to be getting a stream on the "data" socket with the
provided streamID.

When the student disconnects, the stream is closed with maybe some abort
message.

So the students are always the same for an exam session but do not hard enforce
that because students should be able to join anytime during the test still.

The proctor can also subscribe to specific streams like 480p, 720p, which is
then changed dynamically on the sentinel side.

Multiple proctors are allowed to proctor the same exam.

Final answer for Q8: Proctor tears down MSE and just shows some fallback graphic
or svg but the student stays the same. The only deciding factor is the existance
of the stream. The subscription will stay, the students existance will stay
unless the student should be marked as left.

Q9:

I am unsure if i should save each segment to the db because i am not sure if
this is information we have to persist. It would be faster to have the last 1
minute of a stream just in memory and serve to demanding proctors until sentinel
serves a stream.

Persisted streams would have their own management but that is out of scope.

## Round 5

Q10:

That is a big important thing for us because we do things lazily. If a proctor
joins we send the saved init segment of the whole stream, then tell sentinel to
produce a stream with the given requirements that proctor wants. If sentinel is
already doing that stream server will issue and entrypoint and sentinel inserts
an iframe and starts a new segment. that segment and everything after it will be
sent to proctor.

For the related question: Sentinel is streaming 480p and gets a request to
stream 720p, then sentinel will just open an extra stream. If it is already open
then server knows this in the list of streams for the designated sentinel and
just issues an iframe segment for a new proctor to attach to.


Q11:

I want to defer this because that logic would be simple to add and has nothing
to do with the proctor sentinel server flow itself.
