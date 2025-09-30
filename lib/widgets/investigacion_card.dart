import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';

class InvestigacionCard extends StatelessWidget {
  final String titulo;
  final String ubicacion;
  final String descripcion;
  final String fecha;
  final String habitat;
  final String vegetacion;
  final String estado;
  final VoidCallback onPressed;

  const InvestigacionCard({
    Key? key,
    required this.titulo,
    required this.ubicacion,
    required this.descripcion,
    required this.fecha,
    required this.habitat,
    required this.vegetacion,
    required this.estado,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.marginMedium,
        vertical: AppConstants.marginSmall,
      ),
      elevation: AppConstants.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall + 4,
                    vertical: AppConstants.paddingSmall / 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Text(
                    estado,
                    style: AppTextStyles.estadoBadge,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.marginSmall),
            
            _InfoRow(
              icon: Icons.location_on,
              text: ubicacion,
            ),
            SizedBox(height: AppConstants.marginSmall / 2),
            
            _InfoRow(
              icon: Icons.search,
              text: descripcion,
            ),
            SizedBox(height: AppConstants.marginSmall / 2),
            
            _InfoRow(
              icon: Icons.calendar_today,
              text: fecha,
            ),
            SizedBox(height: AppConstants.marginSmall),
            
            Row(
              children: [
                Expanded(
                  child: _SmallInfoRow(
                    icon: Icons.location_city,
                    label: 'Habitat',
                    text: habitat,
                  ),
                ),
                SizedBox(width: AppConstants.marginMedium),
                Expanded(
                  child: _SmallInfoRow(
                    icon: Icons.eco,
                    label: 'Vegetación',
                    text: vegetacion,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.marginMedium),
            
            Center(
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                    vertical: AppConstants.paddingSmall + 4,
                  ),
                ),
                child: Text(
                  AppConstants.verMasDetalles,
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor() {
    switch (estado.toLowerCase()) {
      case 'ejecución':
        return AppColors.estadoEjecucion;
      case 'completado':
        return AppColors.success;
      case 'pendiente':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppConstants.iconSizeSmall, color: AppColors.textSecondary),
        SizedBox(width: AppConstants.marginSmall / 2),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body2,
          ),
        ),
      ],
    );
  }
}

class _SmallInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _SmallInfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppConstants.iconSizeSmall, color: AppColors.textSecondary),
        SizedBox(width: AppConstants.marginSmall / 2),
        Expanded(
          child: Text(
            '$label: $text',
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}