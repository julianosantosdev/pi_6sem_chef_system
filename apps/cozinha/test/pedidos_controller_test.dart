import 'dart:async';
import 'dart:convert';

import 'package:chef_core/chef_core.dart';
import 'package:chef_cozinha/pedidos/pedidos_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('requisição congelada em segundo plano não vira erro nem trava a atualização', () async {
    final respostas = <Completer<http.Response>>[];
    final api = ChefApi(
      baseUrl: 'http://api',
      client: MockClient((_) {
        final c = Completer<http.Response>();
        respostas.add(c);
        return c.future;
      }),
    );
    final controller = PedidosController(api, intervalo: const Duration(hours: 1));

    controller.iniciar(); // 1ª requisição fica pendurada
    await pumpEventQueue();
    controller.pausar(); // app foi para segundo plano
    respostas[0].completeError(http.ClientException('timeout'));
    await pumpEventQueue();
    expect(controller.erro, isNull, reason: 'erro da requisição congelada é ignorado');

    controller.retomar(); // app voltou: nova requisição na hora
    await pumpEventQueue();
    expect(respostas, hasLength(2), reason: 'não ficou travado em _buscando');
    respostas[1].complete(http.Response(jsonEncode([]), 200));
    await pumpEventQueue();
    expect(controller.carregouUmaVez, isTrue);
    expect(controller.erro, isNull);

    controller.dispose();
  });
}
