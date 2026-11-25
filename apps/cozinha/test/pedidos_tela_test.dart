import 'dart:convert';

import 'package:chef_core/chef_core.dart';
import 'package:chef_cozinha/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

/// API falsa em memória que imita /cozinha/pedidos.
class ApiFalsa {
  final pedidos = <int, Map<String, dynamic>>{};
  final patches = <String>[];

  void adicionar(int id, {int mesa = 1, String status = 'ABERTO', String item = 'X-Burger'}) {
    pedidos[id] = {
      'id': id,
      'mesa': {'id': mesa, 'numero': mesa, 'quantidade': 4},
      'statusPedido': status,
      'criadoEm': DateTime.now().toUtc().toIso8601String(),
      'recebidoCozinhaEm': DateTime.now().toUtc().toIso8601String(),
      'itens': [
        {'produtoId': 1, 'nome': item, 'quantidade': 2, 'precoUnitario': 20, 'subtotal': 40},
      ],
      'total': 40,
    };
  }

  late final client = MockClient((req) async {
    http.Response json(Object corpo, [int status = 200]) =>
        http.Response.bytes(utf8.encode(jsonEncode(corpo)), status, headers: {'content-type': 'application/json'});

    if (req.method == 'GET' && req.url.path == '/cozinha/pedidos') {
      return json(pedidos.values.toList().reversed.toList());
    }
    final patch = RegExp(r'^/cozinha/pedidos/(\d+)/status$').firstMatch(req.url.path);
    if (req.method == 'PATCH' && patch != null) {
      final pedido = pedidos[int.parse(patch.group(1)!)]!;
      final destino = StatusPedido.fromApi(jsonDecode(req.body)['status'] as String);
      final atual = StatusPedido.fromApi(pedido['statusPedido'] as String);
      patches.add('${pedido['id']}:${destino.valorApi}');
      if (!atual.permite(destino)) {
        return json({'status': 409, 'error': 'Conflito', 'message': 'Transição não permitida.'}, 409);
      }
      pedido['statusPedido'] = destino.valorApi;
      return json(pedido);
    }
    return http.Response('', 404);
  });
}

Future<ApiFalsa> abrirApp(WidgetTester tester, void Function(ApiFalsa api) preparar) async {
  telaDeCelular(tester);
  final falsa = ApiFalsa();
  preparar(falsa);
  await tester.pumpWidget(CozinhaApp(
    api: ChefApi(baseUrl: 'http://api', client: falsa.client),
    intervaloAtualizacao: const Duration(seconds: 5),
  ));
  await tester.pumpAndSettle();
  return falsa;
}

/// Celular pequeno: os testes falham se algum layout estourar a tela.
void telaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> fecharApp(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('mostra pedidos novos e avança o status até concluído', (tester) async {
    final api = await abrirApp(tester, (api) => api.adicionar(1, mesa: 3));

    expect(find.text('Mesa 3'), findsOneWidget);
    expect(find.text('X-Burger'), findsOneWidget);

    await tester.tap(find.text('Iniciar preparo'));
    await tester.pumpAndSettle();
    expect(api.patches, ['1:PREPARANDO']);
    expect(find.text('Mesa 3'), findsNothing, reason: 'saiu da aba Novos');

    await tester.tap(find.text('Em preparo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(api.patches, ['1:PREPARANDO', '1:CONCLUIDO']);

    await tester.tap(find.text('Finalizados'));
    await tester.pumpAndSettle();
    expect(find.text('Mesa 3'), findsOneWidget);
    expect(find.text('Concluir'), findsNothing);

    await fecharApp(tester);
  });

  testWidgets('cancelar pede confirmação', (tester) async {
    final api = await abrirApp(tester, (api) => api.adicionar(5, mesa: 2));

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(api.patches, isEmpty);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar pedido'));
    await tester.pumpAndSettle();
    expect(api.patches, ['5:CANCELADO']);

    await fecharApp(tester);
  });

  testWidgets('a atualização automática traz pedidos novos e avisa', (tester) async {
    final api = await abrirApp(tester, (_) {});
    expect(find.text('Nenhum pedido novo.'), findsOneWidget);

    api.adicionar(9, mesa: 7);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Mesa 7'), findsOneWidget);
    expect(find.text('Novo pedido da mesa 7'), findsOneWidget);

    await fecharApp(tester);
  });

  testWidgets('mostra erro quando a API não responde', (tester) async {
    await tester.pumpWidget(CozinhaApp(
      api: ChefApi(
        baseUrl: 'http://api',
        client: MockClient((_) async => throw http.ClientException('Connection refused')),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);

    await fecharApp(tester);
  });
}
