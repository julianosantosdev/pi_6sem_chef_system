import 'dart:async';

import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

/// Estado da tela de pedidos da cozinha.
///
/// A API não envia eventos para o app (não há WebSocket/SSE), então a lista é
/// recarregada a cada [intervalo]. Os pedidos chegam à cozinha pelo RabbitMQ
/// dentro da API, e só aparecem aqui depois disso.
class PedidosController extends ChangeNotifier {
  PedidosController(this._api, {this.intervalo = const Duration(seconds: 5), this.aoChegarPedidos});

  final ChefApi _api;
  final Duration intervalo;

  /// Chamado com os pedidos que apareceram desde a última atualização.
  final void Function(List<Pedido> novos)? aoChegarPedidos;

  List<Pedido> _pedidos = const [];
  bool _carregouUmaVez = false;
  bool _buscando = false;
  String? _erro;
  DateTime? _atualizadoEm;
  final Set<int> _alterando = {};
  Timer? _timer;
  bool _descartado = false;

  /// Incrementado a cada alteração de status; descarta respostas de
  /// atualização que começaram antes dela (evita "voltar" o status na tela).
  int _versao = 0;

  /// Incrementado ao pausar; a requisição que ficou congelada em segundo plano
  /// é ignorada (resultado e erro) e não bloqueia as próximas.
  int _geracao = 0;

  bool get carregouUmaVez => _carregouUmaVez;
  String? get erro => _erro;
  DateTime? get atualizadoEm => _atualizadoEm;
  bool alterando(int pedidoId) => _alterando.contains(pedidoId);

  /// Fila da cozinha: o mais antigo primeiro.
  List<Pedido> get novos => _filtrar({StatusPedido.aberto}, maisAntigoPrimeiro: true);
  List<Pedido> get emPreparo => _filtrar({StatusPedido.preparando}, maisAntigoPrimeiro: true);

  /// Histórico: o mais recente primeiro.
  List<Pedido> get finalizados => _filtrar({StatusPedido.concluido, StatusPedido.cancelado}, maisAntigoPrimeiro: false);

  List<Pedido> _filtrar(Set<StatusPedido> status, {required bool maisAntigoPrimeiro}) {
    final lista = _pedidos.where((p) => status.contains(p.status)).toList();
    lista.sort((a, b) => maisAntigoPrimeiro ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
    return lista;
  }

  void iniciar() {
    atualizar();
    _timer ??= Timer.periodic(intervalo, (_) => atualizar());
  }

  /// App saiu da tela: para de consultar a API. O Android congela o processo
  /// em segundo plano, e uma requisição em andamento voltaria como timeout falso.
  void pausar() {
    _timer?.cancel();
    _timer = null;
    _geracao++;
    _buscando = false;
  }

  /// App voltou para a tela: atualiza na hora e retoma o ciclo.
  void retomar() {
    if (_timer == null && !_descartado) iniciar();
  }

  Future<void> atualizar() async {
    if (_buscando || _descartado) return;
    _buscando = true;
    final versaoInicial = _versao;
    final geracao = _geracao;
    try {
      final lista = await _api.listarPedidosCozinha();
      if (_descartado || geracao != _geracao || versaoInicial != _versao) return;

      if (_carregouUmaVez) {
        final idsAnteriores = {for (final p in _pedidos) p.id};
        final chegaram = lista.where((p) => !idsAnteriores.contains(p.id)).toList();
        if (chegaram.isNotEmpty) aoChegarPedidos?.call(chegaram);
      }

      _pedidos = lista;
      _erro = null;
      _carregouUmaVez = true;
      _atualizadoEm = DateTime.now();
    } on ApiException catch (e) {
      if (_descartado || geracao != _geracao) return;
      _erro = e.mensagem;
    } finally {
      if (geracao == _geracao) _buscando = false;
      if (!_descartado) notifyListeners();
    }
  }

  /// Retorna `null` em caso de sucesso, ou a mensagem de erro para exibir.
  Future<String?> alterarStatus(Pedido pedido, StatusPedido destino) async {
    if (!_alterando.add(pedido.id)) return null;
    _versao++;
    notifyListeners();
    try {
      final atualizado = await _api.alterarStatus(pedido.id, destino);
      _pedidos = [for (final p in _pedidos) p.id == atualizado.id ? atualizado : p];
      return null;
    } on ApiException catch (e) {
      // Se outro aparelho já mudou o pedido, a lista recarregada mostra o estado real.
      if (e.conflito || e.naoEncontrado) unawaited(atualizar());
      return e.mensagem;
    } finally {
      _alterando.remove(pedido.id);
      _versao++;
      if (!_descartado) notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _timer?.cancel();
    super.dispose();
  }
}
