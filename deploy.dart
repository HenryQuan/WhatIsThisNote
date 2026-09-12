/// Build the Flutter web app and deploy it to Cloudflare Pages.
///
/// Run from anywhere (resolves its own location):
///   dart run deploy.dart                       # build + deploy to production
///   dart run deploy.dart --skip-build          # deploy the existing build/web
///   dart run deploy.dart --domain=note.tragichero.win --project=whatisthisnote
///
/// Auth is handled by wrangler, one time:
///   bunx wrangler login
///
/// The first deploy also needs the custom domain attached once in the
/// Cloudflare dashboard (Workers & Pages -> project -> Custom domains).
/// After that, every run of this script publishes straight to the domain.
library;

import 'dart:io';

/// Cloudflare Pages project name.
const defaultProject = 'whatisthisnote';

/// Git branch that maps to the production deployment.
const defaultBranch = 'main';

/// Custom domain the site should be served at.
const defaultDomain = 'note.tragichero.win';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);

  // Resolve paths from the script location, so it works from any cwd.
  final scriptDir = File.fromUri(Platform.script).parent; // repo root
  final appDir = Directory(
    '${scriptDir.path}${Platform.pathSeparator}whatisthisnote',
  );
  final buildWeb = Directory(
    '${appDir.path}${Platform.pathSeparator}build${Platform.pathSeparator}web',
  );

  if (!options.skipBuild) {
    stdout.writeln('== flutter build web --release');
    final code = await run('flutter', [
      'build',
      'web',
      '--release',
      '--no-wasm-dry-run',
    ], workingDirectory: appDir.path);
    if (code != 0) exit(code);
  } else if (!buildWeb.existsSync()) {
    stderr.writeln('No existing build at ${buildWeb.path}; drop --skip-build.');
    exit(1);
  }

  stdout.writeln('== wrangler pages deploy');
  final wrangler = _wranglerLauncher();
  final code = await run(wrangler.command, [
    ...wrangler.args,
    'pages',
    'deploy',
    buildWeb.path,
    '--project-name',
    options.project,
    '--branch',
    options.branch,
  ], workingDirectory: appDir.path);
  if (code != 0) exit(code);

  stdout.writeln('\nDeployed. Production URL: https://${options.domain}');
  stdout.writeln(
    '(one-time) If the domain is not live yet, add it in the Cloudflare '
    'dashboard: Workers & Pages -> ${options.project} -> Custom domains -> '
    '${options.domain}',
  );
}

class _Options {
  _Options({
    required this.project,
    required this.branch,
    required this.domain,
    required this.skipBuild,
  });

  final String project;
  final String branch;
  final String domain;
  final bool skipBuild;

  static _Options parse(List<String> args) {
    var project = Platform.environment['PAGES_PROJECT'] ?? defaultProject;
    var branch = Platform.environment['PAGES_BRANCH'] ?? defaultBranch;
    var domain = defaultDomain;
    var skipBuild = false;

    for (final arg in args) {
      if (arg == '--skip-build') {
        skipBuild = true;
      } else if (arg.startsWith('--project=')) {
        project = arg.substring('--project='.length);
      } else if (arg.startsWith('--branch=')) {
        branch = arg.substring('--branch='.length);
      } else if (arg.startsWith('--domain=')) {
        domain = arg.substring('--domain='.length);
      }
    }

    return _Options(
      project: project,
      branch: branch,
      domain: domain,
      skipBuild: skipBuild,
    );
  }
}

/// Picks the wrangler launcher: an explicit `WRANGLER` env override, then
/// `bunx wrangler`, falling back to `npx wrangler`.
({String command, List<String> args}) _wranglerLauncher() {
  final override = Platform.environment['WRANGLER'];
  if (override != null && override.isNotEmpty) {
    return (command: override, args: const []);
  }
  if (_onPath('bunx')) return (command: 'bunx', args: const ['wrangler']);
  if (_onPath('npx')) return (command: 'npx', args: const ['wrangler']);

  stderr.writeln(
    'Could not find bunx or npx. Install Bun (https://bun.sh) '
    'or Node.js, then run `bunx wrangler login` once.',
  );
  exit(1);
}

bool _onPath(String exe) {
  final result = Process.runSync(Platform.isWindows ? 'where' : 'which', [exe]);
  return result.exitCode == 0;
}

/// Run a command with inherited stdio (so wrangler stays interactive) and
/// return its exit code. Resolves .bat/.cmd wrappers on Windows (e.g. flutter).
Future<int> run(
  String cmd,
  List<String> args, {
  String? workingDirectory,
}) async {
  final launcher = Platform.isWindows ? 'cmd' : cmd;
  final launcherArgs = Platform.isWindows ? ['/c', cmd, ...args] : args;
  final process = await Process.start(
    launcher,
    launcherArgs,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}
