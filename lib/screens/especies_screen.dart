import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../models/investigacion.dart';
import '../models/punto_muestreo.dart';
import '../widgets/species_stats_card.dart';
import '../models/especie.dart';
import 'detalles_especie_screen.dart';

class EspeciesScreen extends StatefulWidget {
  final Investigacion investigacion;

  const EspeciesScreen({required this.investigacion, Key? key}) : super(key: key);

  @override
  State<EspeciesScreen> createState() => _EspeciesScreenState();
}

class _EspeciesScreenState extends State<EspeciesScreen> {
  List<Especie> especies = const [];
  Map<String, dynamic>? estadisticas;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _prepararDatos();
  }

  void _prepararDatos() {
    try {
      final lista = _extraerEspecies(widget.investigacion.puntosMuestreo);
      final stats = _calcularEstadisticas(lista);

      setState(() {
        especies = lista;
        estadisticas = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'No fue posible preparar la información de especies.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Especies observadas', style: AppTextStyles.appBarTitle.copyWith(fontSize: 16)),
            Text(
              widget.investigacion.titulo,
              style: AppTextStyles.appBarTitle.copyWith(
                fontSize: 12,
                color: AppColors.textOnPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
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
            Text(errorMessage!, style: AppTextStyles.bodyError, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (especies.isEmpty) {
      return Center(
        child: Text(AppConstants.noDataMessage, style: AppTextStyles.bodySecondary),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          
          if (estadisticas != null)
            Container(
              padding: EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SpeciesStatsCard(
                    number: estadisticas!['totalEspecies'].toString(),
                    label: 'Especies\nobservadas',
                  ),
                  SpeciesStatsCard(
                    number: estadisticas!['totalIndividuos'].toString(),
                    label: 'Individuos\ntotales',
                  ),
                  SpeciesStatsCard(
                    number: '${estadisticas!['totalMachos']}/${estadisticas!['totalHembras']}/${estadisticas!['totalIndeterminados']}',
                    label: 'Machos/\nHembras/\nIndeterminados',
                  ),
                ],
              ),
            ),
          SizedBox(height: AppConstants.marginMedium),
          
          
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Especies registradas(${especies.length})',
              style: AppTextStyles.subtitle1,
            ),
          ),
          SizedBox(height: AppConstants.marginMedium),
          
          
          ...especies.map((especie) => _buildSpeciesCard(especie)).toList(),
        ],
      ),
    );
  }

  Widget _buildSpeciesCard(Especie especie) {
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
                    especie.nombre,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                Container(
                  width: AppConstants.speciesImageSize,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Icon(
                    Icons.image,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ),
              ],
            ),
            Text(
              '${especie.individuos} Individuos',
              style: AppTextStyles.cardSubtitle,
            ),
            SizedBox(height: AppConstants.marginSmall),

            _buildDetailRow('Método de detección', especie.informacionBasica.metodoDeteccion),
            _buildDetailRow('Distancia', especie.informacionBasica.distancia),
            _buildDetailRow('Actividad', especie.informacionBasica.actividad),
            _buildDetailRow('Sustrato', especie.informacionBasica.sustrato),
            _buildDetailRow('Estrato', especie.informacionBasica.estrato),
            
            SizedBox(height: AppConstants.marginSmall),
            
            
            Wrap(
              spacing: AppConstants.marginSmall,
              runSpacing: AppConstants.marginSmall / 2,
              children: [
                if (especie.composicionPoblacional.machos > 0)
                  SpeciesCompositionChip(
                    text: '${especie.composicionPoblacional.machos} Machos',
                    color: AppColors.especieMacho,
                  ),
                if (especie.composicionPoblacional.hembras > 0)
                  SpeciesCompositionChip(
                    text: '${especie.composicionPoblacional.hembras} Hembras',
                    color: AppColors.especieHembra,
                  ),
                if (especie.composicionPoblacional.adultos > 0)
                  SpeciesCompositionChip(
                    text: '${especie.composicionPoblacional.adultos} Adultos',
                    color: AppColors.especieAdulto,
                  ),
                if (especie.composicionPoblacional.juveniles > 0)
                  SpeciesCompositionChip(
                    text: '${especie.composicionPoblacional.juveniles} Jóvenes',
                    color: AppColors.especieJoven,
                  ),
              ],
            ),
            
            
            if (especie.composicionPoblacional.indeterminados > 0) ...[
              SizedBox(height: AppConstants.marginSmall),
              SpeciesStatusChip(
                text: '${especie.composicionPoblacional.indeterminados} Indeterminado',
                isWarning: true,
              ),
            ],
            
            if (especie.observaciones != null && especie.observaciones!.isNotEmpty) ...[
              SizedBox(height: AppConstants.marginSmall),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: AppConstants.iconSizeSmall, color: AppColors.textSecondary),
                  SizedBox(width: AppConstants.marginSmall / 2),
                  Expanded(
                    child: Text(
                      especie.observaciones!,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: AppConstants.marginMedium),
            
            Center(
              child: ElevatedButton(
                onPressed: () => _navegarADetallesEspecie(especie),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                ),
                child: Text(AppConstants.verDetallesCompletos),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.paddingSmall / 2),
      child: Row(
        children: [
          Text('$label: ', style: AppTextStyles.subtitle2),
          Text(value, style: AppTextStyles.body2),
        ],
      ),
    );
  }

  void _navegarADetallesEspecie(Especie especie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallesEspecieScreen(especie: especie),
      ),
    );
  }

  List<Especie> _extraerEspecies(List<PuntoMuestreo> puntos) {
    final resultado = <Especie>[];
    for (final punto in puntos) {
      for (final muestra in punto.muestras) {
        for (final observacion in muestra.especiesObservadas) {
          resultado.add(Especie.fromApiObservation(observacion));
        }
      }
    }
    return resultado;
  }

  Map<String, dynamic> _calcularEstadisticas(List<Especie> lista) {
    final totalEspecies = lista.length;
    final totalIndividuos = lista.fold<int>(0, (sum, especie) => sum + especie.individuos);
    final totalMachos = lista.fold<int>(0, (sum, especie) => sum + especie.composicionPoblacional.machos);
    final totalHembras = lista.fold<int>(0, (sum, especie) => sum + especie.composicionPoblacional.hembras);
    final totalIndeterminados = lista.fold<int>(0, (sum, especie) => sum + especie.composicionPoblacional.indeterminados);

    return {
      'totalEspecies': totalEspecies,
      'totalIndividuos': totalIndividuos,
      'totalMachos': totalMachos,
      'totalHembras': totalHembras,
      'totalIndeterminados': totalIndeterminados,
    };
  }
}
