import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

String horaMinuto(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _tempoDecorrido(DateTime desde) {
  final minutos = DateTime.now().difference(desde).inMinutes;
  if (minutos < 1) return 'agora';
  if (minutos < 60) return 'há $minutos min';
  if (minutos < 24 * 60) return 'há ${minutos ~/ 60}h${(minutos % 60).toString().padLeft(2, '0')}';
  final dias = minutos ~/ (24 * 60);
  return dias == 1 ? 'há 1 dia' : 'há $dias dias';
}

class PedidoCard extends StatelessWidget {
  const PedidoCard({super.key, required this.pedido, required this.alterando, required this.onAlterar});

  final Pedido pedido;
  final bool alterando;
  final ValueChanged<StatusPedido> onAlterar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final textos = tema.textTheme;
    final criado = pedido.criadoEm;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Mesa ${pedido.mesa.numero}',
                        style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      _StatusChip(status: pedido.status),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('#${pedido.id}', style: textos.labelLarge),
                    if (criado != null)
                      Text(
                        pedido.status.finalizado
                            ? horaMinuto(criado)
                            : '${horaMinuto(criado)} · ${_tempoDecorrido(criado)}',
                        style: textos.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            for (final item in pedido.itens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${item.quantidade}×',
                        style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Text(item.nome, style: textos.titleMedium)),
                  ],
                ),
              ),
            if (!pedido.status.finalizado) ...[
              const SizedBox(height: 12),
              _Acoes(pedido: pedido, alterando: alterando, onAlterar: onAlterar),
            ],
          ],
        ),
      ),
    );
  }
}

class _Acoes extends StatelessWidget {
  const _Acoes({required this.pedido, required this.alterando, required this.onAlterar});

  final Pedido pedido;
  final bool alterando;
  final ValueChanged<StatusPedido> onAlterar;

  @override
  Widget build(BuildContext context) {
    final proximo = pedido.status.proximo;
    final erro = Theme.of(context).colorScheme.error;
    // Wrap: em tela estreita o botão principal desce para a linha de baixo.
    // SizedBox com largura total: senão o Wrap encolhe e o alinhamento à direita não acontece.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (alterando)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: erro),
            onPressed: alterando ? null : () => onAlterar(StatusPedido.cancelado),
            child: const Text('Cancelar'),
          ),
          if (proximo != null)
            FilledButton.icon(
              onPressed: alterando ? null : () => onAlterar(proximo),
              icon: Icon(proximo == StatusPedido.preparando ? Icons.local_fire_department : Icons.check),
              label: Text(proximo == StatusPedido.preparando ? 'Iniciar preparo' : 'Concluir'),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final StatusPedido status;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final (fundo, texto) = switch (status) {
      StatusPedido.aberto => (cores.tertiaryContainer, cores.onTertiaryContainer),
      StatusPedido.preparando => (cores.primaryContainer, cores.onPrimaryContainer),
      StatusPedido.concluido => (cores.secondaryContainer, cores.onSecondaryContainer),
      StatusPedido.cancelado => (cores.errorContainer, cores.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)),
      child: Text(status.rotulo, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: texto)),
    );
  }
}
