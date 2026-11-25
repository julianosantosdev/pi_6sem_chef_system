import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import '../cardapio/cardapio_controller.dart';
import '../cardapio/cardapio_tela.dart';
import '../cardapio/carrinho.dart';
import '../pedidos/etapa_pedido.dart';
import '../pedidos/pedidos_mesa_controller.dart';
import '../pedidos/pedidos_mesa_tela.dart';

/// Tela principal da mesa: abas Cardápio e Meus pedidos.
class MesaHome extends StatefulWidget {
  const MesaHome({super.key, required this.api, required this.mesa, required this.intervaloAtualizacao});

  final ChefApi api;
  final Mesa mesa;
  final Duration intervaloAtualizacao;

  @override
  State<MesaHome> createState() => _MesaHomeState();
}

class _MesaHomeState extends State<MesaHome> {
  final _carrinho = Carrinho();
  late final _cardapio = CardapioController(widget.api, _carrinho)..carregar();
  late final _pedidos = PedidosMesaController(
    widget.api,
    widget.mesa,
    intervalo: widget.intervaloAtualizacao,
    aoMudarStatus: _avisarMudanca,
  )..iniciar();

  int _aba = 0;

  /// Pausa a atualização automática enquanto o app está fora da tela.
  late final _ciclo = AppLifecycleListener(onHide: _pedidos.pausar, onShow: _pedidos.retomar);

  @override
  void initState() {
    super.initState();
    _ciclo; // cria o listener
  }

  @override
  void dispose() {
    _ciclo.dispose();
    _pedidos.dispose();
    _cardapio.dispose();
    _carrinho.dispose();
    super.dispose();
  }

  void _avisarMudanca(Pedido pedido) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${pedido.id}: ${EtapaPedido.de(pedido).descricao}'),
        action: _aba == 1 ? null : SnackBarAction(label: 'Ver', onPressed: () => setState(() => _aba = 1)),
      ),
    );
  }

  void _pedidoEnviado(Pedido pedido) {
    _pedidos.adicionar(pedido);
    _cardapio.carregar(); // o estoque mudou
    setState(() => _aba = 1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pedido #${pedido.id} enviado para a cozinha!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Sem seta de voltar: "Trocar mesa" já faz isso e deixa a ação explícita.
        automaticallyImplyLeading: false,
        title: Text('Mesa ${widget.mesa.numero}'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Trocar mesa'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _aba,
        children: [
          CardapioTela(
            api: widget.api,
            mesa: widget.mesa,
            cardapio: _cardapio,
            carrinho: _carrinho,
            onPedidoEnviado: _pedidoEnviado,
          ),
          PedidosMesaTela(controller: _pedidos),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _pedidos,
        builder: (context, _) {
          final ativos = _pedidos.emAndamento.length;
          return NavigationBar(
            selectedIndex: _aba,
            onDestinationSelected: (i) => setState(() => _aba = i),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Cardápio'),
              NavigationDestination(
                icon: Badge(isLabelVisible: ativos > 0, label: Text('$ativos'), child: const Icon(Icons.receipt_long)),
                label: 'Meus pedidos',
              ),
            ],
          );
        },
      ),
    );
  }
}
