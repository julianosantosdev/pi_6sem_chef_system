import 'dart:convert';

import 'package:chef_core/chef_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Exemplo no formato real de `PedidoResponseDTO`.
Map<String, dynamic> pedidoJson({int id = 7, String status = 'ABERTO'}) => {
      'id': id,
      'mesa': {'id': 3, 'numero': 3, 'quantidade': 4},
      'statusPedido': status,
      'criadoEm': '2026-11-25T12:30:00.123456Z',
      'recebidoCozinhaEm': '2026-11-25T12:30:02Z',
      'itens': [
        {'produtoId': 1, 'nome': 'X-Burger', 'quantidade': 2, 'precoUnitario': 25.9, 'subtotal': 51.8},
        {'produtoId': 4, 'nome': 'Suco', 'quantidade': 1, 'precoUnitario': 8, 'subtotal': 8.00},
      ],
      'total': 59.80,
    };

http.Response jsonResponse(Object corpo, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('Pedido.fromJson', () {
    test('lê o DTO da API', () {
      final p = Pedido.fromJson(pedidoJson());
      expect(p.id, 7);
      expect(p.mesa.numero, 3);
      expect(p.status, StatusPedido.aberto);
      expect(p.recebidoPelaCozinha, isTrue);
      expect(p.criadoEm!.toUtc(), DateTime.utc(2026, 11, 25, 12, 30, 0, 123, 456));
      expect(p.itens.map((i) => i.nome), ['X-Burger', 'Suco']);
      expect(p.itens.first.subtotalCentavos, 5180);
      expect(p.totalCentavos, 5980);
    });

    test('aceita recebidoCozinhaEm nulo', () {
      final p = Pedido.fromJson(pedidoJson()..['recebidoCozinhaEm'] = null);
      expect(p.recebidoPelaCozinha, isFalse);
    });
  });

  group('StatusPedido', () {
    test('segue as transições da API', () {
      expect(StatusPedido.aberto.permite(StatusPedido.preparando), isTrue);
      expect(StatusPedido.aberto.permite(StatusPedido.concluido), isFalse);
      expect(StatusPedido.preparando.permite(StatusPedido.concluido), isTrue);
      expect(StatusPedido.preparando.permite(StatusPedido.cancelado), isTrue);
      expect(StatusPedido.concluido.permite(StatusPedido.cancelado), isFalse);
      expect(StatusPedido.aberto.proximo, StatusPedido.preparando);
      expect(StatusPedido.concluido.proximo, isNull);
    });

    test('rejeita status desconhecido', () {
      expect(() => StatusPedido.fromApi('ENTREGUE'), throwsFormatException);
    });
  });

  test('formatarCentavos', () {
    expect(formatarCentavos(5980), r'R$ 59,80');
    expect(formatarCentavos(123456789), r'R$ 1.234.567,89');
    expect(formatarCentavos(5), r'R$ 0,05');
  });

  group('ChefApi', () {
    test('lista pedidos da cozinha', () async {
      late http.Request recebido;
      final api = ChefApi(
        baseUrl: 'http://api:8080',
        client: MockClient((req) async {
          recebido = req;
          return jsonResponse([pedidoJson(id: 2), pedidoJson(id: 1)]);
        }),
      );
      final pedidos = await api.listarPedidosCozinha();
      expect(recebido.method, 'GET');
      expect(recebido.url.toString(), 'http://api:8080/cozinha/pedidos');
      expect(pedidos.map((p) => p.id), [2, 1]);
    });

    test('altera status com PATCH', () async {
      late http.Request recebido;
      final api = ChefApi(
        baseUrl: 'http://api:8080/',
        client: MockClient((req) async {
          recebido = req;
          return jsonResponse(pedidoJson(status: 'PREPARANDO'));
        }),
      );
      final p = await api.alterarStatus(7, StatusPedido.preparando);
      expect(recebido.method, 'PATCH');
      expect(recebido.url.path, '/cozinha/pedidos/7/status');
      expect(jsonDecode(recebido.body), {'status': 'PREPARANDO'});
      expect(p.status, StatusPedido.preparando);
    });

    test('filtra pedidos por mesa e cria pedido', () async {
      final chamadas = <http.Request>[];
      final api = ChefApi(
        baseUrl: 'http://api:8080',
        client: MockClient((req) async {
          chamadas.add(req);
          return req.method == 'POST' ? jsonResponse(pedidoJson(), 201) : jsonResponse([]);
        }),
      );
      await api.listarPedidos(mesaId: 3);
      await api.criarPedido(mesaId: 3, itens: const [NovoItemPedido(produtoId: 1, quantidade: 2)]);
      expect(chamadas[0].url.toString(), 'http://api:8080/pedidos?mesaId=3');
      expect(jsonDecode(chamadas[1].body), {
        'mesaId': 3,
        'itens': [
          {'produtoId': 1, 'quantidade': 2},
        ],
      });
    });

    test('converte StandardError em ApiException', () async {
      final api = ChefApi(
        baseUrl: 'http://api:8080',
        client: MockClient((_) async => jsonResponse({
              'timestamp': '2026-11-25T12:00:00Z',
              'status': 409,
              'error': 'Conflito',
              'message': 'Transição de CONCLUIDO para CANCELADO não permitida.',
              'path': '/cozinha/pedidos/7/status',
            }, 409)),
      );
      await expectLater(
        api.alterarStatus(7, StatusPedido.cancelado),
        throwsA(isA<ApiException>()
            .having((e) => e.conflito, 'conflito', isTrue)
            .having((e) => e.mensagem, 'mensagem', contains('não permitida'))),
      );
    });

    test('falha de conexão vira ApiException sem status', () async {
      final api = ChefApi(
        baseUrl: 'http://api:8080',
        client: MockClient((_) async => throw http.ClientException('Connection refused')),
      );
      await expectLater(
        api.listarPedidosCozinha(),
        throwsA(isA<ApiException>().having((e) => e.semConexao, 'semConexao', isTrue)),
      );
    });
  });
}
