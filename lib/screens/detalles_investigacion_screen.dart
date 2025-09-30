import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../models/investigacion.dart';
import '../widgets/custom_button.dart';
import 'mapa_screen.dart';
import 'especies_screen.dart';

class DetallesInvestigacionScreen extends StatelessWidget {
  final Investigacion investigacion;

  DetallesInvestigacionScreen({required this.investigacion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(investigacion.titulo, style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSmall + 4,
              vertical: AppConstants.paddingSmall / 2,
            ),
            margin: EdgeInsets.only(right: AppConstants.marginMedium),
            decoration: BoxDecoration(
              color: AppColors.estadoEjecucion,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Text(
              investigacion.estado,
              style: AppTextStyles.estadoBadge,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción del proyecto
            Text(
              'Descripción del proyecto',
              style: AppTextStyles.subtitle1,
            ),
            SizedBox(height: AppConstants.marginSmall / 2),
            Text(investigacion.descripcion, style: AppTextStyles.body2),
            SizedBox(height: AppConstants.marginMedium),
            
            // Objetivos
            _buildSection(
              icon: Icons.check_circle,
              title: 'Objetivos',
              children: investigacion.objetivos.map((objetivo) => 
                _buildObjectiveItem(objetivo)
              ).toList(),
            ),
            
            // Resultados
            _buildSection(
              icon: Icons.analytics,
              title: 'Resultados',
              children: investigacion.resultados.map((resultado) => 
                Text(resultado, style: AppTextStyles.body2)
              ).toList(),
            ),
            
            // Datos generales
            _buildSection(
              title: 'Datos generales',
              children: [
                _buildDataRow(
                  Icons.calendar_today,
                  'Periodo de estudio:',
                  investigacion.datosGenerales.periodoEstudio,
                ),
                _buildDataRow(
                  Icons.location_city,
                  'Habitat:',
                  investigacion.datosGenerales.habitat,
                ),
                _buildDataRow(
                  Icons.eco,
                  'Vegetación:',
                  investigacion.datosGenerales.vegetacion,
                ),
                _buildDataRow(
                  Icons.terrain,
                  'Altitud:',
                  investigacion.datosGenerales.altitud,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ubicación
            Text('Ubicación de estudio', style: AppTextStyles.subtitle1),
            SizedBox(height: AppConstants.marginSmall),
            
            Text('País: ${investigacion.ubicacionEstudio.pais}.', style: AppTextStyles.body2),
            Text('Departamento: ${investigacion.ubicacionEstudio.departamento}.', style: AppTextStyles.body2),
            Text('Ciudad: ${investigacion.ubicacionEstudio.ciudad}.', style: AppTextStyles.body2),
            Text('Barrio/Vereda: ${investigacion.ubicacionEstudio.barrioVereda}.', style: AppTextStyles.body2),
            Text('Lugar específico: ${investigacion.ubicacionEstudio.lugarEspecifico}.', style: AppTextStyles.body2),
            
            SizedBox(height: AppConstants.marginSmall),
            
            // Coordenadas GPS
            Container(
              padding: EdgeInsets.all(AppConstants.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, color: AppColors.primary),
                      SizedBox(width: AppConstants.marginSmall),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coordenadas GPS', style: AppTextStyles.subtitle2),
                          Text(investigacion.ubicacionEstudio.coordenadas.descripcion, style: AppTextStyles.body2),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.marginSmall),
                  CustomButton(
                    text: AppConstants.verPuntosMuestreo,
                    onPressed: () => _navegarAMapa(context),
                    isExpanded: true,
                    icon: Icons.location_on,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppConstants.marginMedium),
            
            // Equipo de trabajo
            Text('Equipo de trabajo', style: AppTextStyles.subtitle1),
            SizedBox(height: AppConstants.marginSmall / 2),
            
            Text('Líder: ${investigacion.equipoTrabajo.lider}.', style: AppTextStyles.body2),
            Text('Miembros: ${investigacion.equipoTrabajo.miembros.join(", ")}.', style: AppTextStyles.body2),
            
            SizedBox(height: AppConstants.marginMedium),
            
            // Botones de navegación
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    text: AppConstants.puntosMuestreo,
                    onPressed: () => _navegarAMapa(context),
                  ),
                ),
                SizedBox(width: AppConstants.marginSmall),
                Expanded(
                  child: ActionButton(
                    text: AppConstants.especies,
                    onPressed: () => _navegarAEspecies(context),
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({IconData? icon, required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary),
              SizedBox(width: AppConstants.marginSmall),
            ],
            Text(title, style: AppTextStyles.subtitle1),
          ],
        ),
        SizedBox(height: AppConstants.marginSmall),
        ...children,
        SizedBox(height: AppConstants.marginMedium),
      ],
    );
  }

  Widget _buildObjectiveItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.paddingSmall / 2),
      child: Text(text, style: AppTextStyles.body2),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppConstants.iconSizeSmall),
          SizedBox(width: AppConstants.marginSmall),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(text: label, style: AppTextStyles.subtitle2),
                  TextSpan(text: ' $value', style: AppTextStyles.body2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navegarAMapa(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaScreen(investigacionId: investigacion.id),
      ),
    );
  }

  void _navegarAEspecies(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EspeciesScreen(investigacionId: investigacion.id),
      ),
    );
  }
}