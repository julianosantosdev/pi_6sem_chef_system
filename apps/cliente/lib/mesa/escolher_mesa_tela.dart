import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import '../carregando_ou_erro.dart';
import 'mesa_home.dart';

/// Primeira tela: escolhe em qual mesa o aparelho está.
class EscolherMesaTela extends StatefulWidget {
  const EscolherMesaTela({super.key, required this.api, required this.intervaloAtualizacao});

  final ChefApi api;
  final Duration intervaloAtualizacao;

  @override
  State<EscolherMesaTela> createState() => _EscolherMesaTelaState();
}

class _EscolherMesaTelaState extends State<EscolherMesaTela> {
  List<Mesa>? _mesas;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final mesas = await widget.api.listarMesas();
      mesas.sort((a, b) => a.numero.compareTo(b.numero));
      if (mounted) setState(() => _mesas = mesas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
  }

  void _abrir(Mesa mesa) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MesaHome(api: widget.api, mesa: mesa, intervaloAtualizacao: widget.intervaloAtualizacao),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mesas = _mesas;
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha a mesa')),
      body: mesas == null
          ? CarregandoOuErro(erro: _erro, onTentar: _carregar)
          : RefreshIndicator(
              onRefresh: _carregar,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: mesas.length,
                itemBuilder: (context, i) => _MesaBotao(mesa: mesas[i], onTap: () => _abrir(mesas[i])),
              ),
            ),
    );
  }
}

class _MesaBotao extends StatelessWidget {
  const _MesaBotao({required this.mesa, required this.onTap});

  final Mesa mesa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mesa', style: textos.labelLarge),
            Text('${mesa.numero}', style: textos.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('${mesa.quantidade} lugares', style: textos.bodySmall),
          ],
        ),
      ),
    );
  }
}
