import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../models/especie.dart';

class DetallesEspecieScreen extends StatelessWidget {
  final Especie especie;

  DetallesEspecieScreen({required this.especie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles Completos', style: AppTextStyles.appBarTitle.copyWith(fontSize: 16)),
            Text('${especie.nombre}-Muestra 1', style: AppTextStyles.appBarTitle.copyWith(
              fontSize: 12, 
              color: AppColors.textOnPrimary.withOpacity(0.7)
            )),
          ],
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInformacionBasicaSection(),
            
            _buildComposicionPoblacionalSection(),
            
            _buildMorfologiaSection(),
            
            _buildMedidasAdicionalesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacionBasicaSection() {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(especie.nombre, style: AppTextStyles.title3),
                    SizedBox(height: AppConstants.marginSmall),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingSmall + 4,
                        vertical: AppConstants.paddingSmall / 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                      ),
                      child: Text(
                        '${especie.individuos} Individuos',
                        style: AppTextStyles.estadoBadge,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildImagePlaceholder(),
                  SizedBox(width: AppConstants.marginSmall),
                  _buildImagePlaceholder(),
                  SizedBox(width: AppConstants.marginSmall),
                  _buildImagePlaceholder(),
                ],
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.marginLarge),
          
          Text('Información básica', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildInfoRow('Método de detección', especie.informacionBasica.metodoDeteccion),
          _buildInfoRow('Distancia', especie.informacionBasica.distancia),
          _buildInfoRow('Actividad', especie.informacionBasica.actividad),
          _buildInfoRow('Sustrato', especie.informacionBasica.sustrato),
          _buildInfoRow('Estrato', especie.informacionBasica.estrato),
        ],
      ),
    );
  }

  Widget _buildComposicionPoblacionalSection() {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Composición poblacional', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginMedium),
          
          _buildCompositionRow('Abundancia', '${especie.composicionPoblacional.abundancia} Individuos'),
          _buildCompositionRow('Machos', especie.composicionPoblacional.machos.toString()),
          _buildCompositionRow('Hembras', especie.composicionPoblacional.hembras.toString()),
          _buildCompositionRow('Individuos de sexo indeterminado', especie.composicionPoblacional.indeterminados.toString()),
          _buildCompositionRow('Adultos', especie.composicionPoblacional.adultos.toString()),
          _buildCompositionRow('Juveniles', especie.composicionPoblacional.juveniles.toString()),
          
          SizedBox(height: AppConstants.marginMedium),
          Text(
            'Morfología detallada',
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildMorfologiaSection() {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pico
          Text('Pico', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyTable([
            ['Altura', 'Ancho', 'Ancho'],
            [especie.morfologiaDetallada.pico.altura ?? 'No medida', 
             'Narinas\n${especie.morfologiaDetallada.pico.anchoNarinas ?? 'No medida'}', 
             'Comisura\n${especie.morfologiaDetallada.pico.anchoComisura ?? 'No medida'}'],
          ]),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyTable([
            ['Curvatura', 'Culmen\nTotal', 'Culmen\nexpuesto'],
            [especie.morfologiaDetallada.pico.curvatura ?? 'No medida', 
             especie.morfologiaDetallada.pico.culmenTotal?.toString() ?? 'No medida',
             especie.morfologiaDetallada.pico.culmenExpuesto?.toString() ?? 'No medida'],
          ]),
          
          SizedBox(height: AppConstants.marginMedium),
          
          
          Text('Alas', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyTable([
            ['Altura', 'Cuerda'],
            [especie.morfologiaDetallada.alas.altura ?? 'No medida',
             especie.morfologiaDetallada.alas.cuerda?.toString() ?? 'No medida'],
          ]),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyTable([
            ['Distancia\nprimarias\nsecundarias', 'Envergadura'],
            [especie.morfologiaDetallada.alas.distanciaPrimariaSecundaria ?? 'No medida',
             especie.morfologiaDetallada.alas.envergadura?.toString() ?? 'No medida'],
          ]),
          
          SizedBox(height: AppConstants.marginMedium),
          
          Text('Patas', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyTable([
            ['Garra hallux', 'Longitud hallux'],
            [especie.morfologiaDetallada.patas.garraHallux?.toString() ?? 'No medida',
             especie.morfologiaDetallada.patas.longitudHallux ?? 'No medida'],
          ]),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyTable([
            ['Longitud tarso'],
            [especie.morfologiaDetallada.patas.longitudTarso?.toString() ?? 'No medida'],
          ]),
        ],
      ),
    );
  }

  Widget _buildMedidasAdicionalesSection() {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMorphologyRow(
            'Distancia\nprimarias\nsecundarias',
            'Envergadura',
            especie.morfologiaDetallada.alas.distanciaPrimariaSecundaria ?? 'No medida',
            especie.morfologiaDetallada.alas.envergadura?.toString() ?? 'No medida',
          ),
          
          SizedBox(height: AppConstants.marginMedium),
          
          Text('Patas', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyRow(
            'Garra hallux',
            'Longitud hallux',
            especie.morfologiaDetallada.patas.garraHallux?.toString() ?? 'No medida',
            especie.morfologiaDetallada.patas.longitudHallux ?? 'No medida',
          ),
          _buildMorphologyRow(
            'Longitud tarso',
            '',
            especie.morfologiaDetallada.patas.longitudTarso?.toString() ?? 'No medida',
            '',
          ),
          
          SizedBox(height: AppConstants.marginMedium),
          
          Text('Cola', style: AppTextStyles.subtitle1),
          SizedBox(height: AppConstants.marginSmall),
          
          _buildMorphologyRow(
            'Longitud',
            'Graduacion',
            especie.morfologiaDetallada.cola.longitud?.toString() ?? 'No medida',
            especie.morfologiaDetallada.cola.graduacion ?? 'No medida',
          ),
          _buildMorphologyRow(
            'Masa corporal',
            '',
            especie.morfologiaDetallada.masaCorporal?.toString() ?? 'No medida',
            '',
          ),
          
          SizedBox(height: AppConstants.marginMedium),
          
          Text(
            'Observaciones',
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.primary),
          ),
          SizedBox(height: AppConstants.marginSmall),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.note, size: AppConstants.iconSizeSmall, color: AppColors.textSecondary),
              SizedBox(width: AppConstants.marginSmall),
              Expanded(
                child: Text(
                  especie.observaciones ?? 'No hay observaciones registradas.',
                  style: AppTextStyles.body2,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.marginLarge),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey[600],
        size: 24,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        children: [
          Text('$label: ', style: AppTextStyles.subtitle2),
          Text(value, style: AppTextStyles.body2),
        ],
      ),
    );
  }

  Widget _buildCompositionRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppConstants.paddingSmall,
        horizontal: AppConstants.paddingSmall + 4,
      ),
      margin: EdgeInsets.only(bottom: AppConstants.paddingSmall / 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body2)),
          Text(value, style: AppTextStyles.subtitle2),
        ],
      ),
    );
  }

  Widget _buildMorphologyTable(List<List<String>> data) {
    return Table(
      border: TableBorder.all(color: AppColors.border),
      children: data.map((row) => TableRow(
        children: row.map((cell) => Container(
          padding: EdgeInsets.all(AppConstants.paddingSmall),
          child: Text(cell, style: AppTextStyles.caption),
        )).toList(),
      )).toList(),
    );
  }

  Widget _buildMorphologyRow(String label1, String label2, String value1, String value2) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.marginSmall),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label1, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                Text(value1, style: AppTextStyles.body2),
              ],
            ),
          ),
          if (label2.isNotEmpty) ...[
            SizedBox(width: AppConstants.marginMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label2, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  Text(value2, style: AppTextStyles.body2),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}