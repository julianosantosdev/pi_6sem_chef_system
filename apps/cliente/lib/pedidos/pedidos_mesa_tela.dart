import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import '../carregando_ou_erro.dart';
import 'etapa_pedido.dart';
import 'pedidos_mesa_controller.dart';

class PedidosMesaTela extends StatelessWidget {
  const PedidosMesaTela({super.key, required this.controller});

  final PedidosMesaController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.carregouUmaVez) {
          return CarregandoOuErro(erro: controller.erro, onTentar: controller.atualizar);
        }
        final pedidos = controller.pedidos;
        return RefreshIndicator(
          onRefresh: controller.atualizar,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (controller.erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Sem conexão com a API. Mostrando a última atualização.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (pedidos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text('Nenhum pedido ainda. Escolha algo no cardápio!')),
                ),
              for (final p in pedidos) _PedidoCard(pedido: p),
            ],
          ),
        );
      },
    );
  }
}

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final etapa = EtapaPedido.de(pedido);
    final criado = pedido.criadoEm;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Pedido #${pedido.id}', style: textos.titleMedium),
                const Spacer(),
                if (criado != null)
                  Text(
                    '${criado.hour.toString().padLeft(2, '0')}:${criado.minute.toString().padLeft(2, '0')}',
                    style: textos.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(etapa.descricao, style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (etapa == EtapaPedido.cancelado) _Cancelado() else _LinhaDoTempo(atual: etapa),
            const Divider(height: 24),
            for (final item in pedido.itens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${item.quantidade}× ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item.nome)),
                    Text(formatarCentavos(item.subtotalCentavos)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Total', style: textos.titleSmall),
                const Spacer(),
                Text(formatarCentavos(pedido.totalCentavos), style: textos.titleSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enviado → Recebido → Em preparo → Pronto.
class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo({required this.atual});

  final EtapaPedido atual;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final etapas = EtapaPedido.linhaDoTempo;
    final indiceAtual = etapas.indexOf(atual);
    Widget linha(bool ativa, {bool visivel = true}) =>
        Expanded(child: Container(height: 3, color: !visivel ? null : (ativa ? cores.primary : cores.outlineVariant)));

    // Cada etapa ocupa a mesma largura; o rótulo quebra linha se faltar espaço.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < etapas.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    linha(i <= indiceAtual, visivel: i > 0),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: i <= indiceAtual ? cores.primary : cores.surfaceContainerHighest,
                      child: i < indiceAtual || (i == indiceAtual && atual == EtapaPedido.pronto)
                          ? Icon(Icons.check, size: 16, color: cores.onPrimary)
                          : i == indiceAtual
                          ? CircleAvatar(radius: 4, backgroundColor: cores.onPrimary)
                          : null,
                    ),
                    linha(i < indiceAtual, visivel: i < etapas.length - 1),
                  ],
                ),
                const SizedBox(height: 4),
                Text(etapas[i].rotulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Cancelado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: cores.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.cancel, color: cores.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Fale com um atendente se tiver dúvidas.', style: TextStyle(color: cores.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
