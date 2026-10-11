import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../common/app_icon.dart';

/// Click-to-play brand film in a rounded 16:9 frame.
///
/// Never autoplays. Shows [poster] with a round red play button; after a tap
/// it plays muted, with a play/pause control, a thin red progress line and a
/// replay state at the end. Load errors fall back to the poster.
///
/// CONTAINER (decoration): the clipped, rounded frame around the video.
class BrandVideoPlayer extends StatefulWidget {
  const BrandVideoPlayer({
    super.key,
    required this.asset,
    required this.poster,
  });

  final String asset;
  final String poster;

  @override
  State<BrandVideoPlayer> createState() => _BrandVideoPlayerState();
}

class _BrandVideoPlayerState extends State<BrandVideoPlayer> {
  VideoPlayerController? _c;
  bool _loading = false;
  bool _failed = false;

  bool get _ready => _c?.value.isInitialized ?? false;
  bool get _playing => _c?.value.isPlaying ?? false;
  bool get _ended {
    final v = _c?.value;
    return v != null &&
        v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration;
  }

  Future<void> _start() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final c = VideoPlayerController.asset(
      widget.asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;
    try {
      await c.initialize();
      await c.setVolume(0);
      c.addListener(_onTick);
      await c.play();
    } catch (_) {
      _failed = true;
      _c = null;
      await c.dispose();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    final c = _c;
    if (c == null || !_ready) return;
    if (_ended) {
      await c.seekTo(Duration.zero);
      await c.play();
    } else if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
  }

  @override
  void dispose() {
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final idle = !_ready;
    final ended = _ended;
    final showCenter = idle || ended;
    final v = c?.value;
    final progress =
        (v != null && v.isInitialized && v.duration.inMilliseconds > 0)
        ? (v.position.inMilliseconds / v.duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    // CONTAINER (decoration): rounded 24 clip so poster, video and controls
    // share one soft frame.
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: Radii.cardAll,
          color: AppColors.grey100,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.poster, fit: BoxFit.cover),
            if (_ready)
              AnimatedOpacity(
                opacity: 1,
                duration: Motion.slow,
                child: VideoPlayer(c!),
              ),
            // Tap anywhere on the film to pause or resume.
            if (!idle && !ended)
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: _playing ? 'Pause video' : 'Play video',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggle,
                  ),
                ),
              ),
            if (showCenter)
              Center(
                child: _RoundButton(
                  icon: ended
                      ? HugeIcons.strokeRoundedReload
                      : HugeIcons.strokeRoundedPlay,
                  tooltip: ended ? 'Replay video' : 'Play video',
                  busy: _loading,
                  onTap: ended ? _toggle : _start,
                ),
              ),
            if (_ready && !ended && !_playing)
              Center(
                child: _RoundButton(
                  icon: HugeIcons.strokeRoundedPlay,
                  tooltip: 'Play video',
                  onTap: _toggle,
                ),
              ),
            if (_ready && !ended && _playing)
              Positioned(
                left: Space.md,
                bottom: Space.md + 4,
                child: _RoundButton(
                  icon: HugeIcons.strokeRoundedPause,
                  tooltip: 'Pause video',
                  size: 40,
                  onTap: _toggle,
                ),
              ),
            if (_failed)
              const Positioned(
                left: 0,
                right: 0,
                bottom: Space.md,
                child: Center(child: _FailedNote()),
              ),
            // Thin red progress line.
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 4,
                child: Semantics(
                  label: 'Video progress',
                  value: '${(progress * 100).round()} percent',
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: const ColoredBox(
                        color: AppColors.red,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FailedNote extends StatelessWidget {
  const _FailedNote();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.glassFillStrong,
      borderRadius: Radii.pillAll,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      child: Text('Video unavailable right now'),
    ),
  );
}

/// Round red icon button with tooltip and semantics label.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 72,
    this.busy = false,
  });

  final AppIconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: AppColors.red,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: busy ? null : onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: busy
                    ? SizedBox(
                        width: size / 3,
                        height: size / 3,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : AppIcon(icon, size: size / 2.4, color: AppColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
