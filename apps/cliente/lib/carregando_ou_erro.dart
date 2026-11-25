import 'package:material_ui/material_ui.dart';

/// Estado de carregamento inicial de uma tela: indicador de progresso ou erro com "Tentar de novo".
class CarregandoOuErro extends StatelessWidget {
  const CarregandoOuErro({super.key, required this.erro, required this.onTentar});

  final String? erro;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    if (erro == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(erro!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onTentar, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}
