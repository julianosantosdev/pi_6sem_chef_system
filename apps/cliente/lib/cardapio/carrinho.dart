import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

/// Itens escolhidos pela mesa antes de enviar o pedido.
///
/// A API exige cada produto uma única vez com a quantidade total, então o
/// carrinho guarda produto → quantidade.
class Carrinho extends ChangeNotifier {
  final Map<int, (Produto, int)> _itens = {};

  bool get vazio => _itens.isEmpty;
  int quantidade(int produtoId) => _itens[produtoId]?.$2 ?? 0;
  int get totalItens => _itens.values.fold(0, (soma, i) => soma + i.$2);
  int get totalCentavos => _itens.values.fold(0, (soma, i) => soma + i.$1.precoCentavos * i.$2);

  List<(Produto, int)> get itens => _itens.values.toList()..sort((a, b) => a.$1.nome.compareTo(b.$1.nome));

  /// Não deixa passar do estoque informado pela API.
  bool podeAdicionar(Produto produto) => quantidade(produto.id) < produto.quantidade;

  void adicionar(Produto produto) {
    if (!podeAdicionar(produto)) return;
    _itens[produto.id] = (produto, quantidade(produto.id) + 1);
    notifyListeners();
  }

  void remover(Produto produto) {
    final atual = quantidade(produto.id);
    if (atual <= 1) {
      _itens.remove(produto.id);
    } else {
      _itens[produto.id] = (produto, atual - 1);
    }
    notifyListeners();
  }

  /// Atualiza preços e estoque com o cardápio recarregado, ajustando o que passou do estoque
  /// e tirando o que saiu do cardápio.
  void sincronizar(List<Produto> cardapio) {
    final porId = {for (final p in cardapio) p.id: p};
    for (final id in _itens.keys.toList()) {
      final produto = porId[id];
      final qtd = produto == null ? 0 : quantidade(id).clamp(0, produto.quantidade);
      if (qtd == 0) {
        _itens.remove(id);
      } else {
        _itens[id] = (produto!, qtd);
      }
    }
    notifyListeners();
  }

  List<NovoItemPedido> paraPedido() => [
    for (final (produto, qtd) in _itens.values) NovoItemPedido(produtoId: produto.id, quantidade: qtd),
  ];

  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}
