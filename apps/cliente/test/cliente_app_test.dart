import 'dart:convert';

import 'package:chef_core/chef_core.dart';
import 'package:chef_cliente/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

/// API falsa em memória com o mesmo formato da API real.
class ApiFalsa {
  final produtos = <Map<String, dynamic>>[
    {'id': 1, 'nome': 'Suco de laranja', 'precoVenda': 12.00, 'quantidade': 30, 'categoria': 'BEBIDA'},
    {'id': 2, 'nome': 'Porcao de batata', 'precoVenda': 25.00, 'quantidade': 20, 'categoria': 'ENTRADA'},
    {'id': 4, 'nome': 'Pudim', 'precoVenda': 10.00, 'quantidade': 1, 'categoria': 'SOBREMESA'},
  ];
  final pedidos = <Map<String, dynamic>>[];
  final corposPost = <Object?>[];
  String? erroNoPost;

  void mudarStatus(int id, String status) =>
      pedidos.firstWhere((p) => p['id'] == id)['statusPedido'] = status;

  late final client = MockClient((req) async {
    http.Response json(Object corpo, [int status = 200]) =>
        http.Response.bytes(utf8.encode(jsonEncode(corpo)), status, headers: {'content-type': 'application/json'});

    switch ((req.method, req.url.path)) {
      case ('GET', '/mesas'):
        return json([
          for (var n = 1; n <= 4; n++) {'id': n, 'numero': n, 'quantidade': 4},
        ]);
      case ('GET', '/produtos'):
        return json(produtos);
      case ('GET', '/pedidos'):
        final mesaId = int.parse(req.url.queryParameters['mesaId']!);
        return json(pedidos.where((p) => p['mesa']['id'] == mesaId).toList().reversed.toList());
      case ('POST', '/pedidos'):
        final corpo = jsonDecode(req.body) as Map<String, dynamic>;
        corposPost.add(corpo);
        if (erroNoPost != null) {
          return json({'status': 409, 'error': 'Conflito', 'message': erroNoPost}, 409);
        }
        final mesaId = corpo['mesaId'] as int;
        final itens = [
          for (final i in corpo['itens'] as List)
            () {
              final prod = produtos.firstWhere((p) => p['id'] == i['produtoId']);
              final qtd = i['quantidade'] as int;
              return {
                'produtoId': prod['id'],
                'nome': prod['nome'],
                'quantidade': qtd,
                'precoUnitario': prod['precoVenda'],
                'subtotal': (prod['precoVenda'] as double) * qtd,
              };
            }(),
        ];
        final pedido = {
          'id': pedidos.length + 1,
          'mesa': {'id': mesaId, 'numero': mesaId, 'quantidade': 4},
          'statusPedido': 'ABERTO',
          'criadoEm': DateTime.now().toUtc().toIso8601String(),
          'recebidoCozinhaEm': null,
          'itens': itens,
          'total': itens.fold<double>(0, (s, i) => s + (i['subtotal'] as double)),
        };
        pedidos.add(pedido);
        return json(pedido, 201);
    }
    return http.Response('', 404);
  });
}

Future<ApiFalsa> abrirMesa(WidgetTester tester, {int mesa = 2}) async {
  telaDeCelular(tester);
  final api = ApiFalsa();
  await tester.pumpWidget(ClienteApp(api: ChefApi(baseUrl: 'http://api', client: api.client)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$mesa'));
  await tester.pumpAndSettle();
  return api;
}

/// Celular pequeno: os testes falham se algum layout estourar a tela.
void telaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> fecharApp(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('escolhe a mesa, monta o pedido e envia para a cozinha', (tester) async {
    final api = await abrirMesa(tester);

    expect(find.text('Mesa 2'), findsOneWidget);
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Bebidas'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar Porcao de batata'));
    await tester.pump();
    await tester.tap(find.byTooltip('Adicionar Suco de laranja'));
    await tester.pump();
    await tester.tap(find.byTooltip('Adicionar Suco de laranja'));
    await tester.pump();
    expect(find.text('Ver pedido (3)'), findsOneWidget);
    expect(find.text(r'R$ 49,00'), findsOneWidget);

    await tester.tap(find.text('Ver pedido (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar para a cozinha'));
    await tester.pumpAndSettle();

    expect(api.corposPost.single, {
      'mesaId': 2,
      'itens': [
        {'produtoId': 2, 'quantidade': 1},
        {'produtoId': 1, 'quantidade': 2},
      ],
    });
    expect(find.text('Pedido #1'), findsOneWidget, reason: 'foi para a aba Meus pedidos');
    expect(find.text('Enviando para a cozinha…'), findsOneWidget);

    await fecharApp(tester);
  });

  testWidgets('acompanha o status atualizado pela cozinha', (tester) async {
    final api = await abrirMesa(tester);
    await tester.tap(find.byTooltip('Adicionar Pudim'));
    await tester.pump();
    await tester.tap(find.text('Ver pedido (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar para a cozinha'));
    await tester.pumpAndSettle();

    api.mudarStatus(1, 'PREPARANDO');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Seu pedido está sendo preparado'), findsOneWidget);
    expect(find.text('Pedido #1: Seu pedido está sendo preparado'), findsOneWidget, reason: 'aviso');

    api.mudarStatus(1, 'CONCLUIDO');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Seu pedido está pronto!'), findsOneWidget);

    await fecharApp(tester);
  });

  testWidgets('não deixa passar do estoque', (tester) async {
    await abrirMesa(tester);
    await tester.tap(find.byTooltip('Adicionar Pudim')); // estoque = 1
    await tester.pump();
    final botao = tester.widget<IconButton>(
      find.ancestor(of: find.byTooltip('Adicionar Pudim'), matching: find.byType(IconButton)),
    );
    expect(botao.onPressed, isNull);
    expect(find.text('Ver pedido (1)'), findsOneWidget);

    await fecharApp(tester);
  });

  testWidgets('mostra o erro da API ao enviar', (tester) async {
    final api = await abrirMesa(tester);
    api.erroNoPost = 'Estoque insuficiente para Porcao de batata.';
    await tester.tap(find.byTooltip('Adicionar Porcao de batata'));
    await tester.pump();
    await tester.tap(find.text('Ver pedido (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar para a cozinha'));
    await tester.pumpAndSettle();

    expect(find.text('Estoque insuficiente para Porcao de batata.'), findsOneWidget);
    expect(find.text('Enviar para a cozinha'), findsOneWidget, reason: 'continua na revisão do pedido');

    await fecharApp(tester);
  });
}
