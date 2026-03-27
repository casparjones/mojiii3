import 'package:flutter/material.dart';
import '../models/gem_type.dart';
import 'gem_painter.dart';

/// Widget that renders a gem with idle shimmer and pulse animations.
class GemWidget extends StatefulWidget {
  final GemVisualDef visual;
  final double size;
  final bool highlighted;
  final bool animate;
  final VoidCallback? onTap;

  const GemWidget({
    super.key,
    required this.visual,
    this.size = 48.0,
    this.highlighted = false,
    this.animate = true,
    this.onTap,
  });

  /// Convenience constructor from a Gem model.
  factory GemWidget.fromGem({
    Key? key,
    required Gem gem,
    double size = 48.0,
    bool highlighted = false,
    bool animate = true,
    VoidCallback? onTap,
  }) {
    return GemWidget(
      key: key,
      visual: gem.visual,
      size: size,
      highlighted: highlighted,
      animate: animate,
      onTap: onTap,
    );
  }

  @override
  State<GemWidget> createState() => _GemWidgetState();
}

class _GemWidgetState extends State<GemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (3000 / widget.visual.shimmerSpeed).round(),
      ),
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(GemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (oldWidget.visual.shimmerSpeed != widget.visual.shimmerSpeed) {
      _controller.duration = Duration(
        milliseconds: (3000 / widget.visual.shimmerSpeed).round(),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: GemPainter(
              visual: widget.visual,
              shimmerProgress: _shimmerAnimation.value,
              pulseScale: _pulseAnimation.value,
              highlighted: widget.highlighted,
            ),
          );
        },
      ),
    );
  }
}

/// Displays a grid preview of all gem visual variants.
class GemCatalogWidget extends StatelessWidget {
  final double gemSize;

  const GemCatalogWidget({super.key, this.gemSize = 48.0});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GemVisuals.all
          .map((v) => Tooltip(
                message: '${v.name} (${v.rarity.name})',
                child: GemWidget(visual: v, size: gemSize),
              ))
          .toList(),
    );
  }
}
