import 'package:flutter/material.dart';
import 'package:ui_kit/src/theme.dart';

/// Shared logo asset (package: ui_kit).
const ayniLogoAsset = 'assets/branding/logo.png';

class AyniLogo extends StatelessWidget {
  const AyniLogo({
    super.key,
    this.height = 168,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ayniLogoAsset,
      package: 'ui_kit',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

/// Compact mark for AppBars (logo already includes wordmark).
class AyniAppBarTitle extends StatelessWidget {
  const AyniAppBarTitle({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          ayniLogoAsset,
          package: 'ui_kit',
          height: 40,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              subtitle!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AyniColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
