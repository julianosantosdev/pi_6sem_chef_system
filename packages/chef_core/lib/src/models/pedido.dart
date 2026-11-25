import 'json.dart';
import 'mesa.dart';
import 'status_pedido.dart';

/// Espelha `PedidoResponseDTO`.
class Pedido {
  const Pedido({
    required this.id,
    required this.mesa,
    required this.status,
    required this.criadoEm,
    required this.recebidoCozinhaEm,
    required this.itens,
    required this.totalCentavos,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        id: json['id'] as int,
        mesa: Mesa.fromJson(json['mesa'] as Map<String, dynamic>),
        status: StatusPedido.fromApi(json['statusPedido'] as String),
        criadoEm: lerData(json['criadoEm']),
        recebidoCozinhaEm: lerData(json['recebidoCozinhaEm']),
        itens: [
          for (final item in json['itens'] as List? ?? const [])
            ItemPedido.fromJson(item as Map<String, dynamic>),
        ],
        totalCentavos: lerCentavos(json['total']),
      );

  final int id;
  final Mesa mesa;
  final StatusPedido status;
  final DateTime? criadoEm;

  /// Preenchido quando a cozinha recebe o pedido pelo RabbitMQ.
  /// Enquanto for nulo, a cozinha ainda não pode alterar o status.
  final DateTime? recebidoCozinhaEm;

  final List<ItemPedido> itens;
  final int totalCentavos;

  bool get recebidoPelaCozinha => recebidoCozinhaEm != null;
}

/// Espelha `PedidoResponseDTO.Item`.
class ItemPedido {
  const ItemPedido({
    required this.produtoId,
    required this.nome,
    required this.quantidade,
    required this.precoUnitarioCentavos,
    required this.subtotalCentavos,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
        produtoId: json['produtoId'] as int,
        nome: json['nome'] as String,
        quantidade: json['quantidade'] as int,
        precoUnitarioCentavos: lerCentavos(json['precoUnitario']),
        subtotalCentavos: lerCentavos(json['subtotal']),
      );

  final int produtoId;
  final String nome;
  final int quantidade;
  final int precoUnitarioCentavos;
  final int subtotalCentavos;
}

/// Item enviado em `POST /pedidos` (`ItemPedidoRequestDTO`).
class NovoItemPedido {
  const NovoItemPedido({required this.produtoId, required this.quantidade});

  final int produtoId;
  final int quantidade;

  Map<String, dynamic> toJson() => {'produtoId': produtoId, 'quantidade': quantidade};
}
