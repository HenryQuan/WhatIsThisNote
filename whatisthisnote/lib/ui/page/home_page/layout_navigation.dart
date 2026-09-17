part of '../home_page.dart';

extension _HomeLayoutNavigation on _HomePageState {
  Widget _staffWithPanel(double width, Widget main, Widget panel) {
    final maxSidebarWidth = (width - 420).clamp(320.0, 820.0);
    final sidebarWidth = _sidebarWidth.clamp(280.0, maxSidebarWidth);
    return _withNavigation(
      width,
      Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: main),
          _SidebarResizer(
            onDrag: (dx) => _update(() {
              _sidebarWidth = (_sidebarWidth - dx).clamp(
                280.0,
                maxSidebarWidth,
              );
            }),
          ),
          SizedBox(width: sidebarWidth, child: panel),
        ],
      ),
    );
  }

  /// Wraps a destination's [content] with the right navigation for the window:
  /// a rail on the left when wide, a bottom bar on phones.
  Widget _withNavigation(double width, Widget content) {
    if (width >= _navRailBreakpoint) {
      return Row(
        children: [
          _navigationRail,
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: content),
        _navigationBar,
      ],
    );
  }

  /// Which activity the Practice tab is currently showing.
  _PracticeActivity get _activity => _guided
      ? _PracticeActivity.guided
      : _read
      ? _PracticeActivity.read
      : _PracticeActivity.quiz;

  void _setActivity(_PracticeActivity activity) {
    switch (activity) {
      case _PracticeActivity.quiz:
        _startPractice();
      case _PracticeActivity.guided:
        _startGuided();
      case _PracticeActivity.read:
        _startRead();
    }
  }

  /// The Practice / Guided path / Read & play switch above the practice tab.
  Widget get _practiceModeToggle => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<_PracticeActivity>(
        key: const Key('practice-mode-toggle'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: _PracticeActivity.quiz,
            label: Text(context.l10n.modePractice),
            icon: const Icon(Icons.quiz),
          ),
          ButtonSegment(
            value: _PracticeActivity.read,
            label: Text(context.l10n.modePlay),
            icon: const Icon(Icons.piano),
          ),
          ButtonSegment(
            value: _PracticeActivity.guided,
            label: Text(context.l10n.modeGuide),
            icon: const Icon(Icons.school),
          ),
        ],
        selected: {_activity},
        onSelectionChanged: (selection) => _setActivity(selection.first),
      ),
    ),
  );

  NavigationRail get _navigationRail => NavigationRail(
    selectedIndex: _tab.index,
    // Show the label under each icon on tablets and desktops, where there is
    // room for it; [minWidth] keeps the longest label from clipping.
    labelType: NavigationRailLabelType.all,
    minWidth: 88,
    onDestinationSelected: (index) => _selectTab(_HomeTab.values[index]),
    destinations: [
      for (final tab in _HomeTab.values)
        NavigationRailDestination(
          icon: Icon(tab.icon),
          label: Text(tab.label(context.l10n)),
        ),
    ],
  );

  NavigationBar get _navigationBar => NavigationBar(
    selectedIndex: _tab.index,
    onDestinationSelected: (index) => _selectTab(_HomeTab.values[index]),
    destinations: [
      for (final tab in _HomeTab.values)
        NavigationDestination(
          icon: Icon(tab.icon),
          label: tab.label(context.l10n),
          tooltip: tab.label(context.l10n),
        ),
    ],
  );
}
