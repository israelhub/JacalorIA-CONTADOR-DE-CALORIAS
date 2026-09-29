import 'package:flutter/foundation.dart';

/// Sinaliza que ranking/grupos sociais precisam ser recarregados
/// (ex.: após salvar refeição ou virada de dia).
class SocialDataInvalidator {
  SocialDataInvalidator._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void markDirty() {
    revision.value++;
  }
}
