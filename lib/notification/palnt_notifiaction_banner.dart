import 'package:flutter/material.dart';

class PlantNotificationBanner extends StatefulWidget {
  const PlantNotificationBanner({
    super.key,
    required this.dateLabel,
    required this.title,
    required this.message,
    required this.onDismissed,
  });

  final String dateLabel;
  final String title;
  final String message;
  final VoidCallback onDismissed;

  @override
  State<PlantNotificationBanner> createState() => _PlantNotificationBannerState();
}

class _PlantNotificationBannerState extends State<PlantNotificationBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      widget.dateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Noto Sans KR',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontFamily: 'Noto Sans KR',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontFamily: 'Noto Sans KR',
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: widget.onDismissed,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

