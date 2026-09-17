import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/note_player.dart';
import '../../core/accidental.dart';
import '../../core/chord.dart';
import '../../core/chord_finder.dart';
import '../../core/chord_service.dart';
import '../../core/clef.dart';
import '../../core/display_preferences.dart';
import '../../core/key.dart';
import '../../core/lesson.dart';
import '../../core/melody.dart';
import '../../core/metronome.dart';
import '../../core/note.dart';
import '../../core/quiz.dart';
import '../../core/scale.dart';
import '../../core/staff_geometry.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../widgets/about_panel.dart';
import '../widgets/chord_builder_panel.dart';
import '../widgets/metronome_panel.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/section_heading.dart';
import '../widgets/staff_view.dart';
part 'home_page/playback.dart';
part 'home_page/chord_lab.dart';
part 'home_page/activities.dart';
part 'home_page/metronome.dart';
part 'home_page/builder.dart';
part 'home_page/layout.dart';
part 'home_page/layout_content.dart';
part 'home_page/layout_navigation.dart';
part 'home_page/layout_panel.dart';
part 'home_page/navigation_widgets.dart';
part 'home_page/guided_panel.dart';
part 'home_page/practice_panel.dart';
part 'home_page/read_panel.dart';
part 'home_page/small_widgets.dart';
part 'home_page/controls.dart';
part 'home_page/controls_body.dart';
part 'home_page/key_scale_selectors.dart';
part 'home_page/chord_selectors.dart';
part 'home_page/progression_selector.dart';
part 'home_page/chord_readout.dart';

/// The two kinds of note sequence that can be played automatically.
enum _Playback { highlight, progression }

/// The activities inside the Practice tab.
enum _PracticeActivity { quiz, guided, read }

/// How long each note of a sequence rings, and how long to wait before the
/// next one starts. The gap is a little longer than the sound so the notes
/// stay distinct.
const Duration _sequenceNoteDuration = Duration(milliseconds: 340);
const Duration _sequenceStepGap = Duration(milliseconds: 420);

/// Window width at or above which the destinations move to a left rail; below
/// it they are a bottom bar, so phones keep their width for the staff.
const double _navRailBreakpoint = 900;

/// Most notes the custom chord builder lets the learner stack.
const int _maxBuilderNotes = 8;

/// Pitch of the metronome's accented downbeat and of the other beats, in hertz.
const double _clickAccentHz = 1318.51;
const double _clickBeatHz = 880.0;

/// Top-level destinations of the app.
enum _HomeTab { note, practice, metronome, chords, about }

extension on _HomeTab {
  String label(AppLocalizations l10n) => switch (this) {
    _HomeTab.note => l10n.tabNote,
    _HomeTab.practice => l10n.tabPractice,
    _HomeTab.metronome => l10n.tabMetronome,
    _HomeTab.chords => l10n.tabChords,
    _HomeTab.about => l10n.tabAbout,
  };

  IconData get icon => switch (this) {
    _HomeTab.note => Icons.music_note,
    _HomeTab.practice => Icons.quiz,
    _HomeTab.metronome => Icons.av_timer,
    _HomeTab.chords => Icons.queue_music,
    _HomeTab.about => Icons.info_outline,
  };
}

/// The main screen: an interactive staff plus controls for the clef, the key,
/// an optional scale highlight, the note position and the theme.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.display,
    required this.onDisplayChanged,
    this.notePlayer,
    this.showCoachMark = false,
    this.onCoachMarkDismissed,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DisplayPreferences display;
  final ValueChanged<DisplayPreferences> onDisplayChanged;

  /// Overrides the audio player, used by tests to avoid the native plugin.
  final NotePlayer? notePlayer;

  /// Whether to show the one-time first-run coach mark over the staff.
  final bool showCoachMark;

  /// Called when the learner dismisses the coach mark.
  final VoidCallback? onCoachMarkDismissed;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Clef _clef = Clef.treble;
  MusicalKey _key = kMajorKeys.first;

  /// Optional scale highlight (an add-on), off by default.
  ScaleType? _scaleType;

  /// Optional chord lab (an add-on), off by default.
  ChordMode _chordMode = ChordMode.off;
  int _inversion = 0;
  ChordProgression? _progression;

  /// A specific chord picked from the readout, overriding the diatonic chord.
  ChordQuality? _chordQuality;

  /// Optional guided theory path (an add-on), off by default.
  bool _guided = false;
  int _lessonIndex = 0;
  int _stepIndex = 0;

  /// Optional practice mode (name-the-note quiz), off by default.
  bool _practice = false;
  QuizBuilder? _quizBuilder;
  QuizQuestion? _question;
  String? _answered;
  int _attempts = 0;
  int _correctAnswers = 0;
  int _streak = 0;
  int _bestStreak = 0;

  /// Optional read-and-play mode (a random phrase played back on the
  /// keyboard), off by default.
  bool _read = false;
  MelodyBuilder? _melodyBuilder;
  Melody? _melody;
  int _melodyIndex = 0;
  bool _melodyMistake = false;
  bool _melodyDone = false;

  /// Middle line of the treble staff (B4).
  int _step = 4;

  /// The destination currently shown.
  _HomeTab _tab = _HomeTab.note;

  /// Width of the wide-layout controls rail, dragged by the user.
  double _sidebarWidth = 380;

  /// Metronome tempo (beats per minute) and whether the click is running. The
  /// sounding beat is a notifier so a tick repaints only the beat dots instead
  /// of rebuilding the whole page, which keeps the click visually smooth.
  int _bpm = 90;
  int _beatsPerBar = kBeatsPerBar;
  bool _metronomeOn = false;
  final ValueNotifier<int> _beat = ValueNotifier<int>(0);
  Timer? _metronomeTimer;
  Timer? _bpmRestartTimer;

  /// When the last beat sounded, used to schedule the next one against a fixed
  /// timeline so rounding and frame time never make the tempo drift.
  DateTime? _lastBeatAt;

  /// Register finder selection (a pitch class and an octave) plus its looping
  /// and sweeping playback.
  int _registerPitchClass = 0;
  int _registerZone = 4;
  bool _registerLooping = false;
  bool _registerSweeping = false;
  Timer? _registerTimer;
  int _registerToken = 0;

  /// The custom chord being built, in the order notes were added, and which
  /// note is selected (also the suggested root).
  final List<Note> _builderNotes = [];
  int? _builderSelected;

  /// The suggested chord the learner tapped, highlighted on the staff.
  ChordMatch? _builderMatch;

  /// The sequence currently playing automatically, if any, and which note of
  /// it is sounding. [_playbackToken] invalidates in-flight timer callbacks
  /// when a sequence is stopped or replaced.
  _Playback? _playback;
  int? _playbackIndex;
  int _playbackToken = 0;
  Timer? _playbackTimer;

  /// Invalidates an in-flight read-and-play phrase playback, so a new phrase,
  /// an exit or a tapped key stops the notes still queued behind it.
  int _melodyToken = 0;

  void _setStep(int step) {
    setState(() => _step = clampStaffStep(step));
  }

  /// Keeps state updates in the main State class while feature code lives in
  /// the smaller part files.
  void _update(VoidCallback update) => setState(update);

  /// Created on first use so tests that inject a player never touch the plugin.
  NotePlayer? _ownedPlayer;
  NotePlayer get _notePlayer =>
      widget.notePlayer ?? (_ownedPlayer ??= AudioNotePlayer());

  /// Folds a note's MIDI into the keyboard's C4-C5 range.
  static int _keyboardMidiFor(int midi) {
    final pitchClass = midi % 12;
    if (pitchClass != 0) return 60 + pitchClass;
    return midi >= 72 ? 72 : 60;
  }

  /// Whether [note] is a C that belongs on the keyboard's upper C key.
  static bool _isUpperOctaveC(Note? note) =>
      note != null && note.midi % 12 == 0 && note.midi >= 72;

  /// Catches app-wide keyboard shortcuts (arrow keys, space) that bubble up
  /// from the focused control.
  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'home-shortcuts');

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _playbackTimer?.cancel();
    _playbackToken++;
    _metronomeTimer?.cancel();
    _bpmRestartTimer?.cancel();
    _beat.dispose();
    _registerTimer?.cancel();
    _ownedPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _homeLayoutBuild(context);
}
