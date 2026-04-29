
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

