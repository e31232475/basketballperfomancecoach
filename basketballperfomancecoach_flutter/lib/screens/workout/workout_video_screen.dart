import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';

class WorkoutVideoScreen extends StatefulWidget {
  const WorkoutVideoScreen({
    super.key,
    required this.videoUrl,
  });

  final String videoUrl;

  @override
  State<WorkoutVideoScreen> createState() => _WorkoutVideoScreenState();
}

class _WorkoutVideoScreenState extends State<WorkoutVideoScreen> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoChanged);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final uri = Uri.tryParse(widget.videoUrl);

    if (uri == null || widget.videoUrl.trim().isEmpty) {
      setState(() {
        _isInitializing = false;
        _errorMessage = "Video belum tersedia.";
      });
      return;
    }

    VideoPlayerController? controller;

    try {
      controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize().timeout(const Duration(seconds: 12));
      await controller.setLooping(true);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.addListener(_handleVideoChanged);

      setState(() {
        _controller = controller;
        _isInitializing = false;
        _isPlaying = controller!.value.isPlaying;
      });
    } on TimeoutException {
      await controller?.dispose();
      _setVideoError("Video terlalu lama dimuat.");
    } catch (_) {
      await controller?.dispose();
      _setVideoError("Video tidak dapat dimuat.");
    }
  }

  void _handleVideoChanged() {
    final controller = _controller;

    if (!mounted || controller == null) {
      return;
    }

    final isPlaying = controller.value.isPlaying;

    if (isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }
  }

  void _setVideoError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
      _errorMessage = message;
    });
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {
        _isPlaying = controller.value.isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: _buildVideoBody()),
            Positioned(
              left: 12,
              top: 12,
              child: IconButton(
                tooltip: "Back",
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.appBar.withValues(alpha: 0.82),
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBody() {
    final controller = _controller;

    if (_isInitializing) {
      return const CircularProgressIndicator(color: AppColors.primary);
    }

    if (_errorMessage != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _errorMessage ?? "Video belum tersedia.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final aspectRatio = controller.value.aspectRatio <= 0
        ? 16 / 9
        : controller.value.aspectRatio;

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(controller),
          ),
          if (!_isPlaying)
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
