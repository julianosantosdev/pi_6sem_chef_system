import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import 'pedido_card.dart';
import 'pedidos_controller.dart';

class PedidosTela extends StatefulWidget {
  const PedidosTela({super.key, required this.api, required this.intervaloAtualizacao});

  final ChefApi api;
  final Duration intervaloAtualizacao;

  @override
  State<PedidosTela> createState() => _PedidosTelaState();
}

class _PedidosTelaState extends State<PedidosTela> {
  late final PedidosController _controller = PedidosController(
    widget.api,
    intervalo: widget.intervaloAtualizacao,
    aoChegarPedidos: _avisarNovos,
  )..iniciar();

  /// Pausa a atualização automática enquanto o app está fora da tela.
  late final _ciclo = AppLifecycleListener(onHide: _controller.pausar, onShow: _controller.retomar);

  @override
  void initState() {
    super.initState();
    _ciclo; // cria o listener
  }

  @override
  void dispose() {
    _ciclo.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _avisarNovos(List<Pedido> novos) {
    final mesas = novos.map((p) => p.mesa.numero).toSet().toList()..sort();
    final texto = novos.length == 1
        ? 'Novo pedido da mesa ${mesas.single}'
        : '${novos.length} novos pedidos (mesas ${mesas.join(', ')})';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _alterar(Pedido pedido, StatusPedido destino) async {
    if (destino == StatusPedido.cancelado && !await _confirmarCancelamento(pedido)) return;
    final erro = await _controller.alterarStatus(pedido, destino);
    if (erro != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erro), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  Future<bool> _confirmarCancelamento(Pedido pedido) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar pedido #${pedido.id}?'),
        content: Text('O pedido da mesa ${pedido.mesa.numero} será cancelado e os itens voltam ao estoque.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    return confirmou ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Cozinha'),
              actions: [
                if (c.atualizadoEm != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      'Atualizado ${horaMinuto(c.atualizadoEm!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                IconButton(tooltip: 'Atualizar', icon: const Icon(Icons.refresh), onPressed: c.atualizar),
              ],
              bottom: TabBar(
                tabs: [
                  _aba('Novos', c.novos.length),
                  _aba('Em preparo', c.emPreparo.length),
                  _aba('Finalizados', null),
                ],
              ),
            ),
            body: Column(
              children: [
                if (c.erro != null) _BannerErro(mensagem: c.erro!, onTentar: c.atualizar),
                Expanded(
                  child: !c.carregouUmaVez
                      ? Center(child: c.erro == null ? const CircularProgressIndicator() : null)
                      : TabBarView(
                          children: [
                            _lista(c.novos, 'Nenhum pedido novo.'),
                            _lista(c.emPreparo, 'Nenhum pedido em preparo.'),
                            _lista(c.finalizados, 'Nenhum pedido finalizado.'),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Tab _aba(String texto, int? quantidade) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(texto, overflow: TextOverflow.ellipsis, softWrap: false)),
        if (quantidade != null && quantidade > 0) ...[const SizedBox(width: 8), Badge(label: Text('$quantidade'))],
      ],
    ),
  );

  Widget _lista(List<Pedido> pedidos, String vazio) {
    return RefreshIndicator(
      onRefresh: _controller.atualizar,
      child: pedidos.isEmpty
          // ListView para o "puxar para atualizar" funcionar mesmo vazio.
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(child: Text(vazio)),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pedidos.length,
              itemBuilder: (context, i) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: PedidoCard(
                    pedido: pedidos[i],
                    alterando: _controller.alterando(pedidos[i].id),
                    onAlterar: (destino) => _alterar(pedidos[i], destino),
                  ),
                ),
              ),
            ),
    );
  }
}

class _BannerErro extends StatelessWidget {
  const _BannerErro({required this.mensagem, required this.onTentar});

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Material(
      color: cores.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: cores.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(mensagem, style: TextStyle(color: cores.onErrorContainer)),
            ),
            TextButton(onPressed: onTentar, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}
