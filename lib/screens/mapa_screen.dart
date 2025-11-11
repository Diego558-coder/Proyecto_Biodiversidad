import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../models/investigacion.dart';
import '../models/punto_muestreo.dart';
import '../widgets/custom_button.dart';
import 'especies_screen.dart';

class MapaScreen extends StatelessWidget {
  final Investigacion investigacion;

  const MapaScreen({required this.investigacion, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final puntos = investigacion.puntosMuestreo;
    final puntosConCoordenadas = puntos.where((p) => p.tieneCoordenadas).toList();
    final ubicacionGeneral = investigacion.ubicacionEstudio.coordenadas;
    final tieneUbicacionGeneral = _hasValidLatLng(ubicacionGeneral.latitud, ubicacionGeneral.longitud);
    final mostrarMapa = puntosConCoordenadas.isNotEmpty || tieneUbicacionGeneral;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Puntos de muestreo', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
      ),
      body: mostrarMapa
          ? SingleChildScrollView(
              padding: EdgeInsets.only(bottom: AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMap(puntos, ubicacionGeneral),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          puntos.length == 1
                              ? 'Punto de muestreo'
                              : 'Puntos de muestreo (${puntos.length})',
                          style: AppTextStyles.subtitle1,
                        ),
                        SizedBox(height: AppConstants.marginSmall),
                        if (puntos.isEmpty)
                          _buildEmptyPointsInfo(tieneUbicacionGeneral)
                        else
                          ...puntos.map(_buildPuntoCard),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingLarge),
                child: Text(
                  'Esta investigación aún no registra puntos de muestreo ni coordenadas de referencia.',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      bottomNavigationBar: mostrarMapa ? _buildBottom(context, puntos, ubicacionGeneral) : null,
    );
  }

  Widget _buildMap(List<PuntoMuestreo> puntos, CoordenadasGPS ubicacionGeneral) {
    final puntosConCoordenadas = puntos.where((p) => p.tieneCoordenadas).toList();
    final markers = <Marker>[
      ...puntosConCoordenadas.map(
        (punto) => Marker(
          point: LatLng(punto.coordenadas.latitud!, punto.coordenadas.longitud!),
          width: 60,
          height: 60,
          child: _MapMarker(label: 'Punto #${punto.numero}', color: AppColors.primary),
        ),
      ),
      if (_hasValidLatLng(ubicacionGeneral.latitud, ubicacionGeneral.longitud))
        Marker(
          point: LatLng(ubicacionGeneral.latitud, ubicacionGeneral.longitud),
          width: 70,
          height: 70,
          child: _MapMarker(
            label: 'Área general',
            color: AppColors.secondary,
            icon: Icons.place,
          ),
        ),
    ];

    final markerPoints = markers.map((marker) => marker.point).toList();

    if (markerPoints.isEmpty && _hasValidLatLng(ubicacionGeneral.latitud, ubicacionGeneral.longitud)) {
      markerPoints.add(LatLng(ubicacionGeneral.latitud, ubicacionGeneral.longitud));
    }

    final cameraFit = markerPoints.length > 1
        ? CameraFit.coordinates(
            coordinates: markerPoints,
            padding: EdgeInsets.all(markers.length <= 1 ? 80 : 40),
          )
        : null;

    final initialCenter = markerPoints.isNotEmpty ? markerPoints.first : const LatLng(0, 0);

    return Container(
      height: AppConstants.mapContainerHeight + 80,
      width: double.infinity,
      margin: EdgeInsets.all(AppConstants.marginMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: markers.length <= 1 ? 13 : 12,
                initialCameraFit: cameraFit,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.diego558coder.proyecto_biodiversidad',
                  maxZoom: 18,
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
            if (puntosConCoordenadas.isEmpty)
              _MapNoticeOverlay(
                child: _MapNotice(
                  text: 'Mostrando ubicación general del estudio. Los puntos de muestreo aún no están registrados.',
                ),
              )
            else if (puntosConCoordenadas.length < puntos.length)
              _MapNoticeOverlay(
                child: _MapNotice(
                  text: 'Algunos puntos no tienen coordenadas. Se muestran únicamente los que están georreferenciados.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuntoCard(PuntoMuestreo punto) {
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.marginMedium),
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
                    'Punto #${punto.numero}',
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                if (punto.fechaInicio != null)
                  Text(
                    _formatearFecha(punto.fechaInicio!),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
            SizedBox(height: AppConstants.marginSmall),
            _buildInfoRow('Tipo de muestreo', punto.tipoMuestreo),
            if (punto.detalleTipoMuestreo != null && punto.detalleTipoMuestreo!.isNotEmpty)
              _buildInfoRow('Detalle', punto.detalleTipoMuestreo!),
            _buildInfoRow('Método de detección', punto.deteccion),
            if (punto.periodoCenso != null)
              _buildInfoRow('Periodo de censo (min)', '${punto.periodoCenso}'),
            if (punto.radioFijo != null)
              _buildInfoRow('Radio fijo (m)', '${punto.radioFijo}'),
            if (punto.coordenadas.latitud != null && punto.coordenadas.longitud != null)
              _buildInfoRow(
                'Coordenadas',
                'Lat: ${punto.coordenadas.latitud!.toStringAsFixed(4)}, Long: ${punto.coordenadas.longitud!.toStringAsFixed(4)}',
              ),
            SizedBox(height: AppConstants.marginMedium),
            Text('Muestras registradas (${punto.muestras.length})', style: AppTextStyles.subtitle2),
            SizedBox(height: AppConstants.marginSmall),
            ...punto.muestras.map(_buildMuestraCard),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPointsInfo(bool tieneUbicacionGeneral) {
    final mensaje = tieneUbicacionGeneral
        ? 'Aún no hay puntos de muestreo. Se muestra la ubicación general del estudio mientras se registran nuevas coordenadas.'
        : 'Aún no hay puntos de muestreo registrados para esta investigación.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      margin: EdgeInsets.only(bottom: AppConstants.marginMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        mensaje,
        style: AppTextStyles.bodySecondary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.paddingSmall / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_forward_ios, size: AppConstants.iconSizeSmall, color: AppColors.textSecondary.withOpacity(0.6)),
          SizedBox(width: AppConstants.marginSmall / 2),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body2,
                children: [
                  TextSpan(text: '$label: ', style: AppTextStyles.subtitle2),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuestraCard(Muestra muestra) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.marginSmall),
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  muestra.fecha != null ? _formatearFecha(muestra.fecha!) : 'Fecha desconocida',
                  style: AppTextStyles.subtitle2,
                ),
              ),
              if (muestra.temperatura != null)
                Text('${muestra.temperatura!.toStringAsFixed(1)} °C', style: AppTextStyles.subtitle2),
            ],
          ),
          SizedBox(height: AppConstants.marginSmall / 2),
          if (muestra.humedadRelativa != null)
            Text('Humedad relativa: ${muestra.humedadRelativa!.toStringAsFixed(1)} %', style: AppTextStyles.caption),
          if (muestra.estadoPrecipitacion != null)
            Text('Precipitación: ${muestra.estadoPrecipitacion}', style: AppTextStyles.caption),
          if (muestra.luminosidad != null)
            Text('Luminosidad: ${muestra.luminosidad}', style: AppTextStyles.caption),
          if (muestra.condicionesGenerales != null)
            Text('Condiciones: ${muestra.condicionesGenerales}', style: AppTextStyles.caption),
          SizedBox(height: AppConstants.marginSmall),
          Text('Especies observadas: ${muestra.especiesObservadas.length}', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  bool _hasValidLatLng(double lat, double lon) {
    if (lat.isNaN || lon.isNaN) return false;
    if (lat == 0.0 && lon == 0.0) return false;
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  Widget _buildBottom(BuildContext context, List<PuntoMuestreo> puntos, CoordenadasGPS ubicacionGeneral) {
    if (puntos.isNotEmpty) {
      final punto = puntos.first;
      final primeraMuestra = punto.muestras.isNotEmpty ? punto.muestras.first : null;

      return Container(
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen del primer punto', style: AppTextStyles.subtitle1),
            SizedBox(height: AppConstants.marginSmall),
            _buildInfoRow('Método de detección', punto.deteccion),
            if (primeraMuestra != null)
              _buildInfoRow(
                'Especies registradas',
                '${primeraMuestra.especiesObservadas.length} observaciones',
              ),
            SizedBox(height: AppConstants.marginMedium),
            CustomButton(
              text: AppConstants.verEspeciesObservadas,
              icon: Icons.pets,
              isExpanded: true,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EspeciesScreen(investigacion: investigacion),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de la ubicación', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginSmall),
          _buildInfoRow('Área de estudio', investigacion.ubicacion),
          if (_hasValidLatLng(ubicacionGeneral.latitud, ubicacionGeneral.longitud))
            _buildInfoRow(
              'Referencia GPS',
              'Lat: ${ubicacionGeneral.latitud.toStringAsFixed(4)}, Long: ${ubicacionGeneral.longitud.toStringAsFixed(4)}',
            ),
          SizedBox(height: AppConstants.marginMedium),
          CustomButton(
            text: AppConstants.verEspeciesObservadas,
            icon: Icons.pets,
            isExpanded: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EspeciesScreen(investigacion: investigacion),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final two = (int value) => value.toString().padLeft(2, '0');
    return '${fecha.year}-${two(fecha.month)}-${two(fecha.day)}';
  }
}

class _MapMarker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MapMarker({required this.label, required this.color, this.icon = Icons.location_on});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.paddingSmall,
            vertical: AppConstants.paddingSmall / 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ),
        Icon(icon, color: color, size: 32),
      ],
    );
  }
}

class _MapNotice extends StatelessWidget {
  final String text;

  const _MapNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
        textAlign: TextAlign.left,
      ),
    );
  }
}

class _MapNoticeOverlay extends StatelessWidget {
  final Widget child;

  const _MapNoticeOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(
            top: AppConstants.marginLarge,
            left: AppConstants.marginMedium,
            right: AppConstants.marginMedium,
          ),
          child: child,
        ),
      ),
    );
  }
}
