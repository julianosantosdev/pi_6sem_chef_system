import 'dart:async';

import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

/// Pedidos da mesa, recarregados a cada [intervalo] para acompanhar o preparo.
///
/// A cozinha muda o status pela API; como a API não envia eventos para o app,
/// o app consulta `GET /pedidos?mesaId=` periodicamente.
class PedidosMesaController extends ChangeNotifier {
  PedidosMesaController(this._api, this.mesa, {this.intervalo = const Duration(seconds: 5), this.aoMudarStatus});

  final ChefApi _api;
  final Mesa mesa;
  final Duration intervalo;

  /// Chamado quando um pedido já conhecido muda de status.
  final void Function(Pedido pedido)? aoMudarStatus;

  List<Pedido> _pedidos = const [];
  bool _carregouUmaVez = false;
  bool _buscando = false;
  String? _erro;
  Timer? _timer;
  bool _descartado = false;

  /// Incrementado ao pausar; a requisição que ficou congelada em segundo plano
  /// é ignorada (resultado e erro) e não bloqueia as próximas.
  int _geracao = 0;

  /// Pedidos do mais recente para o mais antigo (ordem da API).
  List<Pedido> get pedidos => _pedidos;
  List<Pedido> get emAndamento => _pedidos.where((p) => !p.status.finalizado).toList();
  bool get carregouUmaVez => _carregouUmaVez;
  String? get erro => _erro;

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
    final geracao = _geracao;
    try {
      final lista = await _api.listarPedidos(mesaId: mesa.id);
      if (_descartado || geracao != _geracao) return;
      if (_carregouUmaVez) {
        final anteriores = {for (final p in _pedidos) p.id: p.status};
        for (final p in lista) {
          final antes = anteriores[p.id];
          if (antes != null && antes != p.status) aoMudarStatus?.call(p);
        }
      }
      _pedidos = lista;
      _erro = null;
      _carregouUmaVez = true;
    } on ApiException catch (e) {
      if (_descartado || geracao != _geracao) return;
      _erro = e.mensagem;
    } finally {
      if (geracao == _geracao) _buscando = false;
      if (!_descartado) notifyListeners();
    }
  }

  /// Mostra o pedido recém-criado sem esperar a próxima atualização.
  void adicionar(Pedido pedido) {
    _pedidos = [pedido, ..._pedidos.where((p) => p.id != pedido.id)];
    notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _timer?.cancel();
    super.dispose();
  }
}
