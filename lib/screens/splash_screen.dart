import 'package:bookplayz/api/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_constants.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = VideoPlayerController.asset('assets/videos/splashscreen-video.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _controller.play();
      });

    // ── Run video delay + session check in parallel ──
    Future.wait([
      Future.delayed(const Duration(seconds: 7)),
      SessionManager.instance.restoreSession(),
    ]).then((results) {
      if (!mounted) return;
      final restored = results[1] as bool;
      Navigator.pushReplacementNamed(
        context,
        restored ? AppRoutes.shell : AppRoutes.onboarding,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}