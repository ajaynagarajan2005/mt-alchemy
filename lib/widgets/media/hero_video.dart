import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../theme/motion.dart';

/// Full-bleed, muted, looping hero video that covers its box.
///
/// A poster still is shown first and cross-fades to the video once it is
/// initialised and playing. With reduced motion, or if the video fails to
/// load, only the poster is shown.
class HeroVideo extends StatefulWidget {
  const HeroVideo({super.key});

  @override
  State<HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<HeroVideo> {
  VideoPlayerController? _controller;
  bool _started = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && !_failed && !Motion.reduced(context)) {
      _init();
    }
  }

  Future<void> _init() async {
    final c = VideoPlayerController.asset(
      'assets/videos/hero_loop.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = c;
    try {
      await c.initialize();
      // Browsers only autoplay muted video, so mute before play().
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      if (mounted) setState(() => _started = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poster = Image.asset(
      'assets/images/hero_poster.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
    final c = _controller;
    final showVideo =
        !Motion.reduced(context) && !_failed && _started && c != null && c.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        poster,
        if (showVideo)
          _FadeIn(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          ),
      ],
    );
  }
}

/// Fades its child from 0 to 1 on first build.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.slow,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
