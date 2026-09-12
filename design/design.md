# Drawing lines
- Line
    * LongLine
    * ShortLine

We need to draw 5 long lines for the notation and extra short lines if the note is too high or too low. 
Line needs to provide functions to get x value and do some basic calculations. 

# Drawing notes
What should be used? Maybe some images?

# Get the sound of the note
This can be done by using axis.

# Responsive
The distance between lines should be calculated based on screen size and be constant (based on the height, longer side)

# Animation
It should be really smooth and the note should snap to the closest position. There will be also two labels. 

# Paid features
- Quiz
- Dark mode

# Upcoming features
- How to read notes

# UX roadmap (review Sep 2026, ordered by learner impact)
1. Practice / quiz mode (separate mode): hide the answer, drill note
   recognition, with real feedback and a score/streak. Serves beginners
   (self-test) and pros (speed).
2. Audio: play the note/chord so symbol -> sound is learnable. Done: a
   pure-Dart tone synthesizer feeds `audioplayers` (Android, iOS, web,
   Windows, macOS, Linux); the play button sounds the note or current chord.
3. Display preferences: naming system (scientific / solfege / jianpu),
   on-staff name label toggle, enharmonic twin (F# ~ Gb). Done: a Display
   bottom sheet; the naming choice drives the readout and the on-staff label
   (practice answers stay scientific). Preferences are saved with
   `shared_preferences` behind a `DisplayPreferencesStore` (tests use an
   in-memory fake) and restored on start.
4. First-run onboarding: one-time coach mark for "drag up/down" and "tap a
   line". Done: a dismissible card over the staff; the "seen" flag is kept in
   `shared_preferences` (Android, iOS, web, Windows, macOS, Linux) behind an
   `OnboardingStore` that tests replace with an in-memory fake. The card body
   ignores pointers so it never blocks the drag it is teaching; only its
   "Got it" button takes taps.
5. Guided-path feedback: "higher/lower" hint on wrong drags, remember
   progress, "practice again".
6. Accessibility & pro conveniences. Done: the staff is a labelled Semantics
   node whose value is the note (null while practising so the answer is not
   announced), with increase/decrease actions and matching
   `increasedValue`/`decreasedValue`; the readout is a live region. Arrow
   keys nudge the note on desktop, and `MediaQuery.disableAnimations` makes
   the snap instant so "reduce motion" is respected.

## Layout stability
The staff is the flexible child, so it fills whatever space the controls
leave and the controls never need to scroll on a normal window. To keep the
staff from resizing (and the note from jumping) mid-drag, nothing in the panel
may change height as the note changes: the note readout uses a single-line
row instead of a wrapping `Wrap`, and the guided status is clipped to one
line. The staff size therefore depends only on the window, and the drag stays
stable and smooth. (An earlier attempt gave the staff a fixed share of the
screen; it was reverted because it forced the controls to scroll.)
