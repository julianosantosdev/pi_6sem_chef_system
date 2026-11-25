# chef_core

Código compartilhado entre os apps **cliente** e **cozinha**:

- `models/`: `Mesa`, `Produto`, `Pedido`, `ItemPedido` e `StatusPedido`, que espelham os DTOs da API.
- `api/`: `ChefApi`, o cliente HTTP com todos os endpoints, e `ApiException`, o erro no formato `StandardError`.

Quando um DTO mudar na API, ajuste o model aqui e rode `dart test`.
