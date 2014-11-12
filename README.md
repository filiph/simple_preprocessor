# Simple Preprocessor

This Transformer modifies code according to directives similar to those found
in [C preprocessors][]. The syntax should be familiar.

[C preprocessors]: http://en.wikipedia.org/wiki/C_preprocessor

Let's start with an example:

```dart
_coreAjax = $['core-ajax'];  // Get <core-ajax> element.
/* #if DEBUG */
_coreAjax.url = "mock.json";  // Change actual prod URL to a mock file.
/* #endif */
```

The URL-changing line will only be included in debug builds (which is also the
default mode for `pub serve`). The line will not exist in release builds.

Since you can change build mode to any custom string by running
`pub build --mode=<mode>`, you can have things like this:

```dart
/* #if LOCALHOST */
baseUrl = "http://localhost/";
/* #endif */
```

## How to use this

In your `pubspec.yaml`, add simple_preprocessor as a dependency and as
a Transformer. Like this:

```yaml
dependencies:
  simple_preprocessor: any
  ...
transformers
- simple_preprocessor
```

Try to include it before any other transformer (it's a _pre_-processor, after
all).

## Warning

This is _not_ a best practice. You're changing semantics of your program by
a non-standard control mechanism that — worse still — lives in a _comment_. The
only thing that kind of makes this almost okay is that the `#if` directive
is so well recognized.

Even so, if you choose to use it, you shouldn't probably use it for anything
more than a few simple `#if DEBUG` statements.

## Supported directives

Currently, there's only `#if`, `#else` and `#endif`.

The `#if` directive takes one argument, which must be all upper case. This will
be compared to the mode of `pub build` ("release" by default) or `pub serve`
("debug" by default). When there's a match, anything between `#if` and `#endif`
(or `#else`) will be included. If not, it will be stripped.

The `#elif` directive is on my TODO, but probably not anything else. This
shouldn't be a simplified programming language like that of a C preprocessor.
If you need to do something more complex than `#if DEBUG`, you're better off
using Dart.

There is no `#define` – the only definition is made by the transformer mode.

## Commenting out branches

Sometimes, to play better with static analysis tooling, you might want to
hide some of the lines from it. Here's a solution:

```dart
  /* #if DEBUG *//*
  var speed = 1000;
*//* #else */
  var speed = 100;
  /* #endif */
```

Without the extra `/*` and `*/`, your IDE would probably display an error
about defining the `speed` variable twice. But `simple_preprocessor` correctly
identifies this syntax and will uncomment the contents between `#if` end `#else`
for debug builds.

Note that the extra comment _must_ come immediately after the `#if` or `#else`
comment and directly before the `#else` or `#endif` comment. No whitespace is
permitted.