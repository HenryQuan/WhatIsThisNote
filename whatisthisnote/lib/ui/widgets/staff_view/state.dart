part of '../staff_view.dart';

class _StaffViewState extends State<StaffView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Tween<double>? _tween;

  /// Continuous staff position of the note.
  late double _currentStep;

  /// Horizontal centre of the note.
  double _noteX = -1;

  bool _dragging = false;

  /// Keeps the staff focusable so arrow keys can nudge the note on desktop.
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentStep = widget.step.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onTick);
  }

  void _onTick() {
    final tween = _tween;
    if (tween == null) return;
    setState(() => _currentStep = tween.evaluate(_controller));
  }

  @override
  void didUpdateWidget(covariant StaffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.step != oldWidget.step) {
      final target = widget.step.toDouble();
      if ((_currentStep - target).abs() > 0.001) {
        _animateTo(target);
      }
    }
  }

  void _animateTo(double target) {
    _controller.stop();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _currentStep = target);
      return;
    }
    _tween = Tween<double>(begin: _currentStep, end: target);
    _controller.forward(from: 0);
  }

  /// Moves the note by [delta] staff steps, clamped to the allowed range.
  void _nudge(int delta) {
    final target = (widget.step + delta).clamp(widget.minStep, widget.maxStep);
    if (target != widget.step) widget.onStepChanged(target);
  }

  /// Scientific name of the note at [step], used for the semantics
  /// `increasedValue`/`decreasedValue` that assistive tech announces.
  String _semanticNameAt(int step) {
    final clamped = step.clamp(widget.minStep, widget.maxStep);
    var note = widget.keySignature.applyTo(widget.clef.noteAt(clamped));
    if (clamped == widget.step && widget.accidental != null) {
      note = note.withAccidental(widget.accidental!);
    }
    return note.name;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _nudge(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _nudge(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPanStart(DragStartDetails details) {
    _dragging = true;
    _controller.stop();
  }

  void _onPanUpdate(StaffGeometry geometry, DragUpdateDetails details) {
    final next = geometry.clampStep(
      _currentStep - details.delta.dy / geometry.halfSpace,
    );
    setState(() {
      _currentStep = next;
      _noteX = _clampNoteX(geometry, _noteX + details.delta.dx);
    });
    final rounded = next.round();
    if (rounded != widget.step) {
      widget.onStepChanged(rounded);
    }
  }

  void _onPanEnd(StaffGeometry geometry) {
    _dragging = false;
    _animateTo(geometry.clampStep(_currentStep.round()));
  }

  void _onTapUp(StaffGeometry geometry, TapUpDetails details) {
    _dragging = false;
    _controller.stop();
    final target = geometry.clampStep(
      geometry.stepForY(details.localPosition.dy).round(),
    );
    setState(() {
      _noteX = _clampNoteX(geometry, details.localPosition.dx);
    });
    _animateTo(target);
    if (target.round() != widget.step) {
      widget.onStepChanged(target.round());
    }
  }

  /// Left-most x the note may occupy, leaving room for the clef and key
  /// signature.
  double _contentLeft(StaffGeometry geometry) {
    final clefRight =
        geometry.staffLeft + (0.15 + widget.clef.advance) * geometry.space;
    final signatureWidth = widget.keySignature.signatureCount == 0
        ? 0.0
        : geometry.space * 0.2 +
              widget.keySignature.signatureCount * geometry.space * 0.9;
    return clefRight + signatureWidth + geometry.space * 0.9;
  }

  double _clampNoteX(StaffGeometry geometry, double x) {
    final lo = _contentLeft(geometry);
    final hi = geometry.staffRight - geometry.space * 0.6;
    if (lo >= hi) return geometry.size.width / 2;
    return x.clamp(lo, hi);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = StaffGeometry.forSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        if (_noteX < 0) {
          _noteX = (_contentLeft(geometry) + geometry.staffRight) / 2;
        }
        _noteX = _clampNoteX(geometry, _noteX);

        final scheme = Theme.of(context).colorScheme;
        final l10n = context.l10n;
        final staff = RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: NotationPainter(
              geometry: geometry,
              clef: widget.clef,
              key: widget.keySignature,
              step: _currentStep,
              noteX: _noteX,
              lineColor: scheme.onSurface.withValues(alpha: 0.85),
              noteColor: scheme.primary,
              labelColor: scheme.primary,
              labelBackgroundColor: scheme.surface,
              showLabel: widget.showLabel,
              naming: widget.naming,
              showEnharmonic: widget.showEnharmonic,
              solfegeName: l10n.solfegeFor,
              chordTones: widget.chordTones,
              chordColor: scheme.tertiary,
              targetStep: widget.targetStep,
              targetAccidental: widget.targetAccidental,
              accidental: widget.accidental,
              targetColor: scheme.outline,
              melodySteps: widget.melodySteps,
              melodyIndex: widget.melodyIndex,
              melodyActiveColor: scheme.tertiary,
            ),
          ),
        );
        if (!widget.interactive) {
          return Semantics(
            image: true,
            label: widget.semanticValue == null
                ? l10n.noteStaff
                : l10n.noteStaffValue(widget.semanticValue!),
            child: staff,
          );
        }
        final value = widget.semanticValue;
        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _onKeyEvent,
          child: Semantics(
            container: true,
            label: l10n.noteStaff,
            value: value,
            increasedValue: value == null
                ? null
                : _semanticNameAt(widget.step + 1),
            decreasedValue: value == null
                ? null
                : _semanticNameAt(widget.step - 1),
            hint: l10n.staffHint,
            onIncrease: value == null ? null : () => _nudge(1),
            onDecrease: value == null ? null : () => _nudge(-1),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _focusNode.requestFocus(),
              onPanStart: (details) {
                _focusNode.requestFocus();
                _onPanStart(details);
              },
              onPanUpdate: (details) => _onPanUpdate(geometry, details),
              onPanEnd: (_) => _onPanEnd(geometry),
              onTapUp: (details) => _onTapUp(geometry, details),
              child: staff,
            ),
          ),
        );
      },
    );
  }
}


