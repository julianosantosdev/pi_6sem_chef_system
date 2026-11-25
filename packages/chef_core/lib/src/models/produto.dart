import 'json.dart';

/// Espelha `ProdutoResponseDTO`. Usado principalmente pelo app do cliente.
class Produto {
  const Produto({
    required this.id,
    required this.nome,
    required this.precoCentavos,
    required this.quantidade,
    required this.categoria,
  });

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        id: json['id'] as int,
        nome: json['nome'] as String,
        precoCentavos: lerCentavos(json['precoVenda']),
        quantidade: json['quantidade'] as int? ?? 0,
        categoria: json['categoria'] as String? ?? 'OUTROS',
      );

  final int id;
  final String nome;
  final int precoCentavos;

  /// Quantidade em estoque.
  final int quantidade;

  /// BEBIDA, ENTRADA, PRATO_PRINCIPAL, SOBREMESA ou OUTROS.
  final String categoria;
}
