// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGesture('Should recognize pan', (GestureTester tester) {
    final PanGestureRecognizer pan = PanGestureRecognizer();
    final TapGestureRecognizer tap = TapGestureRecognizer()..onTap = () {};
    addTearDown(pan.dispose);
    addTearDown(tap.dispose);

    bool didStartPan = false;
    pan.onStart = (_) {
      didStartPan = true;
    };

    Offset? updatedScrollDelta;
    pan.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
    };

    bool didEndPan = false;
    pan.onEnd = (DragEndDetails details) {
      didEndPan = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    tester.closeArena(5);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    tester.route(down);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    // touch should give up when it hits kTouchSlop, which was 18.0 when this test was last updated.

    tester.route(pointer.move(const Offset(20.0, 20.0))); // moved 10 horizontally and 10 vertically which is 14 total
    expect(didStartPan, isFalse); // 14 < 18
    tester.route(pointer.move(const Offset(20.0, 30.0))); // moved 10 horizontally and 20 vertically which is 22 total
    expect(didStartPan, isTrue); // 22 > 18
    didStartPan = false;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(0.0, -5.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer.up());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);
    didEndPan = false;
    expect(didTap, isFalse);
  });

  testGesture('Should report most recent point to onStart by default', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();
    final VerticalDragGestureRecognizer competingDrag = VerticalDragGestureRecognizer()
      ..onStart = (_) {};
    addTearDown(() => drag.dispose);
    addTearDown(() => competingDrag.dispose);

    late Offset positionAtOnStart;
    drag.onStart = (DragStartDetails details) {
      positionAtOnStart = details.globalPosition;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    tester.route(pointer.move(const Offset(30.0, 0.0)));
    expect(positionAtOnStart, const Offset(30.0, 00.0));
  });

  testGesture('Should report most recent point to onStart with a start configuration', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();
    final VerticalDragGestureRecognizer competingDrag = VerticalDragGestureRecognizer()
      ..onStart = (_) {};
    addTearDown(() => drag.dispose);
    addTearDown(() => competingDrag.dispose);

    Offset? positionAtOnStart;
    drag.onStart = (DragStartDetails details) {
      positionAtOnStart = details.globalPosition;
    };
    Offset? updateOffset;
    drag.onUpdate = (DragUpdateDetails details) {
      updateOffset = details.globalPosition;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    tester.route(pointer.move(const Offset(30.0, 0.0)));

    expect(positionAtOnStart, const Offset(30.0, 0.0));
    expect(updateOffset, null);
  });

  testGesture('Should recognize drag', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    double? updatedDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(down);
    expect(didStartDrag, isTrue);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isTrue);
    didStartDrag = false;
    expect(updatedDelta, 10.0);
    updatedDelta = null;
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, 0.0);
    updatedDelta = null;
    expect(didEndDrag, isFalse);

    tester.route(pointer.up());
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;
  });

  testGesture('Should reject mouse drag when configured to ignore mouse pointers - Horizontal', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer(supportedDevices: <PointerDeviceKind>{
      PointerDeviceKind.touch,
    }) ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    double? updatedDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(down);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.up());
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);
  });

  testGesture('Should reject mouse drag when configured to ignore mouse pointers - Vertical', (GestureTester tester) {
    final VerticalDragGestureRecognizer drag = VerticalDragGestureRecognizer(supportedDevices: <PointerDeviceKind>{
      PointerDeviceKind.touch,
    })..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    double? updatedDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(down);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(25.0, 20.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(25.0, 20.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.up());
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);
  });

  testGesture('DragGestureRecognizer.onStart behavior test', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    Duration? startTimestamp;
    Offset? positionAtOnStart;
    drag.onStart = (DragStartDetails details) {
      startTimestamp = details.sourceTimeStamp;
      positionAtOnStart = details.globalPosition;
    };

    Duration? updatedTimestamp;
    Offset? updateDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedTimestamp = details.sourceTimeStamp;
      updateDelta = details.delta;
    };

    // No competing, dragStartBehavior == DragStartBehavior.down
    final TestPointer pointer = TestPointer(5);
    PointerDownEvent down = pointer.down(const Offset(10.0, 10.0), timeStamp: const Duration(milliseconds: 100));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(startTimestamp, isNull);
    expect(positionAtOnStart, isNull);
    expect(updatedTimestamp, isNull);

    tester.route(down);
    // The only horizontal drag gesture win the arena when the pointer down.
    expect(startTimestamp, const Duration(milliseconds: 100));
    expect(positionAtOnStart, const Offset(10.0, 10.0));
    expect(updatedTimestamp, isNull);

    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 200)));
    expect(updatedTimestamp, const Duration(milliseconds: 200));
    expect(updateDelta, const Offset(10.0, 0.0));

    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 300)));
    expect(updatedTimestamp, const Duration(milliseconds: 300));
    expect(updateDelta, Offset.zero);
    tester.route(pointer.up());

    // No competing, dragStartBehavior == DragStartBehavior.start
    // When there are no other gestures competing with this gesture in the arena,
    // there's no difference in behavior between the two settings.
    drag.dragStartBehavior = DragStartBehavior.start;
    startTimestamp = null;
    positionAtOnStart = null;
    updatedTimestamp = null;
    updateDelta = null;

    down = pointer.down(const Offset(10.0, 10.0), timeStamp: const Duration(milliseconds: 400));
    drag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    expect(startTimestamp, const Duration(milliseconds: 400));
    expect(positionAtOnStart, const Offset(10.0, 10.0));
    expect(updatedTimestamp, isNull);

    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 500)));
    expect(updatedTimestamp, const Duration(milliseconds: 500));
    tester.route(pointer.up());

    // With competing, dragStartBehavior == DragStartBehavior.start
    startTimestamp = null;
    positionAtOnStart = null;
    updatedTimestamp = null;
    updateDelta = null;

    final VerticalDragGestureRecognizer competingDrag = VerticalDragGestureRecognizer()
      ..onStart = (_) {};
    addTearDown(() => competingDrag.dispose);

    down = pointer.down(const Offset(10.0, 10.0), timeStamp: const Duration(milliseconds: 600));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    // The pointer down event do not trigger anything.
    expect(startTimestamp, isNull);
    expect(positionAtOnStart, isNull);
    expect(updatedTimestamp, isNull);

    tester.route(pointer.move(const Offset(30.0, 10.0), timeStamp: const Duration(milliseconds: 700)));
    expect(startTimestamp, const Duration(milliseconds: 700));
    // Using the position of the pointer at the time this gesture recognizer won the arena.
    expect(positionAtOnStart, const Offset(30.0, 10.0));
    expect(updatedTimestamp, isNull); // Do not trigger an update event.
    tester.route(pointer.up());

    // With competing, dragStartBehavior == DragStartBehavior.down
    drag.dragStartBehavior = DragStartBehavior.down;
    startTimestamp = null;
    positionAtOnStart = null;
    updatedTimestamp = null;
    updateDelta = null;

    down = pointer.down(const Offset(10.0, 10.0), timeStamp: const Duration(milliseconds: 800));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    expect(startTimestamp, isNull);
    expect(positionAtOnStart, isNull);
    expect(updatedTimestamp, isNull);

    tester.route(pointer.move(const Offset(30.0, 10.0), timeStamp: const Duration(milliseconds: 900)));
    expect(startTimestamp, const Duration(milliseconds: 900));
    // Using the position of the first detected down event for the pointer.
    expect(positionAtOnStart, const Offset(10.0, 10.0));
    expect(updatedTimestamp, const Duration(milliseconds: 900)); // Also, trigger an update event.
    expect(updateDelta, const Offset(20.0, 0.0));
    tester.route(pointer.up());
  });

  testGesture('Should report original timestamps', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    Duration? startTimestamp;
    drag.onStart = (DragStartDetails details) {
      startTimestamp = details.sourceTimeStamp;
    };

    Duration? updatedTimestamp;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedTimestamp = details.sourceTimeStamp;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0), timeStamp: const Duration(milliseconds: 100));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(startTimestamp, isNull);

    tester.route(down);
    expect(startTimestamp, const Duration(milliseconds: 100));

    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 200)));
    expect(updatedTimestamp, const Duration(milliseconds: 200));

    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 300)));
    expect(updatedTimestamp, const Duration(milliseconds: 300));
  });

  testGesture('Should report initial down point to onStart with a down configuration', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    final VerticalDragGestureRecognizer competingDrag = VerticalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down
      ..onStart = (_) {};
    addTearDown(() => drag.dispose);
    addTearDown(() => competingDrag.dispose);

    Offset? positionAtOnStart;
    drag.onStart = (DragStartDetails details) {
      positionAtOnStart = details.globalPosition;
    };
    Offset? updateOffset;
    Offset? updateDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updateOffset = details.globalPosition;
      updateDelta = details.delta;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    tester.route(pointer.move(const Offset(30.0, 0.0)));
    expect(positionAtOnStart, const Offset(10.0, 10.0));

    // The drag is horizontal so we're going to ignore the vertical delta position
    // when calculating the new global position.
    expect(updateOffset, const Offset(30.0, 10.0));
    expect(updateDelta, const Offset(20.0, 0.0));
  });

  testGesture('Drag with multiple pointers in down behavior (events sent individually)', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag1 =
      HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    final VerticalDragGestureRecognizer drag2 =
      VerticalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(() => drag1.dispose);
    addTearDown(() => drag2.dispose);

    final List<String> log = <String>[];
    drag1.onDown = (_) { log.add('drag1-down'); };
    drag1.onStart = (_) { log.add('drag1-start'); };
    drag1.onUpdate = (_) { log.add('drag1-update'); };
    drag1.onEnd = (_) { log.add('drag1-end'); };
    drag1.onCancel = () { log.add('drag1-cancel'); };
    drag2.onDown = (_) { log.add('drag2-down'); };
    drag2.onStart = (_) { log.add('drag2-start'); };
    drag2.onUpdate = (_) { log.add('drag2-update'); };
    drag2.onEnd = (_) { log.add('drag2-end'); };
    drag2.onCancel = () { log.add('drag2-cancel'); };

    final TestPointer pointer5 = TestPointer(5);
    final PointerDownEvent down5 = pointer5.down(const Offset(10.0, 10.0));
    drag1.addPointer(down5);
    drag2.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    log.add('-a');

    // only one pointer moves, the endOfBatch is true.
    tester.route(pointer5.move(const Offset(100.0, 0.0)));
    log.add('-b');
    tester.route(pointer5.move(const Offset(50.0, 50.0)));
    log.add('-c');

    final TestPointer pointer6 = TestPointer(6);
    final PointerDownEvent down6 = pointer6.down(const Offset(20.0, 20.0));
    drag1.addPointer(down6);
    drag2.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    log.add('-d');

    // Two pointers down, only pointer5 moves, and the endOfBatch is ture (for example iOS).
    tester.route(pointer5.move(const Offset(0.0, 100.0)));
    log.add('-e');
    tester.route(pointer5.move(const Offset(70.0, 70.0)));
    log.add('-f');

    tester.route(pointer5.up());
    tester.route(pointer6.up());

    expect(log, <String>[
      'drag1-down',
      'drag2-down',
      '-a',
      'drag2-cancel',
      'drag1-start',
      'drag1-update',
      '-b',
      'drag1-update',
      '-c',
      'drag2-down',
      'drag2-cancel',
      '-d',
      'drag1-update',
      '-e',
      'drag1-update',
      '-f',
      'drag1-end',
    ]);
  });

  testGesture('Drag with multiple pointers in down behavior (events sent in batches)', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag1 = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    final VerticalDragGestureRecognizer drag2 = VerticalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(() => drag1.dispose);
    addTearDown(() => drag2.dispose);

    final List<String> log = <String>[];
    drag1.onDown = (_) { log.add('drag1-down'); };
    drag1.onStart = (_) { log.add('drag1-start'); };
    drag1.onUpdate = (_) { log.add('drag1-update'); };
    drag1.onEnd = (_) { log.add('drag1-end'); };
    drag1.onCancel = () { log.add('drag1-cancel'); };
    drag2.onDown = (_) { log.add('drag2-down'); };
    drag2.onStart = (_) { log.add('drag2-start'); };
    drag2.onUpdate = (_) { log.add('drag2-update'); };
    drag2.onEnd = (_) { log.add('drag2-end'); };
    drag2.onCancel = () { log.add('drag2-cancel'); };

    final TestPointer pointer5 = TestPointer(5);
    final PointerDownEvent down5 = pointer5.down(const Offset(10.0, 10.0));
    drag1.addPointer(down5);
    drag2.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    expect(log, <String>[
      'drag1-down',
      'drag2-down',
    ]);
    log.clear();

    // only one pointer moves, the endOfBatch is true.
    tester.route(pointer5.move(const Offset(100.0, 0.0)));
    expect(log, <String>[
      'drag2-cancel',
      'drag1-start',
      'drag1-update',
    ]);
    log.clear();

    tester.route(pointer5.move(const Offset(50.0, 50.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    log.clear();

    final TestPointer pointer6 = TestPointer(6);
    final PointerDownEvent down6 = pointer6.down(const Offset(20.0, 20.0));
    drag1.addPointer(down6);
    drag2.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    expect(log, <String>[
      'drag2-down',
      'drag2-cancel',
    ]);
    log.clear();

    // Two pointers down, pointer5 and pointer6 move, and the endOfBatch of pointer5 is false (for example Android).
    tester.route(pointer5.move(const Offset(0.0, 100.0), endOfBatch: false));
    expect(log, <String>[]);

    tester.route(pointer6.move(const Offset(70.0, 70.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    log.clear();

    // Two pointers down, pointer5 and pointer6 move, and the endOfBatch of pointer6 is false.
    tester.route(pointer6.move(const Offset(0.0, 100.0), endOfBatch: false));
    expect(log, <String>[]);

    tester.route(pointer5.move(const Offset(70.0, 70.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    log.clear();

    tester.route(pointer5.up());
    expect(log, <String>[
      'drag1-end',
    ]);
    log.clear();

    tester.route(pointer6.up());
    expect(log, <String>[]);
  });

  testGesture('A pointer joins and leaves during a gesture', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag1 = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    final VerticalDragGestureRecognizer drag2 = VerticalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(() => drag1.dispose);
    addTearDown(() => drag2.dispose);

    Offset? updatedScrollDelta;
    final List<String> log = <String>[];
    drag1.onDown = (_) { log.add('drag1-down'); };
    drag1.onStart = (_) { log.add('drag1-start'); };
    drag1.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
      log.add('drag1-update');
    };
    drag1.onEnd = (_) { log.add('drag1-end'); };
    drag1.onCancel = () { log.add('drag1-cancel'); };
    drag2.onDown = (_) { log.add('drag2-down'); };
    drag2.onStart = (_) { log.add('drag2-start'); };
    drag2.onUpdate = (_) { log.add('drag2-update'); };
    drag2.onEnd = (_) { log.add('drag2-end'); };
    drag2.onCancel = () { log.add('drag2-cancel'); };

    // Now only one pointer moves.
    final TestPointer pointer5 = TestPointer(5);
    final PointerDownEvent down5 = pointer5.down(const Offset(10.0, 10.0));
    drag1.addPointer(down5);
    drag2.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    expect(log, <String>[
      'drag1-down',
      'drag2-down',
    ]);
    log.clear();

    tester.route(pointer5.move(const Offset(100.0, 0.0)));
    expect(log, <String>[
      'drag2-cancel',
      'drag1-start',
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(90.0, 0.0));
    log.clear();

    tester.route(pointer5.move(const Offset(50.0, 50.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(-50.0, 0.0));
    log.clear();

    // Let another pointer join.
    final TestPointer pointer6 = TestPointer(6);
    final PointerDownEvent down6 = pointer6.down(const Offset(20.0, 20.0));
    drag1.addPointer(down6);
    drag2.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    expect(log, <String>[
      'drag2-down',
      'drag2-cancel',
    ]);
    log.clear();

    // They move in the opposite direction. Pointer5 moves (-10, -10)
    // and pointer6 moves (+20, +20)
    tester.route(pointer5.move(const Offset(40.0, 40.0), endOfBatch: false));
    expect(log, <String>[]);

    tester.route(pointer6.move(const Offset(40.0, 40.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(10.0, 0.0));
    log.clear();

    // They move at the same direction. Pointer5 moves (20, 20)
    // and pointer6 moves (+30, +30)
    tester.route(pointer5.move(const Offset(60.0, 60.0), endOfBatch: false));
    expect(log, <String>[]);

    tester.route(pointer6.move(const Offset(70.0, 70.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(30.0, 0.0));
    updatedScrollDelta = null;
    log.clear();

    // One pointer leaves and the remaining pointer still moves.
    tester.route(pointer6.up());
    expect(log, <String>[
      'drag1-end',
    ]);
    log.clear();

    tester.route(pointer5.move(const Offset(30.0, 40.0)));
    expect(log, <String>[]);
    expect(updatedScrollDelta, isNull);

    tester.route(pointer5.move(const Offset(40.0, 50.0)));
    expect(log, <String>[]);
    expect(updatedScrollDelta, isNull);

    tester.route(pointer5.move(const Offset(50.0, 60.0)));
    expect(log, <String>[]);
    expect(updatedScrollDelta, isNull);

    tester.route(pointer5.up());
    expect(log, <String>[]);
  });

  testGesture('Two pointers down and both move', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag1 = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(() => drag1.dispose);

    final List<String> log = <String>[];
    Offset? updatedScrollDelta;
    drag1.onDown = (_) { log.add('drag1-down'); };
    drag1.onStart = (_) { log.add('drag1-start'); };
    drag1.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
      log.add('drag1-update');
    };
    drag1.onEnd = (_) { log.add('drag1-end'); };
    drag1.onCancel = () { log.add('drag1-cancel'); };

    final TestPointer pointer5 = TestPointer(5);
    final PointerDownEvent down5 = pointer5.down(const Offset(10.0, 10.0));
    drag1.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    final TestPointer pointer6 = TestPointer(6);
    final PointerDownEvent down6 = pointer6.down(const Offset(20.0, 20.0));
    drag1.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    expect(log, <String>[
      'drag1-down',
      'drag1-start',
    ]);
    log.clear();

    // Pointer 5 moved, but the gesture recognizer is waiting for a full batch, so there is no movement yet.
    tester.route(pointer5.move(const Offset(20.0, 20.0), endOfBatch: false));
    expect(log, <String>[]);
    expect(updatedScrollDelta, isNull);
    log.clear();

    // Pointer 6 moved, making a full batch. The gesture recognizer dispatches movement.
    tester.route(pointer6.move(const Offset(50.0, 50.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(30.0, 0.0));

    log.clear();
    updatedScrollDelta = null;
    // Pointer 6 moved, but the gesture recognizer is waiting for a full batch, so there is no movement yet.
    tester.route(pointer6.move(const Offset(90.0, 100.0), endOfBatch: false));
    expect(log, <String>[]);
    expect(updatedScrollDelta, isNull);
    log.clear();
    updatedScrollDelta = null;

    // Pointer 5 moved, making a full batch. The gesture recognizer dispatches movement.
    tester.route(pointer5.move(const Offset(40.0, 70.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(40.0, 0.0));
    log.clear();

    tester.route(pointer5.up());
    tester.route(pointer6.up());
    expect(log, <String>[
      'drag1-end',
    ]);
  });

  testGesture('Two pointers down but only one moves and dispatches events', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag1 = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.start;
    addTearDown(() => drag1.dispose);

    final List<String> log = <String>[];
    Offset? updatedScrollDelta;
    drag1.onDown = (_) { log.add('drag1-down'); };
    drag1.onStart = (_) { log.add('drag1-start'); };
    drag1.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
      log.add('drag1-update');
    };
    drag1.onEnd = (_) { log.add('drag1-end'); };
    drag1.onCancel = () { log.add('drag1-cancel'); };

    final TestPointer pointer5 = TestPointer(5);
    final PointerDownEvent down5 = pointer5.down(const Offset(10.0, 10.0));
    drag1.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    final TestPointer pointer6 = TestPointer(6);
    final PointerDownEvent down6 = pointer6.down(const Offset(20.0, 20.0));
    drag1.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    expect(log, <String>[
      'drag1-down',
      'drag1-start',
    ]);
    log.clear();

    // Pointer5 moved and pointer6 not moved, the endOfBatch is true (for example iOS).
    tester.route(pointer5.move(const Offset(20.0, 20.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(10.0, 0.0));
    log.clear();
    updatedScrollDelta = null;


    tester.route(pointer5.move(const Offset(40.0, 70.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(20.0, 0.0));
    log.clear();

    tester.route(pointer5.up());
    tester.route(pointer6.up());
    expect(log, <String>[
      'drag1-end',
    ]);
  });

  testGesture('Two pointers down but only one moves (both pointers dispatch events)', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag1 = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.start;
    addTearDown(() => drag1.dispose);

    final List<String> log = <String>[];
    Offset? updatedScrollDelta;
    drag1.onDown = (_) { log.add('drag1-down'); };
    drag1.onStart = (_) { log.add('drag1-start'); };
    drag1.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
      log.add('drag1-update');
    };
    drag1.onEnd = (_) { log.add('drag1-end'); };
    drag1.onCancel = () { log.add('drag1-cancel'); };

    final TestPointer pointer5 = TestPointer(5);
    final PointerDownEvent down5 = pointer5.down(const Offset(10.0, 10.0));
    drag1.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    final TestPointer pointer6 = TestPointer(6);
    final PointerDownEvent down6 = pointer6.down(const Offset(20.0, 20.0));
    drag1.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    expect(log, <String>[
      'drag1-down',
      'drag1-start',
    ]);
    log.clear();

    // Pointer5 moved and pointer6 not moved, the endOfBatch of pointer5 is false and the endOfBatch of pointer6 is ture.
    tester.route(pointer5.move(const Offset(20.0, 20.0), endOfBatch: false));
    expect(log, <String>[]);
    expect(updatedScrollDelta, isNull);

    // Pointer6 does not move.
    tester.route(pointer6.move(const Offset(20.0, 20.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(10.0, 0.0));
    log.clear();
    updatedScrollDelta = null;

    tester.route(pointer5.move(const Offset(40.0, 70.0), endOfBatch: false));
    expect(log, <String>[]);
    expect(updatedScrollDelta, isNull);

    tester.route(pointer6.move(const Offset(20.0, 20.0)));
    expect(log, <String>[
      'drag1-update',
    ]);
    expect(updatedScrollDelta, const Offset(20.0, 0.0));
    log.clear();

    tester.route(pointer5.up());
    tester.route(pointer6.up());
    expect(log, <String>[
      'drag1-end',
    ]);
  });

  testGesture('Clamp max velocity', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    late Velocity velocity;
    double? primaryVelocity;
    drag.onEnd = (DragEndDetails details) {
      velocity = details.velocity;
      primaryVelocity = details.primaryVelocity;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 25.0), timeStamp: const Duration(milliseconds: 10));
    drag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 10)));
    tester.route(pointer.move(const Offset(30.0, 25.0), timeStamp: const Duration(milliseconds: 11)));
    tester.route(pointer.move(const Offset(40.0, 25.0), timeStamp: const Duration(milliseconds: 12)));
    tester.route(pointer.move(const Offset(50.0, 25.0), timeStamp: const Duration(milliseconds: 13)));
    tester.route(pointer.move(const Offset(60.0, 25.0), timeStamp: const Duration(milliseconds: 14)));
    tester.route(pointer.move(const Offset(70.0, 25.0), timeStamp: const Duration(milliseconds: 15)));
    tester.route(pointer.move(const Offset(80.0, 25.0), timeStamp: const Duration(milliseconds: 16)));
    tester.route(pointer.move(const Offset(90.0, 25.0), timeStamp: const Duration(milliseconds: 17)));
    tester.route(pointer.move(const Offset(100.0, 25.0), timeStamp: const Duration(milliseconds: 18)));
    tester.route(pointer.move(const Offset(110.0, 25.0), timeStamp: const Duration(milliseconds: 19)));
    tester.route(pointer.move(const Offset(120.0, 25.0), timeStamp: const Duration(milliseconds: 20)));
    tester.route(pointer.up(timeStamp: const Duration(milliseconds: 20)));
    expect(velocity.pixelsPerSecond.dx, inInclusiveRange(0.99 * kMaxFlingVelocity, kMaxFlingVelocity));
    expect(velocity.pixelsPerSecond.dy, moreOrLessEquals(0.0));
    expect(primaryVelocity, velocity.pixelsPerSecond.dx);
  });

  testGesture('Synthesized pointer events are ignored for velocity tracking', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    late Velocity velocity;
    drag.onEnd = (DragEndDetails details) {
      velocity = details.velocity;
    };

    final TestPointer pointer = TestPointer();
    final PointerDownEvent down = pointer.down(const Offset(10.0, 25.0), timeStamp: const Duration(milliseconds: 10));
    drag.addPointer(down);
    tester.closeArena(1);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 20)));
    tester.route(pointer.move(const Offset(30.0, 25.0), timeStamp: const Duration(milliseconds: 30)));
    tester.route(pointer.move(const Offset(40.0, 25.0), timeStamp: const Duration(milliseconds: 40)));
    tester.route(pointer.move(const Offset(50.0, 25.0), timeStamp: const Duration(milliseconds: 50)));
    tester.route(const PointerMoveEvent(
      pointer: 1,
      // Simulate a small synthesized wobble which would have slowed down the
      // horizontal velocity from 1 px/ms and introduced a slight vertical velocity.
      position: Offset(51.0, 26.0),
      timeStamp: Duration(milliseconds: 60),
      synthesized: true,
    ));
    tester.route(pointer.up(timeStamp: const Duration(milliseconds: 70)));
    expect(velocity.pixelsPerSecond.dx, moreOrLessEquals(1000.0));
    expect(velocity.pixelsPerSecond.dy, moreOrLessEquals(0.0));
  });

  /// Checks that quick flick gestures with 1 down, 2 move and 1 up pointer
  /// events still have a velocity
  testGesture('Quick flicks have velocity', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    late Velocity velocity;
    drag.onEnd = (DragEndDetails details) {
      velocity = details.velocity;
    };

    final TestPointer pointer = TestPointer();
    final PointerDownEvent down = pointer.down(const Offset(10.0, 25.0), timeStamp: const Duration(milliseconds: 10));
    drag.addPointer(down);
    tester.closeArena(1);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 20)));
    tester.route(pointer.move(const Offset(30.0, 25.0), timeStamp: const Duration(milliseconds: 30)));
    tester.route(pointer.up(timeStamp: const Duration(milliseconds: 40)));
    // 3 events moving by 10px every 10ms = 1000px/s.
    expect(velocity.pixelsPerSecond.dx, moreOrLessEquals(1000.0));
    expect(velocity.pixelsPerSecond.dy, moreOrLessEquals(0.0));
  });

  testGesture('Drag details', (GestureTester tester) {
    expect(DragDownDetails(), hasOneLineDescription);
    expect(DragStartDetails(), hasOneLineDescription);
    expect(DragUpdateDetails(globalPosition: Offset.zero), hasOneLineDescription);
    expect(DragEndDetails(), hasOneLineDescription);
  });

  testGesture('Should recognize drag', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    Offset? updateDelta;
    double? updatePrimaryDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updateDelta = details.delta;
      updatePrimaryDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);

    expect(didStartDrag, isFalse);
    expect(updateDelta, isNull);
    expect(updatePrimaryDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(down);
    expect(didStartDrag, isTrue);
    expect(updateDelta, isNull);
    expect(updatePrimaryDelta, isNull);
    expect(didEndDrag, isFalse);
    didStartDrag = false;

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updateDelta, const Offset(10.0, 0.0));
    expect(updatePrimaryDelta, 10.0);
    expect(didEndDrag, isFalse);
    updateDelta = null;
    updatePrimaryDelta = null;

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updateDelta, Offset.zero);
    expect(updatePrimaryDelta, 0.0);
    expect(didEndDrag, isFalse);
    updateDelta = null;
    updatePrimaryDelta = null;

    tester.route(pointer.up());
    expect(didStartDrag, isFalse);
    expect(updateDelta, isNull);
    expect(updatePrimaryDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;
  });

  testGesture('Should recognize drag', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    Offset? latestGlobalPosition;
    drag.onStart = (DragStartDetails details) {
      latestGlobalPosition = details.globalPosition;
    };
    Offset? latestDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      latestGlobalPosition = details.globalPosition;
      latestDelta = details.delta;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);

    tester.route(down);
    expect(latestGlobalPosition, const Offset(10.0, 10.0));
    expect(latestDelta, isNull);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(latestGlobalPosition, const Offset(20.0, 25.0));
    expect(latestDelta, const Offset(10.0, 0.0));

    tester.route(pointer.move(const Offset(0.0, 45.0)));
    expect(latestGlobalPosition, const Offset(0.0, 45.0));
    expect(latestDelta, const Offset(-20.0, 0.0));

    tester.route(pointer.up());
  });

  testGesture('Can filter drags based on device kind', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag =
        HorizontalDragGestureRecognizer(
            kind: PointerDeviceKind.mouse,
        )
        ..dragStartBehavior = DragStartBehavior.down;
    addTearDown(drag.dispose);

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    double? updatedDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    // Using a touch pointer to drag shouldn't be recognized.
    final TestPointer touchPointer = TestPointer(5);
    final PointerDownEvent touchDown = touchPointer.down(const Offset(10.0, 10.0));
    drag.addPointer(touchDown);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(touchDown);
    // Still doesn't recognize the drag because it's coming from a touch pointer.
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(touchPointer.move(const Offset(20.0, 25.0)));
    // Still doesn't recognize the drag because it's coming from a touch pointer.
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(touchPointer.up());
    // Still doesn't recognize the drag because it's coming from a touch pointer.
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    // Using a mouse pointer to drag should be recognized.
    final TestPointer mousePointer = TestPointer(5, PointerDeviceKind.mouse);
    final PointerDownEvent mouseDown = mousePointer.down(const Offset(10.0, 10.0));
    drag.addPointer(mouseDown);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(mouseDown);
    expect(didStartDrag, isTrue);
    didStartDrag = false;
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(mousePointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, 10.0);
    updatedDelta = null;
    expect(didEndDrag, isFalse);

    tester.route(mousePointer.up());
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;
  });

  group('Enforce consistent-button restriction:', () {
    late PanGestureRecognizer pan;
    late TapGestureRecognizer tap;
    final List<String> logs = <String>[];

    setUp(() {
      tap = TapGestureRecognizer()
        ..onTap = () {}; // Need a callback to enable competition
      pan = PanGestureRecognizer()
        ..onStart = (DragStartDetails details) {
          logs.add('start');
        }
        ..onDown = (DragDownDetails details) {
          logs.add('down');
        }
        ..onUpdate = (DragUpdateDetails details) {
          logs.add('update');
        }
        ..onCancel = () {
          logs.add('cancel');
        }
        ..onEnd = (DragEndDetails details) {
          logs.add('end');
        };
    });

    tearDown(() {
      pan.dispose();
      tap.dispose();
      logs.clear();
    });

    testGesture('Button change before acceptance should lead to immediate cancel', (GestureTester tester) {
      final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
      pan.addPointer(down);
      tap.addPointer(down);
      tester.closeArena(5);

      tester.route(down);
      expect(logs, <String>['down']);
      // Move out of slop so make sure button changes takes priority over slops
      tester.route(pointer.move(const Offset(30.0, 30.0), buttons: kSecondaryButton));
      expect(logs, <String>['down', 'cancel']);

      tester.route(pointer.up());
    });

    testGesture('Button change before acceptance should not prevent the next drag', (GestureTester tester) {
      { // First drag (which is canceled)
        final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
        final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
        pan.addPointer(down);
        tap.addPointer(down);
        tester.closeArena(down.pointer);

        tester.route(down);
        tester.route(pointer.move(const Offset(10.0, 10.0), buttons: kSecondaryButton));
        tester.route(pointer.up());
        expect(logs, <String>['down', 'cancel']);
      }
      logs.clear();

      final TestPointer pointer2 = TestPointer(6, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 10.0));
      pan.addPointer(down2);
      tap.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      expect(logs, <String>['down']);

      tester.route(pointer2.move(const Offset(30.0, 30.0)));
      expect(logs, <String>['down', 'start']);

      tester.route(pointer2.up());
      expect(logs, <String>['down', 'start', 'end']);
    });

    testGesture('Button change after acceptance should lead to immediate end', (GestureTester tester) {
      final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
      pan.addPointer(down);
      tap.addPointer(down);
      tester.closeArena(down.pointer);

      tester.route(down);
      expect(logs, <String>['down']);
      tester.route(pointer.move(const Offset(30.0, 30.0)));
      expect(logs, <String>['down', 'start']);
      tester.route(pointer.move(const Offset(30.0, 30.0), buttons: kSecondaryButton));
      expect(logs, <String>['down', 'start', 'end']);

      // Make sure no further updates are sent
      tester.route(pointer.move(const Offset(50.0, 50.0)));
      expect(logs, <String>['down', 'start', 'end']);

      tester.route(pointer.up());
    });

    testGesture('Button change after acceptance should not prevent the next drag', (GestureTester tester) {
      { // First drag (which is canceled)
        final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
        final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
        pan.addPointer(down);
        tap.addPointer(down);
        tester.closeArena(down.pointer);

        tester.route(down);

        tester.route(pointer.move(const Offset(30.0, 30.0)));

        tester.route(pointer.move(const Offset(30.0, 31.0), buttons: kSecondaryButton));
        tester.route(pointer.up());
        expect(logs, <String>['down', 'start', 'end']);
      }
      logs.clear();

      final TestPointer pointer2 = TestPointer(6, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 10.0));
      pan.addPointer(down2);
      tap.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      expect(logs, <String>['down']);

      tester.route(pointer2.move(const Offset(30.0, 30.0)));
      expect(logs, <String>['down', 'start']);

      tester.route(pointer2.up());
      expect(logs, <String>['down', 'start', 'end']);
    });
  });

  group('Recognizers listening on different buttons do not form competition:', () {
    // This test is assisted by tap recognizers. If a tap gesture has
    // no competing recognizers, a pointer down event triggers its onTapDown
    // immediately; if there are competitors, onTapDown is triggered after a
    // timeout.
    // The following tests make sure that drag recognizers do not form
    // competition with a tap gesture recognizer listening on a different button.

    final List<String> recognized = <String>[];
    late TapGestureRecognizer tapPrimary;
    late TapGestureRecognizer tapSecondary;
    late PanGestureRecognizer pan;
    setUp(() {
      tapPrimary = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) {
          recognized.add('tapPrimary');
        };
      tapSecondary = TapGestureRecognizer()
        ..onSecondaryTapDown = (TapDownDetails details) {
          recognized.add('tapSecondary');
        };
      pan = PanGestureRecognizer()
        ..onStart = (_) {
          recognized.add('drag');
        };
    });

    tearDown(() {
      recognized.clear();
      tapPrimary.dispose();
      tapSecondary.dispose();
      pan.dispose();
    });

    testGesture('A primary pan recognizer does not form competition with a secondary tap recognizer', (GestureTester tester) {
      final TestPointer pointer = TestPointer(
        1,
        PointerDeviceKind.touch,
        0,
        kSecondaryButton,
      );
      final PointerDownEvent down = pointer.down(const Offset(10, 10));
      pan.addPointer(down);
      tapSecondary.addPointer(down);
      tester.closeArena(down.pointer);

      tester.route(down);
      expect(recognized, <String>['tapSecondary']);
    });

    testGesture('A primary pan recognizer forms competition with a primary tap recognizer', (GestureTester tester) {
      final TestPointer pointer = TestPointer(
        1,
        PointerDeviceKind.touch,
        kPrimaryButton,
      );
      final PointerDownEvent down = pointer.down(const Offset(10, 10));
      pan.addPointer(down);
      tapPrimary.addPointer(down);
      tester.closeArena(down.pointer);

      tester.route(down);
      expect(recognized, <String>[]);

      tester.route(pointer.up());
      expect(recognized, <String>['tapPrimary']);
    });
  });

  testGesture('A secondary drag should not trigger primary', (GestureTester tester) {
    final List<String> recognized = <String>[];
    final TapGestureRecognizer tap = TapGestureRecognizer()
      ..onTap = () {}; // Need a listener to enable competition.
    final PanGestureRecognizer pan = PanGestureRecognizer()
      ..onDown = (DragDownDetails details) {
        recognized.add('primaryDown');
      }
      ..onStart = (DragStartDetails details) {
        recognized.add('primaryStart');
      }
      ..onUpdate = (DragUpdateDetails details) {
        recognized.add('primaryUpdate');
      }
      ..onEnd = (DragEndDetails details) {
        recognized.add('primaryEnd');
      }
      ..onCancel = () {
        recognized.add('primaryCancel');
      };
    addTearDown(pan.dispose);
    addTearDown(tap.dispose);

    final TestPointer pointer = TestPointer(
      5,
      PointerDeviceKind.touch,
      0,
      kSecondaryButton,
    );

    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    tester.closeArena(5);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 30.0)));
    tester.route(pointer.move(const Offset(20.0, 25.0)));
    tester.route(pointer.up());
    expect(recognized, <String>[]);
    recognized.clear();
  });

  testGesture('A secondary drag should not trigger primary', (GestureTester tester) {
    final List<String> recognized = <String>[];
    final TapGestureRecognizer tap = TapGestureRecognizer()
      ..onTap = () {}; // Need a listener to enable competition.
    final PanGestureRecognizer pan = PanGestureRecognizer()
      ..onDown = (DragDownDetails details) {
        recognized.add('primaryDown');
      }
      ..onStart = (DragStartDetails details) {
        recognized.add('primaryStart');
      }
      ..onUpdate = (DragUpdateDetails details) {
        recognized.add('primaryUpdate');
      }
      ..onEnd = (DragEndDetails details) {
        recognized.add('primaryEnd');
      }
      ..onCancel = () {
        recognized.add('primaryCancel');
      };

    final TestPointer pointer = TestPointer(
      5,
      PointerDeviceKind.touch,
      0,
      kSecondaryButton,
    );

    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    tester.closeArena(5);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 30.0)));
    tester.route(pointer.move(const Offset(20.0, 25.0)));
    tester.route(pointer.up());
    expect(recognized, <String>[]);
    recognized.clear();

    addTearDown(pan.dispose);
    addTearDown(tap.dispose);
    recognized.clear();
  });

  testGesture(
    'On multiple pointers, DragGestureRecognizer is canceled '
    'when all pointers are canceled (FIFO)',
    (GestureTester tester) {
      // This test simulates the following scenario:
      // P1 down, P2 down, P1 up, P2 up
      final List<String> logs = <String>[];
      final HorizontalDragGestureRecognizer hori = HorizontalDragGestureRecognizer()
        ..onDown = (DragDownDetails details) { logs.add('downH'); }
        ..onStart = (DragStartDetails details) { logs.add('startH'); }
        ..onUpdate = (DragUpdateDetails details) { logs.add('updateH'); }
        ..onEnd = (DragEndDetails details) { logs.add('endH'); }
        ..onCancel = () { logs.add('cancelH'); };
      // Competitor
      final TapGestureRecognizer vert = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) { logs.add('downT'); }
        ..onTapUp = (TapUpDetails details) { logs.add('upT'); }
        ..onTapCancel = () {};
      addTearDown(hori.dispose);
      addTearDown(vert.dispose);

      final TestPointer pointer1 = TestPointer(4);
      final TestPointer pointer2 = TestPointer(5);

      final PointerDownEvent down1 = pointer1.down(const Offset(10.0, 10.0));
      final PointerDownEvent down2 = pointer2.down(const Offset(11.0, 10.0));

      hori.addPointer(down1);
      vert.addPointer(down1);
      tester.route(down1);
      tester.closeArena(pointer1.pointer);
      expect(logs, <String>['downH']);
      logs.clear();

      hori.addPointer(down2);
      vert.addPointer(down2);
      tester.route(down2);
      tester.closeArena(pointer2.pointer);
      expect(logs, <String>[]);
      logs.clear();

      tester.route(pointer1.up());
      GestureBinding.instance.gestureArena.sweep(pointer1.pointer);
      expect(logs, <String>['downT', 'upT']);
      logs.clear();

      tester.route(pointer2.up());
      GestureBinding.instance.gestureArena.sweep(pointer2.pointer);
      expect(logs, <String>['cancelH']);
      logs.clear();
    },
  );

  testGesture(
    'On multiple pointers, DragGestureRecognizer is canceled '
    'when all pointers are canceled (FILO)',
    (GestureTester tester) {
      // This test simulates the following scenario:
      // P1 down, P2 down, P1 up, P2 up
      final List<String> logs = <String>[];
      final HorizontalDragGestureRecognizer hori = HorizontalDragGestureRecognizer()
        ..onDown = (DragDownDetails details) { logs.add('downH'); }
        ..onStart = (DragStartDetails details) { logs.add('startH'); }
        ..onUpdate = (DragUpdateDetails details) { logs.add('updateH'); }
        ..onEnd = (DragEndDetails details) { logs.add('endH'); }
        ..onCancel = () { logs.add('cancelH'); };
      // Competitor
      final TapGestureRecognizer vert = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) { logs.add('downT'); }
        ..onTapUp = (TapUpDetails details) { logs.add('upT'); }
        ..onTapCancel = () {};
      addTearDown(hori.dispose);
      addTearDown(vert.dispose);

      final TestPointer pointer1 = TestPointer(4);
      final TestPointer pointer2 = TestPointer(5);

      final PointerDownEvent down1 = pointer1.down(const Offset(10.0, 10.0));
      final PointerDownEvent down2 = pointer2.down(const Offset(11.0, 10.0));

      hori.addPointer(down1);
      vert.addPointer(down1);
      tester.route(down1);
      tester.closeArena(pointer1.pointer);
      expect(logs, <String>['downH']);
      logs.clear();

      hori.addPointer(down2);
      vert.addPointer(down2);
      tester.route(down2);
      tester.closeArena(pointer2.pointer);
      expect(logs, <String>[]);
      logs.clear();

      tester.route(pointer2.up());
      GestureBinding.instance.gestureArena.sweep(pointer2.pointer);
      // Tap is not triggered because pointer2 is not its primary pointer
      expect(logs, <String>[]);
      logs.clear();

      tester.route(pointer1.up());
      GestureBinding.instance.gestureArena.sweep(pointer1.pointer);
      expect(logs, <String>['cancelH', 'downT', 'upT']);
      logs.clear();
    },
  );

  testGesture(
    'On multiple pointers, DragGestureRecognizer is accepted when the '
    'first pointer is accepted',
    (GestureTester tester) {
      // This test simulates the following scenario:
      // P1 down, P2 down, P1 moves away, P2 up
      final List<String> logs = <String>[];
      final HorizontalDragGestureRecognizer hori = HorizontalDragGestureRecognizer()
        ..onDown = (DragDownDetails details) { logs.add('downH'); }
        ..onStart = (DragStartDetails details) { logs.add('startH'); }
        ..onUpdate = (DragUpdateDetails details) { logs.add('updateH'); }
        ..onEnd = (DragEndDetails details) { logs.add('endH'); }
        ..onCancel = () { logs.add('cancelH'); };
      // Competitor
      final TapGestureRecognizer vert = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) { logs.add('downT'); }
        ..onTapUp = (TapUpDetails details) { logs.add('upT'); }
        ..onTapCancel = () {};
      addTearDown(hori.dispose);
      addTearDown(vert.dispose);

      final TestPointer pointer1 = TestPointer(4);
      final TestPointer pointer2 = TestPointer(5);

      final PointerDownEvent down1 = pointer1.down(const Offset(10.0, 10.0));
      final PointerDownEvent down2 = pointer2.down(const Offset(11.0, 10.0));

      hori.addPointer(down1);
      vert.addPointer(down1);
      tester.route(down1);
      tester.closeArena(pointer1.pointer);
      expect(logs, <String>['downH']);
      logs.clear();

      hori.addPointer(down2);
      vert.addPointer(down2);
      tester.route(down2);
      tester.closeArena(pointer2.pointer);
      expect(logs, <String>[]);
      logs.clear();

      tester.route(pointer1.move(const Offset(100, 100)));
      expect(logs, <String>['startH']);
      logs.clear();

      tester.route(pointer2.up());
      GestureBinding.instance.gestureArena.sweep(pointer2.pointer);
      expect(logs, <String>[]);
      logs.clear();

      tester.route(pointer1.up());
      GestureBinding.instance.gestureArena.sweep(pointer1.pointer);
      expect(logs, <String>['endH']);
      logs.clear();
    },
  );

  testGesture(
    'On multiple pointers, canceled pointers (due to up) do not '
    'prevent later pointers getting accepted',
    (GestureTester tester) {
      // This test simulates the following scenario:
      // P1 down, P2 down, P1 Up, P2 moves away
      final List<String> logs = <String>[];
      final HorizontalDragGestureRecognizer hori = HorizontalDragGestureRecognizer()
        ..onDown = (DragDownDetails details) { logs.add('downH'); }
        ..onStart = (DragStartDetails details) { logs.add('startH'); }
        ..onUpdate = (DragUpdateDetails details) { logs.add('updateH'); }
        ..onEnd = (DragEndDetails details) { logs.add('endH'); }
        ..onCancel = () { logs.add('cancelH'); };
      // Competitor
      final TapGestureRecognizer vert = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) { logs.add('downT'); }
        ..onTapUp = (TapUpDetails details) { logs.add('upT'); }
        ..onTapCancel = () {};
      addTearDown(hori.dispose);
      addTearDown(vert.dispose);

      final TestPointer pointer1 = TestPointer(4);
      final TestPointer pointer2 = TestPointer(5);

      final PointerDownEvent down1 = pointer1.down(const Offset(10.0, 10.0));
      final PointerDownEvent down2 = pointer2.down(const Offset(11.0, 10.0));

      hori.addPointer(down1);
      vert.addPointer(down1);
      tester.route(down1);
      tester.closeArena(pointer1.pointer);
      expect(logs, <String>['downH']);
      logs.clear();

      hori.addPointer(down2);
      vert.addPointer(down2);
      tester.route(down2);
      tester.closeArena(pointer2.pointer);
      expect(logs, <String>[]);
      logs.clear();

      tester.route(pointer1.up());
      GestureBinding.instance.gestureArena.sweep(pointer1.pointer);
      expect(logs, <String>['downT', 'upT']);
      logs.clear();

      tester.route(pointer2.move(const Offset(100, 100)));
      expect(logs, <String>['startH']);
      logs.clear();

      tester.route(pointer2.up());
      GestureBinding.instance.gestureArena.sweep(pointer2.pointer);
      expect(logs, <String>['endH']);
      logs.clear();
    },
  );

  testGesture(
    'On multiple pointers, canceled pointers (due to buttons) do not '
    'prevent later pointers getting accepted',
    (GestureTester tester) {
      // This test simulates the following scenario:
      // P1 down, P2 down, P1 change buttons, P2 moves away
      final List<String> logs = <String>[];
      final HorizontalDragGestureRecognizer hori = HorizontalDragGestureRecognizer()
        ..onDown = (DragDownDetails details) { logs.add('downH'); }
        ..onStart = (DragStartDetails details) { logs.add('startH'); }
        ..onUpdate = (DragUpdateDetails details) { logs.add('updateH'); }
        ..onEnd = (DragEndDetails details) { logs.add('endH'); }
        ..onCancel = () { logs.add('cancelH'); };
      // Competitor
      final TapGestureRecognizer vert = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) { logs.add('downT'); }
        ..onTapUp = (TapUpDetails details) { logs.add('upT'); }
        ..onTapCancel = () {};
      addTearDown(hori.dispose);
      addTearDown(vert.dispose);

      final TestPointer pointer1 = TestPointer();
      final TestPointer pointer2 = TestPointer(2);

      final PointerDownEvent down1 = pointer1.down(const Offset(10.0, 10.0));
      final PointerDownEvent down2 = pointer2.down(const Offset(11.0, 10.0));

      hori.addPointer(down1);
      vert.addPointer(down1);
      tester.route(down1);
      tester.closeArena(pointer1.pointer);

      hori.addPointer(down2);
      vert.addPointer(down2);
      tester.route(down2);
      tester.closeArena(pointer2.pointer);
      expect(logs, <String>['downH']);
      logs.clear();

      // Pointer 1 changes buttons, which cancel tap, leaving drag the only
      // remaining member of arena 1, therefore drag is accepted.
      tester.route(pointer1.move(const Offset(9.9, 9.9), buttons: kSecondaryButton));
      expect(logs, <String>['startH']);
      logs.clear();

      tester.route(pointer2.move(const Offset(100, 100)));
      expect(logs, <String>['updateH']);
      logs.clear();

      tester.route(pointer2.up());
      GestureBinding.instance.gestureArena.sweep(pointer2.pointer);
      expect(logs, <String>['endH']);
      logs.clear();
    },
  );

  testGesture(
    'On multiple pointers, the last tracking pointer can be rejected by [resolvePointer] when the '
    'other pointer already accepted the VerticalDragGestureRecognizer',
    (GestureTester tester) {
      // Regressing test for https://github.com/flutter/flutter/issues/68373
      final List<String> logs = <String>[];
      final VerticalDragGestureRecognizer drag = VerticalDragGestureRecognizer()
        ..onDown = (DragDownDetails details) { logs.add('downD'); }
        ..onStart = (DragStartDetails details) { logs.add('startD'); }
        ..onUpdate = (DragUpdateDetails details) { logs.add('updateD'); }
        ..onEnd = (DragEndDetails details) { logs.add('endD'); }
        ..onCancel = () { logs.add('cancelD'); };
      // Competitor
      final TapGestureRecognizer tap = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) { logs.add('downT'); }
        ..onTapUp = (TapUpDetails details) { logs.add('upT'); }
        ..onTapCancel = () {};
      addTearDown(tap.dispose);
      addTearDown(drag.dispose);

      final TestPointer pointer1 = TestPointer();
      final TestPointer pointer2 = TestPointer(2);
      final TestPointer pointer3 = TestPointer(3);
      final TestPointer pointer4 = TestPointer(4);

      final PointerDownEvent down1 = pointer1.down(const Offset(10.0, 10.0));
      final PointerDownEvent down2 = pointer2.down(const Offset(11.0, 11.0));
      final PointerDownEvent down3 = pointer3.down(const Offset(12.0, 12.0));
      final PointerDownEvent down4 = pointer4.down(const Offset(13.0, 13.0));

      tap.addPointer(down1);
      drag.addPointer(down1);
      tester.closeArena(pointer1.pointer);
      tester.route(down1);
      expect(logs, <String>['downD']);
      logs.clear();

      tap.addPointer(down2);
      drag.addPointer(down2);
      tester.closeArena(pointer2.pointer);
      tester.route(down2);
      expect(logs, <String>[]);

      tap.addPointer(down3);
      drag.addPointer(down3);
      tester.closeArena(pointer3.pointer);
      tester.route(down3);
      expect(logs, <String>[]);

      drag.addPointer(down4);
      tester.closeArena(pointer4.pointer);
      tester.route(down4);
      expect(logs, <String>['startD']);
      logs.clear();

      tester.route(pointer2.up());
      GestureBinding.instance.gestureArena.sweep(pointer2.pointer);
      expect(logs, <String>[]);

      tester.route(pointer4.cancel());
      expect(logs, <String>[]);

      tester.route(pointer3.cancel());
      expect(logs, <String>[]);

      tester.route(pointer1.cancel());
      expect(logs, <String>['endD']);
      logs.clear();
    },
  );

  testGesture('Does not crash when one of the 2 pointers wins by default and is then released', (GestureTester tester) {
    // Regression test for https://github.com/flutter/flutter/issues/82784

    bool didStartDrag = false;
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer()
      ..onStart = (_) { didStartDrag = true; }
      ..onEnd = (DragEndDetails details) {} // Crash triggers at onEnd.
      ..dragStartBehavior = DragStartBehavior.down;
    final TapGestureRecognizer tap = TapGestureRecognizer()..onTap = () {};
    final TapGestureRecognizer tap2 = TapGestureRecognizer()..onTap = () {};

    // The pointer1 is caught by drag and tap.
    final TestPointer pointer1 = TestPointer(5);
    final PointerDownEvent down1 = pointer1.down(const Offset(10.0, 10.0));
    drag.addPointer(down1);
    tap.addPointer(down1);
    tester.closeArena(pointer1.pointer);
    tester.route(down1);

    // The pointer2 is caught by drag and tap2.
    final TestPointer pointer2 = TestPointer(6);
    final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 10.0));
    drag.addPointer(down2);
    tap2.addPointer(down2);
    tester.closeArena(pointer2.pointer);
    tester.route(down2);

    // The tap is disposed, leaving drag the default winner.
    tap.dispose();

    // Wait for microtasks to finish, during which drag claims victory.
    tester.async.flushMicrotasks();
    expect(didStartDrag, true);

    // The pointer1 is released, leaving pointer2 drag's only pointer.
    tester.route(pointer1.up());

    drag.dispose();

    // Passes if no crashes here.

    tap2.dispose();
  });

  testGesture('Should recognize pan gestures from platform', (GestureTester tester) {
    final PanGestureRecognizer pan = PanGestureRecognizer();
    // We need a competing gesture recognizer so that the gesture is not immediately claimed.
    final PanGestureRecognizer competingPan = PanGestureRecognizer();
    addTearDown(pan.dispose);
    addTearDown(competingPan.dispose);

    bool didStartPan = false;
    pan.onStart = (_) {
      didStartPan = true;
    };

    Offset? updatedScrollDelta;
    pan.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
    };

    bool didEndPan = false;
    pan.onEnd = (DragEndDetails details) {
      didEndPan = true;
    };

    final TestPointer pointer = TestPointer(2, PointerDeviceKind.trackpad);
    final PointerPanZoomStartEvent start = pointer.panZoomStart(const Offset(10.0, 10.0));
    pan.addPointerPanZoom(start);
    competingPan.addPointerPanZoom(start);
    tester.closeArena(2);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    tester.route(start);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    // Gesture will be claimed when distance reaches kPanSlop, which was 36.0 when this test was last updated.
    tester.route(pointer.panZoomUpdate(const Offset(10.0, 10.0), pan: const Offset(20.0, 20.0))); // moved 20 horizontally and 20 vertically which is 28 total
    expect(didStartPan, isFalse); // 28 < 36
    tester.route(pointer.panZoomUpdate(const Offset(10.0, 10.0), pan: const Offset(30.0, 30.0))); // moved 30 horizontally and 30 vertically which is 42 total
    expect(didStartPan, isTrue); // 42 > 36
    didStartPan = false;
    expect(didEndPan, isFalse);

    tester.route(pointer.panZoomUpdate(const Offset(10.0, 10.0), pan: const Offset(30.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(0.0, -5.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);

    tester.route(pointer.panZoomEnd());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);
    didEndPan = false;
  });

  testGesture('Pointer pan/zooms drags should allow touches to join them', (GestureTester tester) {
    final PanGestureRecognizer pan = PanGestureRecognizer();
    // We need a competing gesture recognizer so that the gesture is not immediately claimed.
    final PanGestureRecognizer competingPan = PanGestureRecognizer();
    addTearDown(pan.dispose);
    addTearDown(competingPan.dispose);

    bool didStartPan = false;
    pan.onStart = (_) {
      didStartPan = true;
    };

    Offset? updatedScrollDelta;
    pan.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
    };

    bool didEndPan = false;
    pan.onEnd = (DragEndDetails details) {
      didEndPan = true;
    };

    final TestPointer panZoomPointer = TestPointer(2, PointerDeviceKind.trackpad);
    final TestPointer touchPointer = TestPointer(3);
    final PointerPanZoomStartEvent start = panZoomPointer.panZoomStart(const Offset(10.0, 10.0));
    pan.addPointerPanZoom(start);
    competingPan.addPointerPanZoom(start);
    tester.closeArena(2);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    tester.route(start);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    // Gesture will be claimed when distance reaches kPanSlop, which was 36.0 when this test was last updated.
    tester.route(panZoomPointer.panZoomUpdate(const Offset(10.0, 10.0), pan: const Offset(20.0, 20.0))); // moved 20 horizontally and 20 vertically which is 28 total
    expect(didStartPan, isFalse); // 28 < 36
    tester.route(panZoomPointer.panZoomUpdate(const Offset(10.0, 10.0), pan: const Offset(30.0, 30.0))); // moved 30 horizontally and 30 vertically which is 42 total
    expect(didStartPan, isTrue); // 42 > 36
    didStartPan = false;
    expect(didEndPan, isFalse);

    tester.route(panZoomPointer.panZoomUpdate(const Offset(10.0, 10.0), pan: const Offset(30.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(0.0, -5.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);

    final PointerDownEvent touchDown = touchPointer.down(const Offset(20.0, 20.0));
    pan.addPointer(touchDown);
    competingPan.addPointer(touchDown);
    tester.closeArena(3);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    tester.route(touchPointer.move(const Offset(25.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(5.0, 5.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);

    // One pointer up. Give up all pointers.
    tester.route(touchPointer.up());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);

    tester.route(panZoomPointer.panZoomEnd());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);
    didEndPan = false;
  });

testGesture('Touch drags should allow pointer pan/zooms to join them', (GestureTester tester) {
    final PanGestureRecognizer pan = PanGestureRecognizer();
    // We need a competing gesture recognizer so that the gesture is not immediately claimed.
    final PanGestureRecognizer competingPan = PanGestureRecognizer();
    addTearDown(pan.dispose);
    addTearDown(competingPan.dispose);

    bool didStartPan = false;
    pan.onStart = (_) {
      didStartPan = true;
    };

    Offset? updatedScrollDelta;
    pan.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
    };

    bool didEndPan = false;
    pan.onEnd = (DragEndDetails details) {
      didEndPan = true;
    };

    final TestPointer panZoomPointer = TestPointer(2, PointerDeviceKind.trackpad);
    final TestPointer touchPointer = TestPointer(3);
    final PointerDownEvent touchDown = touchPointer.down(const Offset(20.0, 20.0));
    pan.addPointer(touchDown);
    competingPan.addPointer(touchDown);
    tester.closeArena(3);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    tester.route(touchPointer.move(const Offset(60.0, 60.0)));
    expect(didStartPan, isTrue);
    didStartPan = false;
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    tester.route(touchPointer.move(const Offset(70.0, 70.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(10.0, 10.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);

    // Another pointer joins.
    final PointerPanZoomStartEvent start = panZoomPointer.panZoomStart(const Offset(10.0, 10.0));
    pan.addPointerPanZoom(start);
    competingPan.addPointerPanZoom(start);
    tester.closeArena(2);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    tester.route(start);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);

    // The touchPointer moves by (10, 10), and the panZoomPointer moves by (30, 30). As a result,
    // the gesture moves by (30, 30).
    tester.route(touchPointer.move(const Offset(80.0, 80.0)));
    tester.route(panZoomPointer.panZoomUpdate(const Offset(10.0, 10.0), pan: const Offset(30.0, 30.0))); // moved 30 horizontally and 30 vertically which is 42 total
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(30.0, 30.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);

    tester.route(panZoomPointer.panZoomEnd());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);

    tester.route(touchPointer.up());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);
    didEndPan = false;
  });
}
