import 'package:chef_core/chef_core.dart';

/// Como o cliente enxerga o andamento do pedido.
///
/// O status ABERTO da API se divide em dois momentos: antes e depois de o
/// pedido chegar à cozinha pelo RabbitMQ (`recebidoCozinhaEm`).
enum EtapaPedido {
  enviado('Enviado', 'Enviando para a cozinha…'),
  naFila('Recebido', 'A cozinha recebeu seu pedido'),
  preparando('Em preparo', 'Seu pedido está sendo preparado'),
  pronto('Pronto', 'Seu pedido está pronto!'),
  cancelado('Cancelado', 'Pedido cancelado pela cozinha');

  const EtapaPedido(this.rotulo, this.descricao);

  final String rotulo;
  final String descricao;

  static EtapaPedido de(Pedido p) => switch (p.status) {
    StatusPedido.aberto => p.recebidoPelaCozinha ? naFila : enviado,
    StatusPedido.preparando => preparando,
    StatusPedido.concluido => pronto,
    StatusPedido.cancelado => cancelado,
  };

  /// Etapas exibidas na linha do tempo (cancelado fica de fora).
  static const linhaDoTempo = [enviado, naFila, preparando, pronto];
}
