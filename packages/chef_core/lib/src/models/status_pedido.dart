/// Espelha `StatusPedido` da API: ABERTO → PREPARANDO → CONCLUIDO,
/// e CANCELADO a partir de ABERTO ou PREPARANDO.
enum StatusPedido {
  aberto('ABERTO', 'Aberto'),
  preparando('PREPARANDO', 'Em preparo'),
  concluido('CONCLUIDO', 'Concluído'),
  cancelado('CANCELADO', 'Cancelado');

  const StatusPedido(this.valorApi, this.rotulo);

  /// Valor exato que a API envia e recebe.
  final String valorApi;

  /// Texto para exibir ao usuário.
  final String rotulo;

  static StatusPedido fromApi(String valor) => StatusPedido.values.firstWhere(
        (s) => s.valorApi == valor,
        orElse: () => throw FormatException('Status de pedido desconhecido: $valor'),
      );

  bool get finalizado => this == concluido || this == cancelado;

  /// Mesma regra de `StatusPedido.permite` na API.
  bool permite(StatusPedido destino) => switch (this) {
        aberto => destino == preparando || destino == cancelado,
        preparando => destino == concluido || destino == cancelado,
        concluido || cancelado => false,
      };

  /// Próximo passo do fluxo normal (sem contar cancelamento).
  StatusPedido? get proximo => switch (this) {
        aberto => preparando,
        preparando => concluido,
        concluido || cancelado => null,
      };
}
