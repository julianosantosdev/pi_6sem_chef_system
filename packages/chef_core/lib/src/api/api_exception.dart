/// Erro devolvido pela API (formato `StandardError`) ou falha de conexão.
class ApiException implements Exception {
  const ApiException(this.mensagem, {this.status, this.titulo});

  /// Monta a exceção a partir do corpo `StandardError`:
  /// `{timestamp, status, error, message, path}`.
  factory ApiException.fromJson(int status, Map<String, dynamic> json) => ApiException(
        (json['message'] as String?) ?? (json['error'] as String?) ?? 'Erro $status na API.',
        status: status,
        titulo: json['error'] as String?,
      );

  /// Texto pronto para mostrar ao usuário.
  final String mensagem;

  /// Código HTTP; nulo quando nem chegou a haver resposta (sem rede, timeout).
  final int? status;

  /// Campo `error` do StandardError (ex.: "Conflito").
  final String? titulo;

  bool get semConexao => status == null;
  bool get naoEncontrado => status == 404;
  bool get conflito => status == 409;

  @override
  String toString() => status == null ? mensagem : 'HTTP $status: $mensagem';
}
