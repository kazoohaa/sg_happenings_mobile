import 'package:flutter/material.dart';
import '../../core/navigation/route_paths.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RoutePaths.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF4E7);
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        fit: StackFit.expand,
        children: const [
          _BackgroundImage(),
          Center(child: _PurpleLoader()),
        ],
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/splash_screen.png',
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
  }
}

class _PurpleLoader extends StatelessWidget {
  const _PurpleLoader();

  @override
  Widget build(BuildContext context) {
    const loaderPurple = Color(0xFF7E57C2);
    return SizedBox(
      height: 36,
      width: 36,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        valueColor: AlwaysStoppedAnimation<Color>(loaderPurple),
      ),
    );
  }
}


