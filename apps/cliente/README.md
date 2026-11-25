# Cliente (mesas)

App Android que fica na mesa. O cliente escolhe a mesa, monta o pedido pelo cardápio, envia para a cozinha e acompanha o preparo.

## Telas

1. **Escolha a mesa**: lista vinda de `GET /mesas`.
2. **Cardápio**: produtos de `GET /produtos` agrupados por categoria, com botões − / +. O app não deixa pedir mais do que o estoque.
3. **Revisão do pedido** (painel que sobe da parte de baixo): mostra os itens e o total e envia com `POST /pedidos`. Se a API recusar (por exemplo, estoque insuficiente), a mensagem aparece ali mesmo e o cardápio é recarregado.
4. **Meus pedidos**: `GET /pedidos?mesaId=` recarregado **a cada 5 s**, com uma linha do tempo:
   **Enviado → Recebido → Em preparo → Pronto**. Quando a cozinha muda o status, aparece um aviso.

"Enviado" e "Recebido" são o mesmo status `ABERTO` na API. O app distingue os dois por `recebidoCozinhaEm`, que a API preenche quando o pedido chega à cozinha pelo RabbitMQ.

## Rodar

```bash
flutter run                                              # emulador (API em 10.0.2.2:8080)
flutter run --dart-define=API_URL=http://IP_DO_PC:8080   # celular físico
```

## Código

| Arquivo | Papel |
|---|---|
| `lib/mesa/escolher_mesa_tela.dart` | Escolha da mesa |
| `lib/mesa/mesa_home.dart` | Abas Cardápio / Meus pedidos; é dono dos controllers |
| `lib/cardapio/carrinho.dart` | Itens escolhidos (produto → quantidade) |
| `lib/cardapio/cardapio_controller.dart` | Carrega os produtos e agrupa por categoria |
| `lib/cardapio/cardapio_tela.dart` | Lista do cardápio e o botão "Ver pedido" |
| `lib/cardapio/resumo_pedido_sheet.dart` | Revisão e envio do pedido |
| `lib/pedidos/pedidos_mesa_controller.dart` | Atualização periódica e detecção de mudança de status |
| `lib/pedidos/etapa_pedido.dart` | Como o status aparece para o cliente |
| `lib/pedidos/pedidos_mesa_tela.dart` | Cards com a linha do tempo |

## Testes

```bash
flutter test
```
