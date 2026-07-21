import 'package:flutter/material.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';

/// Fade + rise entrance, the single micro-interaction reused everywhere content
/// appears (cards, list rows, sections). [index] staggers a list automatically.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final double offsetY;
  const FadeSlideIn({
    super.key, required this.child, this.index = 0,
    this.baseDelay = const Duration(milliseconds: 40), this.offsetY = 18,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: PremiumTokens.medium);
    _fade = CurvedAnimation(parent: _controller, curve: PremiumTokens.easeOut);
    _slide = Tween<Offset>(begin: Offset(0, widget.offsetY / 100), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: PremiumTokens.easeOut));
    final int clampedIndex = widget.index.clamp(0, 12);
    Future.delayed(widget.baseDelay * clampedIndex, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Scale-down-on-press wrapper — the tactile feedback every tappable premium
/// surface (buttons, cards) shares, instead of a plain InkWell ripple alone.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  const PressableScale({super.key, required this.child, this.onTap, this.pressedScale = 0.96});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: PremiumTokens.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
