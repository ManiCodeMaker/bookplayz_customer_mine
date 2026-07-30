import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppLoaderColor { white, black }

class AppLoader extends StatefulWidget {
  final double size;
  final AppLoaderColor color;

  const AppLoader({
    super.key,
    this.size = 80,
    this.color = AppLoaderColor.white,
  });

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1417),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.color == AppLoaderColor.white
        ? 'assets/images/gif/football-loader-white.svg'
        : 'assets/images/gif/football-loader-black.svg';
    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        asset,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
