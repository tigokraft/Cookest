import 'package:flutter/material.dart';


import '../theme/shadcn_theme.dart';

enum ShadcnButtonVariant { defaultBtn, destructive, outline, secondary, ghost, link }

class ShadcnButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ShadcnButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;

  const ShadcnButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ShadcnButtonVariant.defaultBtn,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 40,
      child: switch (variant) {
        ShadcnButtonVariant.defaultBtn => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
            ),
            child: _buildContent(),
          ),
        ShadcnButtonVariant.destructive => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.destructive,
              foregroundColor: Colors.white,
            ),
            child: _buildContent(),
          ),
        ShadcnButtonVariant.outline => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: AppTheme.border),
            ),
            child: _buildContent(),
          ),
        ShadcnButtonVariant.secondary => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.muted,
              foregroundColor: AppTheme.onBackground,
              elevation: 0,
            ),
            child: _buildContent(),
          ),
        ShadcnButtonVariant.ghost => TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.onBackground,
            ),
            child: _buildContent(),
          ),
        ShadcnButtonVariant.link => TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              textStyle: const TextStyle(decoration: TextDecoration.underline),
            ),
            child: _buildContent(),
          ),
      },
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white), // Adjust based on variant if needed
        ),
      );
    }
    
    // For variants with dark text, loader should probably be dark. 
    // Simplifying for now.

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(text),
      ],
    );
  }
}
