import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import '../carregando_ou_erro.dart';
import 'cardapio_controller.dart';
import 'carrinho.dart';
import 'resumo_pedido_sheet.dart';

class CardapioTela extends StatelessWidget {
  const CardapioTela({
    super.key,
    required this.api,
    required this.mesa,
    required this.cardapio,
    required this.carrinho,
    required this.onPedidoEnviado,
  });

  final ChefApi api;
  final Mesa mesa;
  final CardapioController cardapio;
  final Carrinho carrinho;
  final ValueChanged<Pedido> onPedidoEnviado;

  Future<void> _abrirResumo(BuildContext context) async {
    final pedido = await showModalBottomSheet<Pedido>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ResumoPedidoSheet(api: api, mesa: mesa, carrinho: carrinho, cardapio: cardapio),
    );
    if (pedido != null) onPedidoEnviado(pedido);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([cardapio, carrinho]),
      builder: (context, _) {
        if (cardapio.produtos == null) {
          return CarregandoOuErro(erro: cardapio.erro, onTentar: cardapio.carregar);
        }
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: cardapio.carregar,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final (categoria, produtos) in cardapio.porCategoria) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                        child: Text(categoria, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      for (final p in produtos) _ProdutoTile(produto: p, carrinho: carrinho),
                    ],
                  ],
                ),
              ),
            ),
            if (!carrinho.vazio)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => _abrirResumo(context),
                    child: Row(
                      children: [
                        Expanded(child: Text('Ver pedido (${carrinho.totalItens})', overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text(formatarCentavos(carrinho.totalCentavos)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProdutoTile extends StatelessWidget {
  const _ProdutoTile({required this.produto, required this.carrinho});

  final Produto produto;
  final Carrinho carrinho;

  @override
  Widget build(BuildContext context) {
    final esgotado = produto.quantidade <= 0;
    return ListTile(
      enabled: !esgotado,
      title: Text(produto.nome),
      subtitle: Text(esgotado ? 'Esgotado' : formatarCentavos(produto.precoCentavos)),
      trailing: esgotado ? null : SeletorQuantidade(produto: produto, carrinho: carrinho),
    );
  }
}

/// Botões − quantidade + de um produto no carrinho.
class SeletorQuantidade extends StatelessWidget {
  const SeletorQuantidade({super.key, required this.produto, required this.carrinho});

  final Produto produto;
  final Carrinho carrinho;

  @override
  Widget build(BuildContext context) {
    final qtd = carrinho.quantidade(produto.id);
    final adicionar = IconButton.filledTonal(
      tooltip: 'Adicionar ${produto.nome}',
      onPressed: carrinho.podeAdicionar(produto) ? () => carrinho.adicionar(produto) : null,
      icon: const Icon(Icons.add),
    );
    if (qtd == 0) return adicionar;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Remover ${produto.nome}',
          onPressed: () => carrinho.remover(produto),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 28,
          child: Text('$qtd', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ),
        adicionar,
      ],
    );
  }
}
