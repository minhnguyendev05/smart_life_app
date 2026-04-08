import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastType { success, info, warning, error }

class _AppToastVisual {
  const _AppToastVisual({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
}

OverlayEntry? _activeAppToastEntry;
Timer? _activeAppToastTimer;

void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.success,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }

  _activeAppToastTimer?.cancel();
  _activeAppToastEntry?.remove();

  final visual = _visualFor(type);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (overlayContext) {
      final topInset = MediaQuery.of(overlayContext).padding.top + 12;

      return Positioned(
        top: topInset,
        left: 14,
        right: 14,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: visual.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(visual.icon, color: visual.iconColor, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: visual.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  _activeAppToastEntry = entry;

  _activeAppToastTimer = Timer(duration, () {
    if (_activeAppToastEntry == entry) {
      _activeAppToastEntry?.remove();
      _activeAppToastEntry = null;
    }
  });
}

_AppToastVisual _visualFor(AppToastType type) {
  switch (type) {
    case AppToastType.success:
      return const _AppToastVisual(
        icon: Icons.check_circle,
        backgroundColor: Color(0xFF34C759),
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    case AppToastType.info:
      return const _AppToastVisual(
        icon: Icons.info_rounded,
        backgroundColor: Color(0xFF3D8BFF),
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    case AppToastType.warning:
      return const _AppToastVisual(
        icon: Icons.warning_amber_rounded,
        backgroundColor: Color(0xFFF5A524),
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    case AppToastType.error:
      return const _AppToastVisual(
        icon: Icons.error_outline_rounded,
        backgroundColor: Color(0xFFE5484D),
        iconColor: Colors.white,
        textColor: Colors.white,
      );
  }
}
