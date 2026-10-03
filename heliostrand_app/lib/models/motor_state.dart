/// Estado de marcha/tracción del sistema mecánico Theo Jansen.
enum MotorState {
  adelante,
  atras,
  detenido;

  String get displayName {
    switch (this) {
      case MotorState.adelante:
        return 'ADELANTE';
      case MotorState.atras:
        return 'ATRAS';
      case MotorState.detenido:
        return 'DETENIDO';
    }
  }
}
