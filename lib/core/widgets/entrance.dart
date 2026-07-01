import 'package:flutter/material.dart';

/// Anima a entrada do [child] com fade + deslize de baixo pra cima.
/// Use [delay] para escalonar itens de uma lista (efeito cascata).
class Entrance extends StatefulWidget {
  const Entrance({
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 22,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
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
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Aplica [Entrance] a uma lista de filhos, com atraso incremental entre
/// eles para o efeito cascata.
class EntranceList extends StatelessWidget {
  const EntranceList({
    required this.children,
    this.step = const Duration(milliseconds: 70),
    this.initialDelay = Duration.zero,
    super.key,
  });

  final List<Widget> children;
  final Duration step;
  final Duration initialDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          Entrance(
            delay: initialDelay + step * i,
            child: children[i],
          ),
      ],
    );
  }
}
