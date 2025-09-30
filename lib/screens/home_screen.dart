import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../widgets/investigacion_card.dart';
import '../services/investigacion_service.dart';
import '../models/investigacion.dart';
import 'detalles_investigacion_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Investigacion> investigaciones = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarInvestigaciones();
  }

  Future<void> _cargarInvestigaciones() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final datos = await InvestigacionService.obtenerInvestigaciones();
      
      setState(() {
        investigaciones = datos;
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
        leading: Icon(Icons.menu, color: AppColors.textOnPrimary),
        title: Text('Home', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        actions: [
          CircleAvatar(
            backgroundColor: AppColors.surface,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          SizedBox(width: AppConstants.marginSmall),
          Icon(Icons.search, color: AppColors.textOnPrimary),
          SizedBox(width: AppConstants.marginMedium),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              AppConstants.homeTitle,
              style: AppTextStyles.title2,
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
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
            Text(
              AppConstants.loadingMessage,
              style: AppTextStyles.body2,
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppConstants.iconSizeLarge * 2,
              color: AppColors.error,
            ),
            SizedBox(height: AppConstants.marginMedium),
            Text(
              errorMessage!,
              style: AppTextStyles.bodyError,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.marginMedium),
            ElevatedButton(
              onPressed: _cargarInvestigaciones,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (investigaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: AppConstants.iconSizeLarge * 2,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppConstants.marginMedium),
            Text(
              AppConstants.noDataMessage,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarInvestigaciones,
      color: AppColors.primary,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: investigaciones.length,
        itemBuilder: (context, index) {
          final investigacion = investigaciones[index];
          return InvestigacionCard(
            titulo: investigacion.titulo,
            ubicacion: investigacion.ubicacion,
            descripcion: investigacion.descripcion,
            fecha: investigacion.fecha,
            habitat: investigacion.habitat,
            vegetacion: investigacion.vegetacion,
            estado: investigacion.estado,
            onPressed: () => _navegarADetalles(investigacion),
          );
        },
      ),
    );
  }

  void _navegarADetalles(Investigacion investigacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallesInvestigacionScreen(
          investigacion: investigacion,
        ),
      ),
    );
  }
}