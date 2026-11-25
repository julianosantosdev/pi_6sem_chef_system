/// Espelha `MesaResponseDTO`.
class Mesa {
  const Mesa({required this.id, required this.numero, required this.quantidade});

  factory Mesa.fromJson(Map<String, dynamic> json) => Mesa(
        id: json['id'] as int,
        numero: json['numero'] as int,
        quantidade: json['quantidade'] as int,
      );

  final int id;
  final int numero;

  /// Quantidade de lugares da mesa.
  final int quantidade;
}
