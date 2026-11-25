import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import 'mesa/escolher_mesa_tela.dart';

class ClienteApp extends StatelessWidget {
  const ClienteApp({super.key, required this.api, this.intervaloAtualizacao = const Duration(seconds: 5)});

  final ChefApi api;

  /// De quanto em quanto tempo os pedidos da mesa são recarregados da API.
  final Duration intervaloAtualizacao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChefSystem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
      ),
      home: EscolherMesaTela(api: api, intervaloAtualizacao: intervaloAtualizacao),
    );
  }
}
