# Cozinha

App Android da cozinha. Ele lista os pedidos que chegaram das mesas e muda o status de cada um:
**Novo → Em preparo → Concluído**. Também dá para cancelar.

## Rodar

1. Suba a API (repositório da API): `docker compose up -d`.
   O RabbitMQ precisa estar no ar. É por ele que o pedido chega à cozinha, e até isso acontecer o pedido não aparece aqui.
2. Rode o app:

```bash
# Emulador Android (10.0.2.2 = localhost do PC)
flutter run

# Celular físico na mesma rede: use o IP do PC
flutter run --dart-define=API_URL=http://192.168.0.10:8080
```

Para o celular físico acessar a API, a porta no `compose.yaml` da API tem que ser `"8080:8080"`, e não `"127.0.0.1:8080:8080"`.

## Como funciona

- A lista vem de `GET /cozinha/pedidos` e é recarregada **a cada 5 s**. A API não avisa o app quando algo muda.
- Os botões chamam `PATCH /cozinha/pedidos/{id}/status`.
- Quando aparece um pedido novo, o app mostra um aviso.
- `lib/pedidos/pedidos_controller.dart` guarda o estado e faz a atualização periódica.
- `lib/pedidos/pedidos_tela.dart` monta as abas, os avisos e a confirmação de cancelamento.
- `lib/pedidos/pedido_card.dart` desenha o card de cada pedido.
- Models e o cliente HTTP ficam em [`packages/chef_core`](../../packages/chef_core).

## Testes

```bash
flutter test
```
