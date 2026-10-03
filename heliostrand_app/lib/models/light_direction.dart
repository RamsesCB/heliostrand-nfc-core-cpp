/// Dirección lumínica predominante basada en los sensores LDR.
enum LightDirection {
  norte,
  sur,
  este,
  oeste,
  equilibrado;

  String get displayName {
    switch (this) {
      case LightDirection.norte:
        return 'NORTE';
      case LightDirection.sur:
        return 'SUR';
      case LightDirection.este:
        return 'ESTE';
      case LightDirection.oeste:
        return 'OESTE';
      case LightDirection.equilibrado:
        return 'EQUILIBRADO';
    }
  }
}
