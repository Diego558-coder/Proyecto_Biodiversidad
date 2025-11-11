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
  late Future<List<Investigacion>> _investigacionesFuture;

  @override
  void initState() {
    super.initState();
    _investigacionesFuture = InvestigacionService.obtenerInvestigaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Investigaciones', style: AppTextStyles.appBarTitle),
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
      body: FutureBuilder<List<Investigacion>>(
        future: _investigacionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (snapshot.hasError) {
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
                    AppConstants.errorMessage,
                    style: AppTextStyles.bodyError,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppConstants.marginMedium),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _investigacionesFuture = InvestigacionService.obtenerInvestigaciones();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final investigaciones = snapshot.data!;
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
              onRefresh: () async {
                setState(() {
                  _investigacionesFuture = InvestigacionService.obtenerInvestigaciones();
                });
              },
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
          } else {
            return Center(child: Text('No hay datos disponibles'));
          }
        },
      ),
    );
  }

  Future<void> _navegarADetalles(Investigacion investigacion) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final detalle = await InvestigacionService.obtenerInvestigacionPorId(investigacion.id);
      if (!mounted) return;
      Navigator.pop(context); // cerrar diálogo

      if (detalle == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontraron detalles para esta investigación.')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallesInvestigacionScreen(
            investigacion: detalle,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar detalles: $e')),
      );
    }
  }
}