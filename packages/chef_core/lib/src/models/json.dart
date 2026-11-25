/// Funções auxiliares para ler o JSON da API.
library;

/// A API envia valores monetários como BigDecimal (número JSON).
/// Guardamos em centavos para não acumular erro de ponto flutuante.
int lerCentavos(Object? valor) {
  if (valor == null) return 0;
  if (valor is num) return (valor * 100).round();
  return (num.parse(valor.toString()) * 100).round();
}

/// `Instant` do Java chega como texto ISO-8601 (ex.: 2026-11-25T12:30:00Z).
/// Se a API for configurada para timestamps numéricos, aceita segundos epoch.
DateTime? lerData(Object? valor) {
  if (valor == null) return null;
  if (valor is num) {
    return DateTime.fromMicrosecondsSinceEpoch((valor * 1000000).round(), isUtc: true).toLocal();
  }
  return DateTime.parse(valor.toString()).toLocal();
}

/// Formata centavos como "R$ 12,50".
String formatarCentavos(int centavos) {
  final sinal = centavos < 0 ? '-' : '';
  final abs = centavos.abs();
  final reais = (abs ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '${sinal}R\$ $reais,$cents';
}
