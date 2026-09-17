part of '../home_page.dart';

extension _HomeLayout on _HomePageState {
  Widget _homeLayoutBuild(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _onShortcut,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.appTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(child: LayoutBuilder(builder: _buildResponsiveContent)),
      ),
    );
  }
}
