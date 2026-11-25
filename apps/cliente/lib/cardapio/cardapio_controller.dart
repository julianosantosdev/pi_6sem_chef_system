import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import 'carrinho.dart';

/// Ordem e nomes das categorias no cardápio (enum CategoriaProduto da API).
const categorias = {
  'ENTRADA': 'Entradas',
  'PRATO_PRINCIPAL': 'Pratos principais',
  'SOBREMESA': 'Sobremesas',
  'BEBIDA': 'Bebidas',
  'OUTROS': 'Outros',
};

class CardapioController extends ChangeNotifier {
  CardapioController(this._api, this._carrinho);

  final ChefApi _api;
  final Carrinho _carrinho;

  List<Produto>? _produtos;
  String? _erro;
  bool _descartado = false;

  List<Produto>? get produtos => _produtos;
  String? get erro => _erro;

  /// Produtos agrupados por categoria, na ordem de [categorias].
  List<(String, List<Produto>)> get porCategoria {
    final grupos = <String, List<Produto>>{};
    for (final p in _produtos ?? const <Produto>[]) {
      grupos.putIfAbsent(p.categoria, () => []).add(p);
    }
    final ordem = [...categorias.keys, ...grupos.keys.where((c) => !categorias.containsKey(c))];
    return [
      for (final c in ordem)
        if (grupos[c] case final lista?) (categorias[c] ?? c, lista..sort((a, b) => a.nome.compareTo(b.nome))),
    ];
  }

  Future<void> carregar() async {
    _erro = null;
    notifyListeners();
    try {
      final produtos = await _api.listarProdutos();
      if (_descartado) return;
      _produtos = produtos;
      _carrinho.sincronizar(produtos);
    } on ApiException catch (e) {
      if (_descartado) return;
      _erro = e.mensagem;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
