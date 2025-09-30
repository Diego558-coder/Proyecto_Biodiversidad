import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';

class SpeciesStatsCard extends StatelessWidget {
  final String number;
  final String label;

  const SpeciesStatsCard({
    Key? key,
    required this.number,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: AppTextStyles.especieStats,
          ),
          SizedBox(height: AppConstants.marginSmall / 2),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SpeciesCompositionChip extends StatelessWidget {
  final String text;
  final Color color;

  const SpeciesCompositionChip({
    Key? key,
    required this.text,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: AppConstants.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption,
      ),
    );
  }
}

class SpeciesStatusChip extends StatelessWidget {
  final String text;
  final bool isWarning;

  const SpeciesStatusChip({
    Key? key,
    required this.text,
    this.isWarning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: AppConstants.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.warning.withOpacity(0.2) : AppColors.primaryWithOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption,
      ),
    );
  }
}