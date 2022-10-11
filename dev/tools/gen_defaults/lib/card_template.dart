// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class CardTemplate extends TokenTemplate {
  const CardTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _${blockName}DefaultsM3 extends CardTheme {
  const _${blockName}DefaultsM3(this.context)
    : super(
        clipBehavior: Clip.none,
        elevation: ${elevation("md.comp.elevated-card.container")},
        margin: const EdgeInsets.all(4.0),
        shape: ${shape("md.comp.elevated-card.container")},
      );

  final BuildContext context;

  @override
  Color? get color => ${componentColor("md.comp.elevated-card.container")};

  @override
  Color? get shadowColor => ${colorOrTransparent("md.comp.elevated-card.container.shadow-color")};

  @override
  Color? get surfaceTintColor => ${colorOrTransparent("md.comp.elevated-card.container.surface-tint-layer.color")};
}
''';
}
