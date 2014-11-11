library simple_preprocessor;

import 'package:barback/barback.dart';
import 'package:string_scanner/string_scanner.dart';
import 'dart:collection';

part 'src/modes.dart';

class SimplePreprocessor extends Transformer {
  final BarbackSettings _settings;

  String get buildMode => _settings.mode.name;

  Queue<_SourceMode> _modeStack = new Queue<_SourceMode>();
  _SourceMode get currentMode => _modeStack.first;

  SimplePreprocessor.asPlugin(this._settings);

  String get allowedExtensions => ".dart";

  apply(Transform transform) {
    return transform.primaryInput.readAsString().then((content) {
      var id = transform.primaryInput.id;
      var newContent = process(content);
      transform.addOutput(new Asset.fromString(id, newContent));
    });
  }

  String process(String content) {
    LineScanner scanner = new LineScanner(content);
    StringBuffer newContent = new StringBuffer();

    // Sorted from most specific to least specific (= Normal).
    final modes = <_SourceMode>[
        new _ElseMode(scanner, newContent, buildMode),
        new _IfMode(scanner, newContent, buildMode),
        new _NormalMode(scanner, newContent)
    ];

    _modeStack.clear();
    _modeStack.add(modes.last);  // Start state stack with normal.

    while (!scanner.isDone) {
      for (_SourceMode mode in modes) {
        if (mode == currentMode) {
          continue;
        }
        if (mode.canEnterWhileIn(currentMode)) {
          _modeStack.addFirst(mode);
          mode.lineStart = scanner.line;
          break;
        }
      }
      bool shouldContinueWithMode = currentMode.process();
      if (!shouldContinueWithMode) _modeStack.removeFirst();
    }

    if (_modeStack.length != 1) {
      throw new FormatException("Source code has unclosed ${currentMode.name} "
          "block that starts on line ${currentMode.lineStart}");
    }

    return newContent.toString();
  }
}