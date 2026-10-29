import 'package:material_ui/material_ui.dart';

/// Branch container for the shell route: keeps every branch alive and
/// offstage like go_router's indexed stack, and fades the newly selected one
/// in with a slight settle (the incoming half of Material's fade through).
///
/// Each child keeps the same wrapper widgets whether it is active or not, so
/// switching never rebuilds a branch's state.
class BranchFadeThrough extends StatefulWidget {
  const BranchFadeThrough({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<BranchFadeThrough> createState() => _BranchFadeThroughState();
}

class _BranchFadeThroughState extends State<BranchFadeThrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.98,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  static const _still = AlwaysStoppedAnimation<double>(1);

  @override
  void didUpdateWidget(BranchFadeThrough oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (index, child) in widget.children.indexed)
          _branch(child, active: index == widget.currentIndex),
      ],
    );
  }

  Widget _branch(Widget child, {required bool active}) {
    return Offstage(
      offstage: !active,
      child: TickerMode(
        enabled: active,
        child: FadeTransition(
          opacity: active ? _opacity : _still,
          child: ScaleTransition(scale: active ? _scale : _still, child: child),
        ),
      ),
    );
  }
}
