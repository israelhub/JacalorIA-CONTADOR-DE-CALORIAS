import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_main_bottom_navigation.dart';
import 'user_manual_content.dart';

enum ManualGuidedTourStepKind {
  tab,
  openMore,
  openOverlay,
  highlightOnly,
}

enum ManualGuidedTourOverlay {
  profile,
  reminders,
  notifications,
  support,
}

class ManualGuidedTourStep {
  const ManualGuidedTourStep({
    required this.title,
    required this.description,
    this.kind = ManualGuidedTourStepKind.highlightOnly,
    this.tab,
    this.overlay,
    this.targetIds = const <String>[],
    this.allowHighlightTap = false,
    this.nextLabel,
    this.waitForTarget = false,
    this.tooltipAbove = false,
    this.highlightInflate = 0,
    this.highlightRadius = AppRadius.lg,
    this.scrollAlignment = 0.18,
  });

  final String title;
  final String description;
  final ManualGuidedTourStepKind kind;
  final AppMainBottomTab? tab;
  final ManualGuidedTourOverlay? overlay;
  final List<String> targetIds;
  final bool allowHighlightTap;
  final String? nextLabel;
  final bool waitForTarget;
  final bool tooltipAbove;
  final double highlightInflate;
  final double highlightRadius;
  final double scrollAlignment;
}

class ManualGuidedTourTargetIds {
  ManualGuidedTourTargetIds._();

  static const workoutDestination = 'workout_destination';
  static const profileDestination = 'profile_destination';
  static const remindersDestination = 'reminders_destination';
  static const notificationsDestination = 'notifications_destination';
  static const workoutPlanCard = 'workout_plan_card';
  static const workoutImportButton = 'workout_import_button';
  static const workoutAddExercise = 'workout_add_exercise';
  static const profileBanner = 'profile_banner';
  static const profileManual = 'profile_manual';
  static const remindersList = 'reminders_list';
  static const notificationsList = 'notifications_list';
  static const waterCard = 'water_card';
  static const stepsCard = 'steps_card';
  static const weightCard = 'weight_card';
}

const Map<UserManualGuidedTourId, List<ManualGuidedTourStep>>
manualGuidedTourStepsById = <UserManualGuidedTourId, List<ManualGuidedTourStep>>{
  UserManualGuidedTourId.workout: <ManualGuidedTourStep>[
    ManualGuidedTourStep(
      title: 'Treino',
      description: 'Abra Treino no menu Mais. Você já começa com a ficha Treino A.',
      kind: ManualGuidedTourStepKind.openMore,
      tab: AppMainBottomTab.workout,
      targetIds: [ManualGuidedTourTargetIds.workoutDestination],
      allowHighlightTap: true,
      nextLabel: 'Abrir Treino',
      tooltipAbove: true,
      highlightInflate: 4,
      highlightRadius: AppRadius.md,
    ),
    ManualGuidedTourStep(
      title: 'Treino A',
      description:
          'Esta é a sua ficha. Troque entre fichas por aqui ou abra a pasta para criar outras.',
      kind: ManualGuidedTourStepKind.tab,
      tab: AppMainBottomTab.workout,
      targetIds: [ManualGuidedTourTargetIds.workoutPlanCard],
      waitForTarget: true,
      highlightInflate: 0,
      highlightRadius: AppRadius.lg,
      scrollAlignment: 0.12,
    ),
    ManualGuidedTourStep(
      title: 'Exercícios',
      description:
          'Toque em Adicionar exercício para montar a ficha. O peso de cada um você anota na Home.',
      kind: ManualGuidedTourStepKind.tab,
      tab: AppMainBottomTab.workout,
      targetIds: [ManualGuidedTourTargetIds.workoutAddExercise],
      waitForTarget: true,
      highlightInflate: 4,
      highlightRadius: AppRadius.lg,
      scrollAlignment: 0.35,
    ),
    ManualGuidedTourStep(
      title: 'Trazer com IA',
      description:
          'Já tem tudo no bloco de notas? Este botão importa e monta as fichas pra você.',
      kind: ManualGuidedTourStepKind.tab,
      tab: AppMainBottomTab.workout,
      targetIds: [ManualGuidedTourTargetIds.workoutImportButton],
      waitForTarget: true,
      highlightInflate: 6,
      highlightRadius: AppRadius.pill,
      scrollAlignment: 0.05,
      tooltipAbove: false,
    ),
  ],
  UserManualGuidedTourId.profile: <ManualGuidedTourStep>[
    ManualGuidedTourStep(
      title: 'Perfil',
      description: 'Abra Perfil no menu Mais para ver seu visual e dados.',
      kind: ManualGuidedTourStepKind.openMore,
      overlay: ManualGuidedTourOverlay.profile,
      targetIds: [ManualGuidedTourTargetIds.profileDestination],
      allowHighlightTap: true,
      nextLabel: 'Abrir Perfil',
      tooltipAbove: true,
      highlightInflate: 4,
      highlightRadius: AppRadius.md,
    ),
    ManualGuidedTourStep(
      title: 'Seu banner',
      description:
          'Foto, moldura e fundo. O emoji de reação fica no canto, se quiser trocar.',
      kind: ManualGuidedTourStepKind.openOverlay,
      overlay: ManualGuidedTourOverlay.profile,
      targetIds: [ManualGuidedTourTargetIds.profileBanner],
      waitForTarget: true,
      highlightInflate: 0,
      highlightRadius: AppRadius.md,
      scrollAlignment: 0.0,
    ),
    ManualGuidedTourStep(
      title: 'Manual do usuário',
      description:
          'Este botão abre tours e guias. Fica logo acima de Sair.',
      kind: ManualGuidedTourStepKind.openOverlay,
      overlay: ManualGuidedTourOverlay.profile,
      targetIds: [ManualGuidedTourTargetIds.profileManual],
      waitForTarget: true,
      highlightInflate: 4,
      highlightRadius: AppRadius.md,
      scrollAlignment: 0.85,
      tooltipAbove: true,
    ),
  ],
  UserManualGuidedTourId.reminders: <ManualGuidedTourStep>[
    ManualGuidedTourStep(
      title: 'Lembretes',
      description: 'Abra Lembretes de refeição no menu Mais.',
      kind: ManualGuidedTourStepKind.openMore,
      overlay: ManualGuidedTourOverlay.reminders,
      targetIds: [ManualGuidedTourTargetIds.remindersDestination],
      allowHighlightTap: true,
      nextLabel: 'Abrir Lembretes',
      tooltipAbove: true,
      highlightInflate: 4,
      highlightRadius: AppRadius.md,
    ),
    ManualGuidedTourStep(
      title: 'Seus lembretes',
      description:
          'Nesta lista você cria, edita, liga e desliga cada aviso de refeição.',
      kind: ManualGuidedTourStepKind.openOverlay,
      overlay: ManualGuidedTourOverlay.reminders,
      targetIds: [ManualGuidedTourTargetIds.remindersList],
      waitForTarget: true,
      highlightInflate: 0,
      highlightRadius: AppRadius.lg,
      scrollAlignment: 0.2,
    ),
  ],
  UserManualGuidedTourId.notifications: <ManualGuidedTourStep>[
    ManualGuidedTourStep(
      title: 'Notificações',
      description: 'Abra Notificações no menu Mais para ver os avisos.',
      kind: ManualGuidedTourStepKind.openMore,
      overlay: ManualGuidedTourOverlay.notifications,
      targetIds: [ManualGuidedTourTargetIds.notificationsDestination],
      allowHighlightTap: true,
      nextLabel: 'Abrir Notificações',
      tooltipAbove: true,
      highlightInflate: 4,
      highlightRadius: AppRadius.md,
    ),
    ManualGuidedTourStep(
      title: 'Avisos do app',
      description:
          'Cada card é uma mensagem. Toque para ler o detalhe.',
      kind: ManualGuidedTourStepKind.openOverlay,
      overlay: ManualGuidedTourOverlay.notifications,
      targetIds: [ManualGuidedTourTargetIds.notificationsList],
      waitForTarget: true,
      highlightInflate: 0,
      highlightRadius: AppRadius.lg,
      scrollAlignment: 0.15,
    ),
  ],
  UserManualGuidedTourId.hydration: <ManualGuidedTourStep>[
    ManualGuidedTourStep(
      title: 'Água',
      description: 'Neste card do Início você registra o que bebeu no dia.',
      kind: ManualGuidedTourStepKind.tab,
      tab: AppMainBottomTab.home,
      targetIds: [ManualGuidedTourTargetIds.waterCard],
      waitForTarget: true,
      highlightInflate: 0,
      highlightRadius: AppRadius.lg,
      scrollAlignment: 0.25,
      tooltipAbove: true,
    ),
    ManualGuidedTourStep(
      title: 'Passos',
      description:
          'Aqui entram os passos do dia, quando a saúde do celular estiver ligada.',
      kind: ManualGuidedTourStepKind.tab,
      tab: AppMainBottomTab.home,
      targetIds: [ManualGuidedTourTargetIds.stepsCard],
      waitForTarget: true,
      highlightInflate: 0,
      highlightRadius: AppRadius.lg,
      scrollAlignment: 0.35,
      tooltipAbove: true,
    ),
    ManualGuidedTourStep(
      title: 'Peso',
      description: 'Atualize o peso neste atalho, sem abrir o Perfil.',
      kind: ManualGuidedTourStepKind.tab,
      tab: AppMainBottomTab.home,
      targetIds: [ManualGuidedTourTargetIds.weightCard],
      waitForTarget: true,
      highlightInflate: 0,
      highlightRadius: AppRadius.lg,
      scrollAlignment: 0.35,
      tooltipAbove: true,
    ),
  ],
};
