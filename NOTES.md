Notes on the @birthdaynoc Project
=================================

(this is just a random scratchpad of personal notes; i am deeply
sorry of it makes little to no sense to anyone else.)

The Tweets
----------

On its own timeline, @birthdaynoc tweets messages like this:

    Happy 24th birthday to 172.15.14.0/24!

Twitter users can DM the bot with messages like:

    When was 1.2.3.4 born?

and

    How old is 1.2.3.4?

and get replies like:

    1.2.3.4 (and the rest of 1.2.3.0/24) was born on
    January 17th, 1987, in the Netherlands!

and

    1.2.3.4 (just like everyone else in 1.2.3.0/24) turns 34
    next January (on the 17th)!

Components
----------

The **writer** takes the source data (subnets and their birth
dates) and composes tweets, according to a context-free grammar
run in reverse.  The writer then stores these tweets in a
key-value store, indexed by the date, for easy retrieval by the
scheduler.

The writer is also responsible for listening to incoming requests
for tweets, via the message bus, and responding to them.

Because timing isn't a hard requirement, we can do all of this
work in a single thread that operates in two modes: initially the
backlog of writing is done to fill out the key-value store with
scheduled messages, and then the bot starts responding to tweet
requests that have come in.  For safety, we will assess a
"freshness" check to the latter, to ensure that the bot doesn't
respond to a message from days or weeks ago.

The writer is written in _Perl_, for its text-processing
capabilities.

The **bot** is responsible for integrating with Twitter API.
It reads outgoing status updates and replies off of one message
queue, posting them to Twitter, and writes incoming direct
messages to a different queue.  It's really a router that
understands status updates and direct messages.

The bot is written in _Go_, for the coroutine / threading support.
It can use <https://github.com/dghubble/go-twitter>.

The **scheduler** watches the clock, knows the date, and randomly
selects a pre-written message from the key-value store at specific
intervals.  It then posts those messages through the mbus to the
bot, for status posting.

The scheduler is written in _Rust_, using redis-rs to talk to
the message bus / key-value store.  It cannot be scaled.

The **website** is a static HTTP(s) application that gives out
information about the bot, it's purpose and creators, etc.  It
also provides some stats, drawn live from the key-value store,
about number of subnets, wishes wished so far, etc. for interested
parties.

The website is written in _Node_, for the Vue integration.

Message Grammar(s)
------------------

There are two grammars: one for the scheduled status updates
(unbiddenn wishes of happy birthdays), and another for responses
to direct message queries.

Status Updates:

    Happy birthday to 

    tweet := <wish> sp <hashtags>
    wish := <greeting>, <birth>
    greeting := <verb> to $subnet <clarifier> <followup>
    verb := "wishing a " <adj> <bday> " to"
          | "sending " <adj> <bday> " wishes to"
          | <adj> <bday> " to"
          | "a " <adj> <bday> " to"
          ;
    adj := "happy"
         | "joyous"
         | "splendid"
         ;
    bday := "birthday"
          | "bday"
          | "b-day"
          | "cake day"
          | "🎂 day"
          ;
    clarifier := nil
               | "(and all" $n <ip-plural> "in it)"
               | "(and all of its" $n <ip-plural> ")"
               ;
    ip-plural := "ips"
               | "addresses"
               ;

    followup := nil
              | "." <age-today>
              | ";" <born-today>
              ;

    age-today := "it turns" $years "old today!"
               | "celebrating" $years "years in" $location
               | "celebrating" $years "years"
               | "happy" ord($years) "!"
               | "you only get to turn" $years "old once!"
               ;

Direct Messsages come in a few varieties: (a) random wish on a
specific day, (b) age of a specific IP or subnet, and (c) birth
date of a specific IP or subnet.

    top := choose(a, b, c)
    a := "today," $subnet " (and its" $n <ip-plural^>) turns " $years
      ;

    b := <subject> "is" $years "old."
      ;
    subject := $ip "(in" $subnet ")"
             | $subnet
             ;

    c := <subject> "turns" $years "old" <when> <followup>
       | <subject> "will turn" $years <when> <followup>
       ;
    when := "on" $month $day "of next year"
          | "on the" ord($day) "of next" $month
          | "next" $month ord($day)
          ;

    followup := nil
              | "." <mark-calendars>
              ;

    mark-calendars := "mark your calendar!"
                    | "save the date!"
                    | "better buy your gifts now..."
                    ;

Over time, I expect these grammars to morph and expand.  As we
descend into the grammar to build a sentence, we need to be able
to do two things: eliminate branches that have data requirements
and randomly choose from the remaining weighted alternatives.
This needs to be encoded in the AST that we build to represent the
CFG.

A sketch of a syntax for the grammars:

    _ : <production> "literal" STOP
      ;

    production : ~     [5%]
               | "a"   [30%]
               | "the" [30%]
               | "this" $thing
               | "that" <thing>
               ;

     thing : "special" uc($thing)
           | "normal"  lc($thing)
           ;

In this example, we have a grammar that always ens with the word
"literal" and a full stop (usually, a period: '.'), signified by
the token 'STOP'.

When generating the first expansion, <production>, the grammar
needs to recurse into the next definition and perform branch
elimination and weighted branch selection.  The first step is
carried out based on the data requirements of each branch and the
supplied parmaeters to the generator.  The first (~), second ("a")
and third ("the") branches do not have any data requirements, so
they pass through selection as viable branches.  The next two
branches depend on the parameter `thing`; the first does so
explicitly and the second does so implicitly through percolated
requirements.

Having eliminated the branches that depend on data we don't have
access to, the weighted random selection begins.  The branches
that remain have weights of 5%, 30%, and 30%; these need to be
scaled up to a total of 100%, so we get 5% → 7.7%, and both 30% →
46.15%.  We then select a number between 0 and 100, randomly, and
choose the appropriate branch.

(Realistically, we don't "scale" the weights up, we scale down the
ceiling of our random scope.  In the above example, we choose
anumber between 0 and 65 (since 5 + 30 + 30 = 65), and select
accordingly.)

Having chosen a branch, we recursively resolve the literals,
references, and productions until we finish.

If we _did_ have the `thing` parameter, the generator would have
selected across all branches, assigning #4 and #5 equal weights of
17.5% each).  If the fourth branch was selected, the ensuring
resolution would use the literal value of the `thing` parameter
as-is.  However, if #5 (a close to 1-in-5 chance) were selected,
the ensuing recursive resolution of the <thing> production runs
into a 50/50 choice between two functional value references:

    uc($thing)

and

    lc($thing)

This syntax, `f(x)` is a code-wise functional transformation of a
single input to a single output.  It is currently illegal to pass
multiple arguments to such a function.  It is also therefore
illegal to pass a production (at this time), so this doesn't work:

    foo : f(<bar>) ;
    bar : $BAR | $BAZ ;

Instead, you would have to manually distribute the function call:

    foo : f($BAR)
        | f($BAZ)
        ;

This is considered to be of minor inconvenience to the grammar
writer, and a major boon to the generator implementation, in terms
of reduced complexity.

The following functions are defined:

    - uc(s) - Uppercase a string value
    - lc(s) - Lowercase a string value
    - cap(s) - Capitalize the first letter in a string value
    - ord(n) - Treating `n` as a stringified integer, append the
      appropriate ordinal suffix (-th, -nd, -rd, or -st).

Others may be added as time marches on and new needs arise.

Redis Schema
------------

We use Redis to keep track of ephemeral data that can easily be
reconstituted from the source data.  The writer process is chiefly
responsible for populating the key-value store with queued
messages to be sent out, keyed by birth date.

    RPUSH "on:0125" "Warm wishes to 17.0.0.0/8!"
    RPUSH "on:0125" "Happy Birthday to 142.56.17.0/24!"

etc.

The writer's goal is to maintain coverage for the wole year,
starting at today's date and working outward.  It does so by
formulating the key based on each successive date (`on:MMDD`), and
then checking LLEN.  If the size of the list falls below a
specific threshold, the writer replenishes it with new random
messages, based on source data, until a sufficient number of items
does exist.

The bot front-end then can indiscriminately ask for (and then
LREM) messages based on the date it is interested in.  The main
event loop (tweeting out birthday wishes) runs on a timer and uses
the current date.  The direct message handler, on the other hand,
parses requested dates and requests those.

Are SETs a better fit?

Consider for a moment the following set of commands from the
writer (pseudo code):

    writer:
      while SCARD("on:0125") < 25
        SADD "on:0125" generate(1,25)

    bot:
      tweet(SRANDMEMBER "on:0125")

This allows the writer to do its job on a slower schedule, either
opting to never clear out the set or to do so on its own
timescale, regardless of what the bot actor is doing (via main or
DM loops).
