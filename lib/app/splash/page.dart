import 'package:flutter/material.dart';

import '../../push/push_service.dart';
import '../../data/session.dart';
import '../../data/app_api.dart';
import '../nav.dart';

/// First screen: the AV mark pops in on the navy brand colour, a light sweep crosses it, then
/// the app name fades up before moving on to sign in (or the module grid when signed in).
/// It continues straight from the native splash, which shows the same colour and mark.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  static const navy = Color(0xFF022D5A);

  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  late final Animation<double> _pop = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack));
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.25, curve: Curves.easeOut));
  late final Animation<double> _sweep = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.75, curve: Curves.easeInOut));
  late final Animation<double> _text = CurvedAnimation(parent: _c, curve: const Interval(0.6, 0.95, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // Check the saved sign-in while the logo animates.
    final restored = AppSession.instance.restore();
    await _c.forward();
    final signedIn = await restored;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    AppNav.reset(context, signedIn ? '/module' : '/auth/signin');
    // The app was opened by tapping a notification popup: go straight to its page.
    final url = PushService.pendingUrl;
    if (signedIn && url != null) {
      PushService.pendingUrl = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = AppApi.navigatorKey.currentState;
        if (nav != null) pushNotificationUrl(nav, url);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const logo = 220.0;
    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: 0.55 + 0.45 * _pop.value,
                  child: SizedBox(
                    width: logo,
                    height: logo,
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (rect) {
                        // A soft bright band that travels left → right across the mark.
                        final x = -0.4 + 1.8 * _sweep.value;
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [Color(0x00FFFFFF), Color(0xFF9CC8FF), Color(0x00FFFFFF)],
                          stops: [(x - 0.18).clamp(0.0, 1.0), x.clamp(0.0, 1.0), (x + 0.18).clamp(0.0, 1.0)],
                        ).createShader(rect);
                      },
                      child: Image.asset('assets/icon/icon_foreground.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Opacity(
                opacity: _text.value,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - _text.value)),
                  child: const Text(
                    'AVATARA DEFENCE',
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
