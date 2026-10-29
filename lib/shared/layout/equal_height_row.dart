import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// A row of cards that all take the height of the tallest one.
///
/// `IntrinsicHeight` + a stretched `Row` would do the same, but it asks for
/// intrinsic sizes, which `LayoutBuilder` (used inside M3EButtonGroup) can't
/// report. This lays each child out for real at its share of the width, then
/// again with the tallest height.
///
/// Children are first laid out with unbounded height, so they must not
/// expand vertically on their own; use a `LayoutBuilder` and check
/// `hasBoundedHeight` to stretch in the second pass.
class EqualHeightRow extends MultiChildRenderObjectWidget {
  const EqualHeightRow({
    super.key,
    this.spacing = 0,
    this.flex = const [],
    required super.children,
  });

  final double spacing;

  /// Width share per child, in order; missing entries count as 1.
  final List<int> flex;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderEqualHeightRow(
    spacing: spacing,
    flex: flex,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderEqualHeightRow renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..flex = flex
      ..textDirection = Directionality.of(context);
  }
}

class _EqualHeightParentData extends ContainerBoxParentData<RenderBox> {}

/// Render object for [EqualHeightRow].
class RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualHeightParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightParentData> {
  RenderEqualHeightRow({
    required this._spacing,
    required this._flex,
    required this._textDirection,
  });

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  List<int> _flex;
  set flex(List<int> value) {
    if (listEquals(value, _flex)) return;
    _flex = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightParentData) {
      child.parentData = _EqualHeightParentData();
    }
  }

  List<double> _widths(double maxWidth, int count) {
    final flexes = [
      for (var i = 0; i < count; i++) i < _flex.length ? _flex[i] : 1,
    ];
    final total = flexes.fold(0, (sum, f) => sum + f);
    final available = math.max(0.0, maxWidth - _spacing * (count - 1));
    return [for (final f in flexes) available * f / total];
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    final children = getChildrenAsList();
    if (children.isEmpty) {
      size = constraints.smallest;
      return;
    }
    final widths = _widths(constraints.maxWidth, children.length);

    var height = 0.0;
    for (var i = 0; i < children.length; i++) {
      children[i].layout(
        BoxConstraints.tightFor(width: widths[i]),
        parentUsesSize: true,
      );
      height = math.max(height, children[i].size.height);
    }
    height = constraints.constrainHeight(height);

    var x = 0.0;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      child.layout(
        BoxConstraints.tightFor(width: widths[i], height: height),
        parentUsesSize: true,
      );
      (child.parentData! as _EqualHeightParentData).offset = Offset(
        _textDirection == TextDirection.rtl
            ? constraints.maxWidth - x - widths[i]
            : x,
        0,
      );
      x += widths[i] + _spacing;
    }
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _maxChildHeight(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _maxChildHeight(width, (child, w) => child.getMaxIntrinsicHeight(w));

  double _maxChildHeight(
    double width,
    double Function(RenderBox child, double width) measure,
  ) {
    final children = getChildrenAsList();
    if (children.isEmpty || !width.isFinite) return 0;
    final widths = _widths(width, children.length);
    var height = 0.0;
    for (var i = 0; i < children.length; i++) {
      height = math.max(height, measure(children[i], widths[i]));
    }
    return height;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
