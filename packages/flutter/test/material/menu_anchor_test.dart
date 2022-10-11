// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuController controller;
  String? focusedMenu;
  final List<TestMenu> selected = <TestMenu>[];
  final List<TestMenu> opened = <TestMenu>[];
  final List<TestMenu> closed = <TestMenu>[];
  final GlobalKey menuItemKey = GlobalKey();
  late Size defaultSize;

  void onPressed(TestMenu item) {
    selected.add(item);
  }

  void onOpen(TestMenu item) {
    opened.add(item);
  }

  void onClose(TestMenu item) {
    closed.add(item);
  }

  void handleFocusChange() {
    focusedMenu = primaryFocus?.debugLabel ?? primaryFocus?.toString();
  }

  setUpAll(() {
    final MediaQueryData mediaQueryData = MediaQueryData.fromWindow(TestWidgetsFlutterBinding.instance.window);
    defaultSize = mediaQueryData.size;
  });

  setUp(() {
    focusedMenu = null;
    selected.clear();
    opened.clear();
    closed.clear();
    controller = MenuController();
    focusedMenu = null;
  });

  Future<void> changeSurfaceSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(defaultSize);
    });
  }

  void listenForFocusChanges() {
    FocusManager.instance.addListener(handleFocusChange);
    addTearDown(() => FocusManager.instance.removeListener(handleFocusChange));
  }

  Finder findMenuPanels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuPanel');
  }

  Finder findMenuBarItemLabels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuItemLabel');
  }

  // Finds the mnemonic associated with the menu item that has the given label.
  Finder findMnemonic(String label) {
    return find
        .descendant(
          of: find.ancestor(of: find.text(label), matching: findMenuBarItemLabels()),
          matching: find.byType(Text),
        )
        .last;
  }

  Widget buildTestApp({
    AlignmentGeometry? alignment,
    Offset alignmentOffset = Offset.zero,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final FocusNode focusNode = FocusNode();
    return MaterialApp(
      home: Material(
        child: Directionality(
          textDirection: textDirection,
          child: Center(
            child: MenuAnchor(
              childFocusNode: focusNode,
              controller: controller,
              alignmentOffset: alignmentOffset,
              style: MenuStyle(alignment: alignment),
              menuChildren: <Widget>[
                MenuItemButton(
                  key: menuItemKey,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyB,
                    control: true,
                  ),
                  onPressed: () {},
                  child: Text(TestMenu.subMenu00.label),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.send),
                  trailingIcon: const Icon(Icons.mail),
                  onPressed: () {},
                  child: Text(TestMenu.subMenu01.label),
                ),
              ],
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return ElevatedButton(
                  focusNode: focusNode,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: child,
                );
              },
              child: const Text('Press Me'),
            ),
          ),
        ),
      ),
    );
  }

  Future<TestGesture> hoverOver(WidgetTester tester, Finder finder) async {
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    return gesture;
  }

  Material getMenuBarMaterial(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(of: findMenuPanels(), matching: find.byType(Material)).first,
    );
  }

  group('Menu functions', () {
    testWidgets('basic menu structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu110.label), findsNothing);
      expect(opened, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu110.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu111.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu112.label), findsNothing);
      expect(opened.last, equals(TestMenu.mainMenu1));
      opened.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu110.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu111.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu112.label), findsOneWidget);
      expect(opened.last, equals(TestMenu.subMenu11));
    });

    testWidgets('geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(112.0, 69.0, 266.0, 83.0)),
      );
      expect(
        tester.getRect(
          find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1),
        ),
        equals(const Rect.fromLTRB(104.0, 48.0, 334.0, 200.0)),
      );
    });

    testWidgets('geometry with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MenuBar(
                          children: createTestMenus(onPressed: onPressed),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(534.0, 69.0, 688.0, 83.0)),
      );
      expect(
        tester.getRect(
          find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1),
        ),
        equals(const Rect.fromLTRB(466.0, 48.0, 696.0, 200.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Test menu bar size when not expanded.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  children: createTestMenus(onPressed: onPressed),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getRect(find.byType(MenuBar)),
        equals(const Rect.fromLTRB(246.0, 0.0, 554.0, 48.0)),
      );
    });

    testWidgets('menu alignment and offset in LTR', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope = find.ancestor(of: find.byKey(menuItemKey), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(328.0, 324.0, 618.0, 428.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.topStart));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(328.0, 276.0, 618.0, 380.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.center));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(400.0, 300.0, 690.0, 404.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.bottomEnd));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(472.0, 324.0, 762.0, 428.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.topStart));
      await tester.pump();

      final Rect menuRect = tester.getRect(findMenuScope);
      await tester.pumpWidget(
        buildTestApp(
          alignment: AlignmentDirectional.topStart,
          alignmentOffset: const Offset(10, 20),
        ),
      );
      await tester.pump();
      final Rect offsetMenuRect = tester.getRect(findMenuScope);
      expect(
        offsetMenuRect.topLeft - menuRect.topLeft,
        equals(const Offset(10, 20)),
      );
    });

    testWidgets('menu alignment and offset in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl));

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(182.0, 324.0, 472.0, 428.0)));

      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.topStart));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(182.0, 276.0, 472.0, 380.0)));

      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.center));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(110.0, 300.0, 400.0, 404.0)));

      await tester
          .pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.bottomEnd));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(38.0, 324.0, 328.0, 428.0)));

      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.topStart));
      await tester.pump();

      final Rect menuRect = tester.getRect(findMenuScope);
      await tester.pumpWidget(
        buildTestApp(
          textDirection: TextDirection.rtl,
          alignment: AlignmentDirectional.topStart,
          alignmentOffset: const Offset(10, 20),
        ),
      );
      await tester.pump();
      expect(tester.getRect(findMenuScope).topLeft - menuRect.topLeft, equals(const Offset(-10, 20)));
    });

    testWidgets('menu position in LTR', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(alignmentOffset: const Offset(100, 50)));

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(428.0, 374.0, 718.0, 478.0)));

      // Now move the menu by calling open() again with a local position on the
      // anchor.
      controller.open(position: const Offset(200, 200));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(510.0, 476.0, 800.0, 580.0)));
    });

    testWidgets('menu position in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        alignmentOffset: const Offset(100, 50),
        textDirection: TextDirection.rtl,
      ));

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(82.0, 374.0, 372.0, 478.0)));

      // Now move the menu by calling open() again with a local position on the
      // anchor.
      controller.open(position: const Offset(400, 200));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(510.0, 476.0, 800.0, 580.0)));
    });

    testWidgets('works with Padding around menu and overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: MenuBar(
                            children: createTestMenus(onPressed: onPressed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(134.0, 91.0, 288.0, 105.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(126.0, 70.0, 356.0, 222.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });

    testWidgets('works with Padding around menu and overlay with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: MenuBar(
                              children: createTestMenus(onPressed: onPressed),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: Placeholder()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(512.0, 91.0, 666.0, 105.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(444.0, 70.0, 674.0, 222.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });

    testWidgets('visual attributes can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        style: MenuStyle(
                          elevation: MaterialStateProperty.all<double?>(10),
                          backgroundColor: const MaterialStatePropertyAll<Color>(Colors.red),
                        ),
                        children: createTestMenus(onPressed: onPressed),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      expect(tester.getRect(findMenuPanels()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 48.0)));
      final Material material = getMenuBarMaterial(tester);
      expect(material.elevation, equals(10));
      expect(material.color, equals(Colors.red));
    });

    testWidgets('open and close works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(opened, isEmpty);
      expect(closed, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.subMenu11]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, equals(<TestMenu>[TestMenu.subMenu11]));
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu0]));
      expect(closed, equals(<TestMenu>[TestMenu.mainMenu1]));
    });

    testWidgets('select works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      await tester.tap(find.text(TestMenu.subSubMenu110.label));
      await tester.pump();

      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu110]));

      // Selecting a non-submenu item should close all the menus.
      expect(opened, isEmpty);
      expect(find.text(TestMenu.subSubMenu110.label), findsNothing);
      expect(find.text(TestMenu.subMenu11.label), findsNothing);
    });

    testWidgets('diagnostics', (WidgetTester tester) async {
      const MenuItemButton item = MenuItemButton(
        shortcut: SingleActivator(LogicalKeyboardKey.keyA),
        child: Text('label2'),
      );
      final MenuBar menuBar = MenuBar(
        controller: controller,
        style: const MenuStyle(
          backgroundColor: MaterialStatePropertyAll<Color>(Colors.red),
          elevation: MaterialStatePropertyAll<double?>(10.0),
        ),
        children: const <Widget>[item],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: menuBar,
          ),
        ),
      );
      await tester.pump();

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      menuBar.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(
        description.join('\n'),
        equalsIgnoringHashCodes(
            'style: MenuStyle#00000(backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336))), elevation: MaterialStatePropertyAll(10.0))\n'
            'clipBehavior: Clip.none'),
      );
    });

    testWidgets('keyboard tab traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  children: createTestMenus(
                    onPressed: onPressed,
                    onOpen: onOpen,
                    onClose: onClose,
                  ),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      opened.clear();
      closed.clear();

      // Test closing a menu with enter.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, isEmpty);
      expect(closed, <TestMenu>[TestMenu.mainMenu0]);
    });

    testWidgets('keyboard directional traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 111"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 112"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));
    });

    testWidgets('keyboard directional traversal works in RTL mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: MenuBar(
                controller: controller,
                children: createTestMenus(
                  onPressed: onPressed,
                  onOpen: onOpen,
                  onClose: onClose,
                ),
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 111"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 112"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));
    });

    testWidgets('hover traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Hovering when the menu is not yet open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, isNull);

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));

      // Hovering when the menu is already  open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));

      // Hovering over the other main menu items opens them now.
      await hoverOver(tester, find.text(TestMenu.mainMenu2.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));

      await hoverOver(tester, find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      // Hovering over the menu items focuses them.
      await hoverOver(tester, find.text(TestMenu.subMenu10.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await hoverOver(tester, find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      await hoverOver(tester, find.text(TestMenu.subSubMenu110.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));
    });

    testWidgets('menus close on ancestor scroll', (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                height: 1000,
                alignment: Alignment.center,
                child: MenuBar(
                  controller: controller,
                  children: createTestMenus(
                    onPressed: onPressed,
                    onOpen: onOpen,
                    onClose: onClose,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(opened, isNotEmpty);
      expect(closed, isEmpty);
      opened.clear();

      scrollController.jumpTo(1000);
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, isNotEmpty);
    });

    testWidgets('menus close on view size change', (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      final MediaQueryData mediaQueryData = MediaQueryData.fromWindow(tester.binding.window);

      Widget build(Size size) {
        return MaterialApp(
          home: Material(
            child: MediaQuery(
              data: mediaQueryData.copyWith(size: size),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Container(
                  height: 1000,
                  alignment: Alignment.center,
                  child: MenuBar(
                    controller: controller,
                    children: createTestMenus(
                      onPressed: onPressed,
                      onOpen: onOpen,
                      onClose: onClose,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(mediaQueryData.size));

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(opened, isNotEmpty);
      expect(closed, isEmpty);
      opened.clear();

      const Size smallSize = Size(200, 200);
      await changeSurfaceSize(tester, smallSize);

      await tester.pumpWidget(build(smallSize));
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, isNotEmpty);
    });
  });

  group('MenuController', () {
    testWidgets('Moving a controller to a new instance works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      // Now pump a new menu with a different UniqueKey to dispose of the opened
      // menu's node, but keep the existing controller.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('closing via controller works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  )
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(opened, unorderedEquals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      closed.clear();

      // Close menus using the controller
      controller.close();
      await tester.pump();

      // The menu should go away,
      expect(closed, unorderedEquals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      expect(opened, isEmpty);
    });
  });

  group('MenuItemButton', () {
    testWidgets('Shortcut mnemonics are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                  TestMenu.subSubMenu111: const SingleActivator(LogicalKeyboardKey.keyB, shift: true),
                  TestMenu.subSubMenu112: const SingleActivator(LogicalKeyboardKey.keyC, alt: true),
                  TestMenu.subSubMenu113: const SingleActivator(LogicalKeyboardKey.keyD, meta: true),
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      Text mnemonic0;
      Text mnemonic1;
      Text mnemonic2;
      Text mnemonic3;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
          expect(mnemonic3.data, equals('Meta D'));
          break;
        case TargetPlatform.windows:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
          expect(mnemonic3.data, equals('Win D'));
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
          expect(mnemonic0.data, equals('⌃ A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
          expect(mnemonic2.data, equals('⌥ C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
          expect(mnemonic3.data, equals('⌘ D'));
          break;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(LogicalKeyboardKey.arrowRight),
                  TestMenu.subSubMenu111: const SingleActivator(LogicalKeyboardKey.arrowLeft),
                  TestMenu.subSubMenu112: const SingleActivator(LogicalKeyboardKey.arrowUp),
                  TestMenu.subSubMenu113: const SingleActivator(LogicalKeyboardKey.arrowDown),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
      expect(mnemonic0.data, equals('→'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
      expect(mnemonic1.data, equals('←'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
      expect(mnemonic2.data, equals('↑'));
      mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
      expect(mnemonic3.data, equals('↓'));

      // Try some weirder ones.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(LogicalKeyboardKey.escape),
                  TestMenu.subSubMenu111: const SingleActivator(LogicalKeyboardKey.fn),
                  TestMenu.subSubMenu112: const SingleActivator(LogicalKeyboardKey.enter),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
      expect(mnemonic0.data, equals('Esc'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
      expect(mnemonic1.data, equals('Fn'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
      expect(mnemonic2.data, equals('↵'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('leadingIcon is used when set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      leadingIcon: const Text('leadingIcon'),
                      child: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('leadingIcon'), findsOneWidget);
    });

    testWidgets('trailingIcon is used when set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      trailingIcon: const Text('trailingIcon'),
                      child: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('trailingIcon'), findsOneWidget);
    });

    testWidgets('diagnostics', (WidgetTester tester) async {
      final ButtonStyle style = ButtonStyle(
        shape: MaterialStateProperty.all<OutlinedBorder?>(const StadiumBorder()),
        elevation: MaterialStateProperty.all<double?>(10.0),
        backgroundColor: const MaterialStatePropertyAll<Color>(Colors.red),
      );
      final MenuStyle menuStyle = MenuStyle(
        shape: MaterialStateProperty.all<OutlinedBorder?>(const RoundedRectangleBorder()),
        elevation: MaterialStateProperty.all<double?>(20.0),
        backgroundColor: const MaterialStatePropertyAll<Color>(Colors.green),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  style: style,
                  menuStyle: menuStyle,
                  menuChildren: <Widget>[
                    MenuItemButton(
                      style: style,
                      child: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      final SubmenuButton submenu = tester.widget(find.byType(SubmenuButton));
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      submenu.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(
        description,
        equalsIgnoringHashCodes(
          <String>[
            'child: Text("Menu 0")',
            'focusNode: null',
            'menuStyle: MenuStyle#00000(backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xff4caf50))), elevation: MaterialStatePropertyAll(20.0), shape: MaterialStatePropertyAll(RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.zero)))',
            'alignmentOffset: null',
            'clipBehavior: none',
          ],
        ),
      );
    });
  });

  group('Layout', () {
    List<Rect> collectMenuRects() {
      final List<Rect> menuRects = <Rect>[];
      final List<Element> candidates = find.byType(SubmenuButton).evaluate().toList();
      for (final Element candidate in candidates) {
        final RenderBox box = candidate.renderObject! as RenderBox;
        final Offset topLeft = box.localToGlobal(box.size.topLeft(Offset.zero));
        final Offset bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
        menuRects.add(Rect.fromPoints(topLeft, bottomRight));
      }
      return menuRects;
    }

    testWidgets('unconstrained menus show up in the right place in LTR', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(4.0, 0.0, 104.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(104.0, 0.0, 204.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(204.0, 0.0, 304.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(104.0, 100.0, 334.0, 148.0)));
    });

    testWidgets('unconstrained menus show up in the right place in RTL', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MenuBar(
                          children: createTestMenus(onPressed: onPressed),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(696.0, 0.0, 796.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(596.0, 0.0, 696.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(496.0, 0.0, 596.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(466.0, 100.0, 696.0, 148.0)));
    });

    testWidgets('constrained menus show up in the right place in LTR', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(300, 300));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                      const Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(4.0, 0.0, 104.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(104.0, 0.0, 204.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(204.0, 0.0, 304.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(70.0, 100.0, 300.0, 148.0)));
    });

    testWidgets('constrained menus show up in the right place in RTL', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(300, 300));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                      const Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(4));
      final List<Rect> menuRects = collectMenuRects();
      expect(menuRects[0], equals(const Rect.fromLTRB(196.0, 0.0, 296.0, 48.0)));
      expect(menuRects[1], equals(const Rect.fromLTRB(96.0, 0.0, 196.0, 48.0)));
      expect(menuRects[2], equals(const Rect.fromLTRB(-4.0, 0.0, 96.0, 48.0)));
      expect(menuRects[3], equals(const Rect.fromLTRB(0.0, 100.0, 230.0, 148.0)));
    });
  });

  group('LocalizedShortcutLabeler', () {
    testWidgets('getShortcutLabel returns the right labels', (WidgetTester tester) async {
      String expectedMeta;
      String expectedCtrl;
      String expectedAlt;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          expectedCtrl = 'Ctrl';
          expectedMeta = 'Meta';
          expectedAlt = 'Alt';
          break;
        case TargetPlatform.windows:
          expectedCtrl = 'Ctrl';
          expectedMeta = 'Win';
          expectedAlt = 'Alt';
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expectedCtrl = '⌃';
          expectedMeta = '⌘';
          expectedAlt = '⌥';
          break;
      }

      const SingleActivator allModifiers = SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
        meta: true,
        shift: true,
        alt: true,
      );
      final String allExpected = '$expectedAlt $expectedCtrl $expectedMeta ⇧ A';
      const CharacterActivator charShortcuts = CharacterActivator('ñ');
      const String charExpected = 'ñ';
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      shortcut: allModifiers,
                      child: Text(TestMenu.subMenu10.label),
                    ),
                    MenuItemButton(
                      shortcut: charShortcuts,
                      child: Text(TestMenu.subMenu11.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text(allExpected), findsOneWidget);
      expect(find.text(charExpected), findsOneWidget);
    }, variant: TargetPlatformVariant.all());
  });

  group('CheckboxMenuButton', () {
    testWidgets('tapping toggles checkbox', (WidgetTester tester) async {
      bool? checkBoxValue;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MenuBar(
                children: <Widget>[
                  SubmenuButton(
                    menuChildren: <Widget>[
                      CheckboxMenuButton(
                        value: checkBoxValue,
                        onChanged: (bool? value) {
                          setState(() {
                            checkBoxValue = value;
                          });
                        },
                        tristate: true,
                        child: const Text('checkbox'),
                      )
                    ],
                    child: const Text('submenu'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();

      expect(tester.widget<CheckboxMenuButton>(find.byType(CheckboxMenuButton)).value, null);

      await tester.tap(find.byType(CheckboxMenuButton));
      await tester.pumpAndSettle();
      expect(checkBoxValue, false);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(CheckboxMenuButton));
      await tester.pumpAndSettle();
      expect(checkBoxValue, true);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(CheckboxMenuButton));
      await tester.pumpAndSettle();
      expect(checkBoxValue, null);
    });
  });

  group('RadioMenuButton', () {
    testWidgets('tapping toggles radio button', (WidgetTester tester) async {
      int? radioValue;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MenuBar(
                children: <Widget>[
                  SubmenuButton(
                    menuChildren: <Widget>[
                      RadioMenuButton<int>(
                        value: 0,
                        groupValue: radioValue,
                        onChanged: (int? value) {
                          setState(() {
                            radioValue = value;
                          });
                        },
                        toggleable: true,
                        child: const Text('radio 0'),
                      ),
                      RadioMenuButton<int>(
                        value: 1,
                        groupValue: radioValue,
                        onChanged: (int? value) {
                          setState(() {
                            radioValue = value;
                          });
                        },
                        toggleable: true,
                        child: const Text('radio 1'),
                      )
                    ],
                    child: const Text('submenu'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();

      expect(
        tester.widget<RadioMenuButton<int>>(find.byType(RadioMenuButton<int>).first).groupValue,
        null,
      );

      await tester.tap(find.byType(RadioMenuButton<int>).first);
      await tester.pumpAndSettle();
      expect(radioValue, 0);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(RadioMenuButton<int>).first);
      await tester.pumpAndSettle();
      expect(radioValue, null);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(RadioMenuButton<int>).last);
      await tester.pumpAndSettle();
      expect(radioValue, 1);
    });
  });
}

List<Widget> createTestMenus({
  void Function(TestMenu)? onPressed,
  void Function(TestMenu)? onOpen,
  void Function(TestMenu)? onClose,
  Map<TestMenu, MenuSerializableShortcut> shortcuts = const <TestMenu, MenuSerializableShortcut>{},
  bool includeStandard = false,
  bool includeExtraGroups = false,
}) {
  final List<Widget> result = <Widget>[
    SubmenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu0) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu0) : null,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu00) : null,
          shortcut: shortcuts[TestMenu.subMenu00],
          child: Text(TestMenu.subMenu00.label),
        ),
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu01) : null,
          shortcut: shortcuts[TestMenu.subMenu01],
          child: Text(TestMenu.subMenu01.label),
        ),
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu02) : null,
          shortcut: shortcuts[TestMenu.subMenu02],
          child: Text(TestMenu.subMenu02.label),
        ),
      ],
      child: Text(TestMenu.mainMenu0.label),
    ),
    SubmenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu1) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu1) : null,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu10) : null,
          shortcut: shortcuts[TestMenu.subMenu10],
          child: Text(TestMenu.subMenu10.label),
        ),
        SubmenuButton(
          onOpen: onOpen != null ? () => onOpen(TestMenu.subMenu11) : null,
          onClose: onClose != null ? () => onClose(TestMenu.subMenu11) : null,
          menuChildren: <Widget>[
            MenuItemButton(
              key: UniqueKey(),
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu110) : null,
              shortcut: shortcuts[TestMenu.subSubMenu110],
              child: Text(TestMenu.subSubMenu110.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu111) : null,
              shortcut: shortcuts[TestMenu.subSubMenu111],
              child: Text(TestMenu.subSubMenu111.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu112) : null,
              shortcut: shortcuts[TestMenu.subSubMenu112],
              child: Text(TestMenu.subSubMenu112.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu113) : null,
              shortcut: shortcuts[TestMenu.subSubMenu113],
              child: Text(TestMenu.subSubMenu113.label),
            ),
          ],
          child: Text(TestMenu.subMenu11.label),
        ),
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu12) : null,
          shortcut: shortcuts[TestMenu.subMenu12],
          child: Text(TestMenu.subMenu12.label),
        ),
      ],
      child: Text(TestMenu.mainMenu1.label),
    ),
    SubmenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu2) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu2) : null,
      menuChildren: <Widget>[
        MenuItemButton(
          // Always disabled.
          shortcut: shortcuts[TestMenu.subMenu20],
          child: Text(TestMenu.subMenu20.label),
        ),
      ],
      child: Text(TestMenu.mainMenu2.label),
    ),
    if (includeExtraGroups)
      SubmenuButton(
        onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu3) : null,
        onClose: onClose != null ? () => onClose(TestMenu.mainMenu3) : null,
        menuChildren: <Widget>[
          MenuItemButton(
            // Always disabled.
            shortcut: shortcuts[TestMenu.subMenu30],
            // Always disabled.
            child: Text(TestMenu.subMenu30.label),
          ),
        ],
        child: Text(TestMenu.mainMenu3.label),
      ),
    if (includeExtraGroups)
      SubmenuButton(
        onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu4) : null,
        onClose: onClose != null ? () => onClose(TestMenu.mainMenu4) : null,
        menuChildren: <Widget>[
          MenuItemButton(
            // Always disabled.
            shortcut: shortcuts[TestMenu.subMenu40],
            // Always disabled.
            child: Text(TestMenu.subMenu40.label),
          ),
          MenuItemButton(
            // Always disabled.
            shortcut: shortcuts[TestMenu.subMenu41],
            // Always disabled.
            child: Text(TestMenu.subMenu41.label),
          ),
          MenuItemButton(
            // Always disabled.
            shortcut: shortcuts[TestMenu.subMenu42],
            // Always disabled.
            child: Text(TestMenu.subMenu42.label),
          ),
        ],
        child: Text(TestMenu.mainMenu4.label),
      ),
  ];
  return result;
}

enum TestMenu {
  mainMenu0('Menu 0'),
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  mainMenu3('Menu 3'),
  mainMenu4('Menu 4'),
  subMenu00('Sub Menu 00'),
  subMenu01('Sub Menu 01'),
  subMenu02('Sub Menu 02'),
  subMenu10('Sub Menu 10'),
  subMenu11('Sub Menu 11'),
  subMenu12('Sub Menu 12'),
  subMenu20('Sub Menu 20'),
  subMenu30('Sub Menu 30'),
  subMenu40('Sub Menu 40'),
  subMenu41('Sub Menu 41'),
  subMenu42('Sub Menu 42'),
  subSubMenu110('Sub Sub Menu 110'),
  subSubMenu111('Sub Sub Menu 111'),
  subSubMenu112('Sub Sub Menu 112'),
  subSubMenu113('Sub Sub Menu 113');

  const TestMenu(this.label);
  final String label;
}
