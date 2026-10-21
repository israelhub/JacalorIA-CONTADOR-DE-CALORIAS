import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/auth/service/auth_service.dart';
import 'package:jacaloria/features/home/helpers/home_shell_product_tour_prefs.dart';
import 'package:jacaloria/features/home/helpers/home_shell_product_tour_steps.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AuthService.globalUser = null;
  });

  tearDown(() {
    AuthService.globalUser = null;
  });

  test('sem usuario logado nao dispara tour', () {
    AuthService.globalUser = null;
    expect(HomeShellProductTourPrefs.shouldShow(), isFalse);
  });

  test('usuario sem flag no perfil deve ver o tour', () {
    AuthService.globalUser = <String, dynamic>{'id': 'user-1'};
    expect(HomeShellProductTourPrefs.shouldShow(), isTrue);
    expect(HomeShellProductTourPrefs.isCompleted(), isFalse);
  });

  test('usuario com homeProductTourCompleted true nao ve o tour', () {
    AuthService.globalUser = <String, dynamic>{
      'id': 'user-1',
      'homeProductTourCompleted': true,
    };
    expect(HomeShellProductTourPrefs.shouldShow(), isFalse);
    expect(HomeShellProductTourPrefs.isCompleted(), isTrue);
  });

  test('aceita snake_case do backend', () {
    expect(
      HomeShellProductTourPrefs.isCompleted(<String, dynamic>{
        'home_product_tour_completed': true,
      }),
      isTrue,
    );
  });

  test('salva e retoma o passo pelo id', () async {
    AuthService.globalUser = <String, dynamic>{'id': 'user-1'};
    final prefs = HomeShellProductTourPrefs();

    await prefs.saveProgress(HomeShellProductTourStepId.meals);
    final index = await prefs.resolveResumeIndex(homeShellProductTourSteps);

    expect(
      index,
      homeShellProductTourSteps.indexWhere(
        (step) => step.id == HomeShellProductTourStepId.meals,
      ),
    );
  });

  test('limpa progresso ao concluir', () async {
    AuthService.globalUser = <String, dynamic>{'id': 'user-1'};
    final prefs = HomeShellProductTourPrefs();
    await prefs.saveProgress(HomeShellProductTourStepId.store);
    await prefs.clearProgress();

    expect(await prefs.resolveResumeIndex(homeShellProductTourSteps), 0);
  });
}
