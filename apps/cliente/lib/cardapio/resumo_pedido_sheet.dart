import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import 'cardapio_controller.dart';
import 'cardapio_tela.dart';
import 'carrinho.dart';

/// Revisão do carrinho e envio do pedido. Fecha devolvendo o [Pedido] criado.
class ResumoPedidoSheet extends StatefulWidget {
  const ResumoPedidoSheet({
    super.key,
    required this.api,
    required this.mesa,
    required this.carrinho,
    required this.cardapio,
  });

  final ChefApi api;
  final Mesa mesa;
  final Carrinho carrinho;
  final CardapioController cardapio;

  @override
  State<ResumoPedidoSheet> createState() => _ResumoPedidoSheetState();
}

class _ResumoPedidoSheetState extends State<ResumoPedidoSheet> {
  bool _enviando = false;
  String? _erro;

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final pedido = await widget.api.criarPedido(mesaId: widget.mesa.id, itens: widget.carrinho.paraPedido());
      widget.carrinho.limpar();
      if (mounted) Navigator.of(context).pop(pedido);
    } on ApiException catch (e) {
      // 409 = estoque insuficiente: recarrega o cardápio para ajustar o carrinho.
      if (e.conflito || e.naoEncontrado) await widget.cardapio.carregar();
      if (mounted) {
        setState(() {
          _erro = e.mensagem;
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: widget.carrinho,
      builder: (context, _) {
        final carrinho = widget.carrinho;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Seu pedido · Mesa ${widget.mesa.numero}', style: textos.titleLarge),
                const SizedBox(height: 8),
                Flexible(
                  child: carrinho.vazio
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Carrinho vazio.')),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final (produto, qtd) in carrinho.itens)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(produto.nome),
                                subtitle: Text(formatarCentavos(produto.precoCentavos * qtd)),
                                trailing: SeletorQuantidade(produto: produto, carrinho: carrinho),
                              ),
                          ],
                        ),
                ),
                const Divider(),
                Row(
                  children: [
                    Text('Total', style: textos.titleMedium),
                    const Spacer(),
                    Text(formatarCentavos(carrinho.totalCentavos), style: textos.titleMedium),
                  ],
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: _enviando || carrinho.vazio ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Enviar para a cozinha'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
