import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';
import '../services/puntos_muestreo_service.dart';
import '../models/punto_muestreo.dart';
import 'especies_screen.dart';

class MapaScreen extends StatefulWidget {
  final String investigacionId;

  MapaScreen({required this.investigacionId});

  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  List<PuntoMuestreo> puntos = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarPuntoMuestreo();
  }

  Future<void> _cargarPuntoMuestreo() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final lista = await PuntosMuestreoService.obtenerPuntosPorInvestigacion(widget.investigacionId);
      
      setState(() {
        puntos = lista;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = AppConstants.errorMessage;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Puntos de muestreo', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: AppConstants.marginMedium),
            Text(AppConstants.loadingMessage, style: AppTextStyles.body2),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppConstants.marginMedium),
            Text(errorMessage!, style: AppTextStyles.bodyError),
            SizedBox(height: AppConstants.marginMedium),
            ElevatedButton(
              onPressed: _cargarPuntoMuestreo,
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (puntos.isEmpty) {
      return Center(
        child: Text(AppConstants.noDataMessage, style: AppTextStyles.bodySecondary),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mapa placeholder
          Container(
            height: AppConstants.mapContainerHeight,
            width: double.infinity,
            margin: EdgeInsets.all(AppConstants.marginMedium),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 50, color: Colors.grey[600]),
                      SizedBox(height: AppConstants.marginSmall),
                      Text(
                        'Mapa de ubicación',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Marcadores simulados
                Positioned(
                  top: 80,
                  left: 100,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 80,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 60,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Información de puntos de muestreo desde la API
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puntos de muestreo (${puntos.length})',
                  style: AppTextStyles.subtitle1,
                ),
                SizedBox(height: AppConstants.marginSmall),
                ...puntos.map((p) => Padding(
                  padding: EdgeInsets.only(bottom: AppConstants.marginSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem(p.nombre),
                      _buildInfoItem('Altitud: ${p.ubicacion.altitud}'),
                      _buildInfoItem('Longitud: ${p.ubicacion.longitud}'),
                      if (p.metodologia.tipoMuestreo.isNotEmpty)
                        _buildInfoItem('Tipo de muestreo: ${p.metodologia.tipoMuestreo}'),
                    ],
                  ),
                )),
                SizedBox(height: AppConstants.marginLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.paddingSmall / 2),
      child: Text(text, style: AppTextStyles.body2),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')} AM';
  }

  @override
  Widget? get bottomNavigationBar {
    if (puntos.isEmpty) return null;
    
    return Container(
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
          Container(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de muestreo: ${puntos.first.metodologia.tipoMuestreo}.',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Detalle del muestreo: ${puntos.first.metodologia.detalleMuestreo}.',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Método de detección: ${puntos.first.metodologia.metodoDeteccion}.',
                  style: AppTextStyles.caption,
                ),
                SizedBox(height: AppConstants.marginSmall),
                
                Text('Parámetros del censo:', style: AppTextStyles.subtitle2),
                Text(
                  'Periodo de censo: ${puntos.first.parametrosCenso.periodoCenso}. Radio fijo: ${puntos.first.parametrosCenso.radioFijo}.',
                  style: AppTextStyles.caption,
                ),
                SizedBox(height: AppConstants.marginSmall),
                
                Text('Duración del muestreo:', style: AppTextStyles.subtitle2),
                Text(
                  'Fecha de inicio: ${_formatearFecha(puntos.first.duracionMuestreo.fechaInicio)}.',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Fecha de finalización: ${_formatearFecha(puntos.first.duracionMuestreo.fechaFinalizacion)}.',
                  style: AppTextStyles.caption,
                ),
                
                SizedBox(height: AppConstants.marginMedium),
                
                Text('Muestras del punto', style: AppTextStyles.subtitle1),
                SizedBox(height: AppConstants.marginSmall),
                
                ...puntos.first.muestras.map((muestra) => _buildMuestraCard(muestra)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuestraCard(Muestra muestra) {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingSmall + 4),
      margin: EdgeInsets.only(bottom: AppConstants.marginSmall),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(muestra.nombre, style: AppTextStyles.subtitle2),
              Spacer(),
              Text('${muestra.temperatura.toInt()}°C', style: AppTextStyles.subtitle2),
            ],
          ),
          SizedBox(height: AppConstants.paddingSmall / 2),
          Row(
            children: [
              Spacer(),
              Text('${muestra.humedad}% Humedad', style: AppTextStyles.caption),
            ],
          ),
          SizedBox(height: AppConstants.marginSmall),
          
          Row(
            children: [
              _buildCondicionColumn('Precipitación:', muestra.condiciones.precipitacion),
              Spacer(),
              _buildCondicionColumn('Nubosidad:', muestra.condiciones.nubosidad),
            ],
          ),
          SizedBox(height: AppConstants.marginSmall),
          
          Row(
            children: [
              _buildCondicionColumn('Luminosidad:', muestra.condiciones.luminosidad),
              Spacer(),
              _buildCondicionColumn('Condiciones:', muestra.condiciones.condiciones),
            ],
          ),
          
          SizedBox(height: AppConstants.marginMedium),
          
          CustomButton(
            text: AppConstants.verEspeciesObservadas,
            onPressed: () => _navegarAEspecies(),
            isExpanded: true,
            icon: Icons.pets,
          ),
        ],
      ),
    );
  }

  Widget _buildCondicionColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(value, style: AppTextStyles.caption),
      ],
    );
  }

  void _navegarAEspecies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EspeciesScreen(investigacionId: widget.investigacionId),
      ),
    );
  }
}
