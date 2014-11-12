import 'package:unittest/unittest.dart';
import 'package:barback/barback.dart';
import 'package:simple_preprocessor/simple_preprocessor.dart';

main() {
  var debugSettings = new BarbackSettings({}, BarbackMode.DEBUG);
  var debugProcessor = new SimplePreprocessor.asPlugin(debugSettings);
  var releaseSettings = new BarbackSettings({}, BarbackMode.RELEASE);
  var releaseProcessor = new SimplePreprocessor.asPlugin(releaseSettings);

  group("Simple debug preprocessor", () {
    test("returns normal string unchanged", () {
      var text = "String s = 'example 42 or something';";
      expect(debugProcessor.process(text), text);
      expect(releaseProcessor.process(text), text);
    });

    test("returns string with random slashes unchanged", () {
      var text = "var ratio = good / all;";
      expect(debugProcessor.process(text), text);
      expect(releaseProcessor.process(text), text);
    });

    test("returns string with regular comment unchanged", () {
      var text = "var all = good /* comment */ + bad;";
      expect(debugProcessor.process(text), text);
      expect(releaseProcessor.process(text), text);
    });

    test("correctly handles #if debug in multiline-style comment", () {
      var text = "var speed = /* #if DEBUG */ 100 * /* #endif */ speed;";
      var debug = "var speed =  100 *  speed;";
      var release = "var speed =  speed;";
      expect(debugProcessor.process(text), debug);
      expect(releaseProcessor.process(text), release);
    });

    test("correctly handles #if debug on multiple lines", () {
      var text = r"""
        var speed = 100;
        /* #if DEBUG */
        var speed = 1000;
        /* #endif */
        print(speed);
      """;
      var onlyInDebug = r"var speed = 1000;";
      expect(debugProcessor.process(text), contains(onlyInDebug));
      expect(releaseProcessor.process(text), isNot(contains(onlyInDebug)));
    });

    test("correctly handles #if debug on one-line comment", () {
      var text = r"""
        var speed = 100;
        // #if DEBUG
        var speed = 1000;
        // #endif
        print(speed);
      """;
      var onlyInDebug = r"var speed = 1000;";
      expect(debugProcessor.process(text), contains(onlyInDebug));
      expect(releaseProcessor.process(text), isNot(contains(onlyInDebug)));
    });

    test("correctly handles #else on multiline comment", () {
      var text = r"""
        /* #if DEBUG */
        var speed = 1000;
        /* #else */
        var speed = 100;
        /* #endif */
        print(speed);
      """;
      var onlyInDebug = r"var speed = 1000;";
      var onlyInRelease = r"var speed = 100;";
      expect(debugProcessor.process(text), contains(onlyInDebug));
      expect(debugProcessor.process(text), isNot(contains(onlyInRelease)));
      expect(releaseProcessor.process(text), isNot(contains(onlyInDebug)));
      expect(releaseProcessor.process(text), contains(onlyInRelease));
    });

    test("correctly handles #else on one-line comment", () {
      var text = r"""
        // #if DEBUG
        var speed = 1000;
        // #else
        var speed = 100;
        // #endif
        print(speed);
      """;
      var onlyInDebug = r"var speed = 1000;";
      var onlyInRelease = r"var speed = 100;";
      expect(debugProcessor.process(text), contains(onlyInDebug));
      expect(debugProcessor.process(text), isNot(contains(onlyInRelease)));
      expect(releaseProcessor.process(text), isNot(contains(onlyInDebug)));
      expect(releaseProcessor.process(text), contains(onlyInRelease));
    });

    test("correctly handles directive starting at start of file", () {
      var text = r"""// #if DEBUG
        var speed = 1000;
        // #else
        var speed = 100;
        // #endif
        print(speed);
      """;
      var onlyInDebug = r"var speed = 1000;";
      var onlyInRelease = r"var speed = 100;";
      expect(debugProcessor.process(text), contains(onlyInDebug));
      expect(debugProcessor.process(text), isNot(contains(onlyInRelease)));
      expect(releaseProcessor.process(text), isNot(contains(onlyInDebug)));
      expect(releaseProcessor.process(text), contains(onlyInRelease));
    });

    test("correctly handles directive ending at end of file", () {
      var text = r"""
        /* #if DEBUG */
        var speed = 1000;
        /* #else */
        var speed = 100;
        /* #endif */""";
      var onlyInDebug = r"var speed = 1000;";
      var onlyInRelease = r"var speed = 100;";
      expect(debugProcessor.process(text), contains(onlyInDebug));
      expect(debugProcessor.process(text), isNot(contains(onlyInRelease)));
      expect(releaseProcessor.process(text), isNot(contains(onlyInDebug)));
      expect(releaseProcessor.process(text), contains(onlyInRelease));
    });

    test("throws exception in malformed source (no #endif after #else)", () {
      var text = r"""
        // #if DEBUG
        var speed = 1000;
        // #else
        var speed = 100;
        print(speed);
      """;
      expect(() => debugProcessor.process(text), throwsFormatException);
      expect(() => releaseProcessor.process(text), throwsFormatException);
    });

    test("throws exception in malformed source (no #endif after #if)", () {
      var text = r"""
        // #if DEBUG
        var speed = 1000;
        print(speed);
      """;
      expect(() => debugProcessor.process(text), throwsFormatException);
      expect(() => releaseProcessor.process(text), throwsFormatException);
    });

    test("understands custom modes", () {
      var text = r"""
        // #if CUSTOM_MODE
        var speed = 1000;
        // #endif
        print(speed);
      """;
      var inclText = r"var speed = 1000;";

      var customSettings = new BarbackSettings({},
          new BarbackMode("custom_mode"));
      var customProcessor = new SimplePreprocessor.asPlugin(customSettings);
      expect(customProcessor.process(text), contains(inclText));
      expect(debugProcessor.process(text), isNot(contains(inclText)));
      expect(releaseProcessor.process(text), isNot(contains(inclText)));
    });

    test("handles else with custom modes", () {
      var text = r"""
        // #if CUSTOM_MODE
        var speed = 1000;
        // #else
        var speed = 100;
        // #endif
        print(speed);
      """;
      var inclText = r"var speed = 1000;";
      var notInclText = r"var speed = 100;";

      var customSettings = new BarbackSettings({},
          new BarbackMode("custom_mode"));
      var customProcessor = new SimplePreprocessor.asPlugin(customSettings);
      expect(customProcessor.process(text), contains(inclText));
      expect(customProcessor.process(text), isNot(contains(notInclText)));
      expect(debugProcessor.process(text), isNot(contains(inclText)));
      expect(debugProcessor.process(text), contains(notInclText));
    });

    test("handles malformed # else", () {
      var text = r"""
        // #if CUSTOM_MODE
        var speed = 1000;
        // # else
        var speed = 100;
        // #endif
        print(speed);
      """;
      var inclText = r"var speed = 1000;";
      var inclText2 = r"var speed = 100;";

      var customSettings = new BarbackSettings({},
          new BarbackMode("custom_mode"));
      var customProcessor = new SimplePreprocessor.asPlugin(customSettings);
      expect(customProcessor.process(text), contains(inclText));
      expect(customProcessor.process(text), contains(inclText2));
    });

    test("handle special multiline comment of if else", () {
      var text = r"""
        /* #if DEBUG *//*
        var speed = 1000;
      *//* #else */
        var speed = 100;
        /* #endif */
        print(speed);
      """;
      var debugRegExp =
          new RegExp(r"\s*var speed = 1000;\s*print\(speed\);\s*");
      var releaseRegExp =
          new RegExp(r"\s*var speed = 100;\s*print\(speed\);\s*");

      expect(debugProcessor.process(text), matches(debugRegExp));
      expect(releaseProcessor.process(text), matches(releaseRegExp));
    });
  });
}

