import 'dart:ui';

/// Lowest staff step the user can drag to (three ledger lines below).
const int kMinStaffStep = -6;

/// Highest staff step the user can drag to (three ledger lines above).
const int kMaxStaffStep = 14;

/// Immutable geometry for a five line staff.
///
/// Staff positions are measured in *steps*, where one step is half the
/// distance between two adjacent staff lines. Step `0` is the bottom line,
/// step `8` is the top line, even steps are lines and odd steps are spaces.
class StaffGeometry {
  const StaffGeometry({
    required this.size,
    required this.space,
    required this.staffLeft,
    required this.staffRight,
    this.minStep = kMinStaffStep,
    this.maxStep = kMaxStaffStep,
  });

  /// Builds responsive geometry: the line spacing scales with the available
  /// height but is clamped so the staff stays readable on any screen.
  factory StaffGeometry.forSize(Size size) {
    final space = (size.height / 15).clamp(8.0, 40.0);
    final margin = (size.width * 0.06).clamp(12.0, 64.0);
    return StaffGeometry(
      size: size,
      space: space,
      staffLeft: margin,
      staffRight: size.width - margin,
    );
  }

  final Size size;

  /// Distance between two adjacent staff lines (one staff space).
  final double space;

  final double staffLeft;
  final double staffRight;

  /// Lowest step the user can drag to (three ledger lines below the staff).
  final int minStep;

  /// Highest step the user can drag to (three ledger lines above the staff).
  final int maxStep;

  /// Half a staff space: the vertical distance of one step.
  double get halfSpace => space / 2;

  /// The step that is vertically centred in the viewport.
  double get centerStep => (minStep + maxStep) / 2;

  double get centerY => size.height / 2;

  /// The y coordinate of [step].
  double yForStep(num step) => centerY - (step - centerStep) * halfSpace;

  /// The (fractional) step at the given y coordinate.
  double stepForY(double y) => centerStep + (centerY - y) / halfSpace;

  /// Clamps a fractional step to the draggable range.
  double clampStep(num step) => step.clamp(minStep, maxStep).toDouble();

  /// The y coordinate of the bottom staff line.
  double get bottomLineY => yForStep(0);

  /// The y coordinate of the top staff line.
  double get topLineY => yForStep(8);

  /// True when [step] falls on a staff line (rather than a space).
  static bool isLine(num step) => step.round() % 2 == 0;

  /// Ledger lines required to write a note at [step].
  ///
  /// Staff lines occupy steps `0, 2, 4, 6, 8`. A note in the space just outside
  /// the staff needs no ledger line, but every line position beyond the staff
  /// up to (and including) the note does.
  List<int> ledgerStepsFor(int step) {
    final result = <int>[];
    if (step >= 10) {
      for (var s = 10; s <= step; s += 2) {
        result.add(s);
      }
    } else if (step <= -2) {
      for (var s = -2; s >= step; s -= 2) {
        result.add(s);
      }
    }
    return result;
  }
}
