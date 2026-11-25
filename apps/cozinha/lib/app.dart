import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import 'pedidos/pedidos_tela.dart';

class CozinhaApp extends StatelessWidget {
  const CozinhaApp({super.key, required this.api, this.intervaloAtualizacao = const Duration(seconds: 5)});

  final ChefApi api;

  /// De quanto em quanto tempo a lista é recarregada da API.
  final Duration intervaloAtualizacao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChefSystem · Cozinha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark),
      ),
      home: PedidosTela(api: api, intervaloAtualizacao: intervaloAtualizacao),
    );
  }
}
