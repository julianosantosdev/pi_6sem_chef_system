import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mesa.dart';
import '../models/pedido.dart';
import '../models/produto.dart';
import '../models/status_pedido.dart';
import 'api_exception.dart';

/// Cliente HTTP da API ChefSystem.
///
/// Os apps não falam com o RabbitMQ: a mensageria acontece dentro da API.
/// Para acompanhar mudanças de status, os apps consultam a API periodicamente.
class ChefApi {
  ChefApi({required String baseUrl, http.Client? client, this.timeout = const Duration(seconds: 10)})
      : baseUrl = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
        _client = client ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final http.Client _client;

  // ---------- Mesas e produtos ----------

  Future<List<Mesa>> listarMesas() async =>
      _lista(await _get('mesas'), Mesa.fromJson);

  Future<List<Produto>> listarProdutos() async =>
      _lista(await _get('produtos'), Produto.fromJson);

  // ---------- Pedidos (app do cliente) ----------

  Future<List<Pedido>> listarPedidos({int? mesaId}) async =>
      _lista(await _get('pedidos', {if (mesaId != null) 'mesaId': '$mesaId'}), Pedido.fromJson);

  Future<Pedido> buscarPedido(int id) async =>
      Pedido.fromJson(await _get('pedidos/$id') as Map<String, dynamic>);

  Future<Pedido> criarPedido({required int mesaId, required List<NovoItemPedido> itens}) async {
    final json = await _enviar('POST', 'pedidos', {
      'mesaId': mesaId,
      'itens': [for (final item in itens) item.toJson()],
    });
    return Pedido.fromJson(json as Map<String, dynamic>);
  }

  // ---------- Cozinha ----------

  /// Pedidos que já chegaram à cozinha pelo RabbitMQ, do mais novo para o mais antigo.
  Future<List<Pedido>> listarPedidosCozinha() async =>
      _lista(await _get('cozinha/pedidos'), Pedido.fromJson);

  Future<Pedido> alterarStatus(int pedidoId, StatusPedido status) async {
    final json = await _enviar('PATCH', 'cozinha/pedidos/$pedidoId/status', {'status': status.valorApi});
    return Pedido.fromJson(json as Map<String, dynamic>);
  }

  void close() => _client.close();

  // ---------- Infra ----------

  Future<Object?> _get(String caminho, [Map<String, String>? query]) {
    final uri = baseUrl.resolve(caminho).replace(queryParameters: query?.isEmpty ?? true ? null : query);
    return _executar(() => _client.get(uri, headers: {'Accept': 'application/json'}));
  }

  Future<Object?> _enviar(String metodo, String caminho, Object corpo) {
    final request = http.Request(metodo, baseUrl.resolve(caminho))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json'
      ..body = jsonEncode(corpo);
    return _executar(() async => http.Response.fromStream(await _client.send(request)));
  }

  Future<Object?> _executar(Future<http.Response> Function() chamada) async {
    final http.Response resposta;
    try {
      resposta = await chamada().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('A API demorou demais para responder.');
    } on http.ClientException {
      // O pacote http embrulha SocketException (sem rede, porta fechada) em ClientException.
      throw ApiException('Não foi possível conectar à API em $baseUrl.');
    }

    final texto = utf8.decode(resposta.bodyBytes);
    final corpo = texto.isEmpty ? null : _decodificar(texto);

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return corpo;
    if (corpo is Map<String, dynamic>) throw ApiException.fromJson(resposta.statusCode, corpo);
    throw ApiException('Erro ${resposta.statusCode} na API.', status: resposta.statusCode);
  }

  static Object? _decodificar(String texto) {
    try {
      return jsonDecode(texto);
    } on FormatException {
      return null;
    }
  }

  static List<T> _lista<T>(Object? json, T Function(Map<String, dynamic>) converter) => [
        for (final item in json as List? ?? const []) converter(item as Map<String, dynamic>),
      ];
}
