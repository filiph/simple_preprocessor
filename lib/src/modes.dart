part of simple_preprocessor;


abstract class _SourceMode {
  final LineScanner scanner;
  final StringSink output;

  int lineStart;

  _SourceMode(this.scanner, this.output);

  String get name;
  bool canEnterWhileIn(_SourceMode otherMode);
  bool process();

  operator==(_SourceMode other) => this.name == other.name;
}

class _NormalMode extends _SourceMode {
  final RegExp _notSlash = new RegExp(r"[^/]+");
  final RegExp _slash = new RegExp(r"/+");
//  final RegExp _any = new RegExp(r".");

  _NormalMode(LineScanner scanner, StringSink output) : super(scanner, output);

  String name = "normal";
  bool canEnterWhileIn(_SourceMode otherMode) {
    return false;  // Normal mode can never take over.
  }

  bool process() {
    if (scanner.scan("/")) output.write(scanner.lastMatch.group(0));
    if (scanner.scan(_notSlash)) output.write(scanner.lastMatch.group(0));
    return true;
  }
}

class _IfMode extends _SourceMode {
  static final RegExp _enterIfMultiline =
  new RegExp(r"/\*\s*#if\s+([A-Z0-9_]+)\s*\*/(/\*)?\n?", multiLine: true);
  static final RegExp _exitIfMultiline =
  new RegExp(r"(\*/)?/\*\s*#endif\s*\*/\n?", multiLine: true);

  static final RegExp _enterIfSingleLine =
  new RegExp(r"//+\s*#if\s+([A-Z0-9_]+)\s*\n", multiLine: false);
  static final RegExp _exitIfSingleLine =
  new RegExp(r"//+\s*#endif\s*\n", multiLine: false);

  final RegExp _notSlashOrAsterisk = new RegExp(r"[^/\*]+");
  final RegExp _slashOrAsterisk = new RegExp(r"[/\*]+");

  final String buildMode;
  String currentSourceMode;

  _IfMode(LineScanner scanner, StringSink output, this.buildMode)
  : super(scanner, output);

  String name = "if";

  bool canEnterWhileIn(_SourceMode otherMode) {
    if (otherMode is! _NormalMode) return false;

    if (scanner.scan(_enterIfMultiline)) {
      currentSourceMode = scanner.lastMatch.group(1);
      return true;
    }

    if (scanner.scan(_enterIfSingleLine)) {
      currentSourceMode = scanner.lastMatch.group(1);
      return true;
    }
    return false;
  }

  bool get matchesMode => currentSourceMode == buildMode.toUpperCase();

  process() {
    if (scanner.scan(_exitIfMultiline) ||
    scanner.scan(_exitIfSingleLine)) {
      currentSourceMode = null;
      return false;
    }
    if (scanner.scan(_slashOrAsterisk) && matchesMode) {
      output.write(scanner.lastMatch.group(0));
    }
    scanner.scan(_notSlashOrAsterisk);
    if (matchesMode) output.write(scanner.lastMatch.group(0));
    return true;
  }
}

class _ElseMode extends _IfMode {
  static final RegExp _enterElseMultiline =
  new RegExp(r"(\*/)?/\*\s*#else\s*\*/(/\*)?\n?", multiLine: true);

  static final RegExp _enterElseSingleLine =
  new RegExp(r"//+\s*#else\s*\n", multiLine: false);

  _ElseMode(LineScanner scanner, StringSink output, String buildMode)
  : super(scanner, output, buildMode);

  String name = "else";

  String currentElseSourceMode;
  bool get matchesMode => currentElseSourceMode != buildMode.toUpperCase();

  bool canEnterWhileIn(_SourceMode otherMode) {
    if (otherMode is! _IfMode) return false;

    if (scanner.scan(_enterElseMultiline) ||
    scanner.scan(_enterElseSingleLine)) {
      // copy source mode
      currentElseSourceMode = (otherMode as _IfMode).currentSourceMode;
      return true;
    }
    return false;
  }

  process() {
    if (scanner.matches(_IfMode._exitIfMultiline) ||
    scanner.matches(_IfMode._exitIfSingleLine)) {
      currentElseSourceMode = null;
      return false;
    }
    if (scanner.scan(_slashOrAsterisk) && matchesMode) {
      output.write(scanner.lastMatch.group(0));
    }
    scanner.scan(_notSlashOrAsterisk);
    if (matchesMode) output.write(scanner.lastMatch.group(0));
    return true;
  }
}