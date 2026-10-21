import '../../../shared/widgets/app_main_bottom_navigation.dart';

enum HomeShellProductTourStepId {
  home,
  dailyGoal,
  meals,
  more,
  missions,
  store,
  social,
  socialTabs,
  performance,
}

enum HomeShellProductTourTooltipPlacement { above, below, auto }

class HomeShellProductTourStep {
  const HomeShellProductTourStep({
    required this.id,
    required this.title,
    required this.description,
    this.tab,
    this.openMoreMenu = false,
    this.allowHighlightTap = false,
    this.nextLabel,
    this.waitForTarget = false,
    this.tooltipPlacement = HomeShellProductTourTooltipPlacement.auto,
  });

  final HomeShellProductTourStepId id;
  final String title;
  final String description;
  final AppMainBottomTab? tab;
  final bool openMoreMenu;
  final bool allowHighlightTap;
  final String? nextLabel;
  final bool waitForTarget;
  final HomeShellProductTourTooltipPlacement tooltipPlacement;
}

const List<HomeShellProductTourStep> homeShellProductTourSteps =
    <HomeShellProductTourStep>[
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.home,
        title: 'Início',
        description:
            'Aqui você acompanha refeições, água, passos e o progresso do dia.',
        tab: AppMainBottomTab.home,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.above,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.dailyGoal,
        title: 'Meta diária',
        description:
            'Este card é o resumo da sua meta diária de calorias: quanto você já consumiu, o quanto ainda cabe no dia e o seu objetivo. Ele se atualiza quando você registra refeições.',
        tab: AppMainBottomTab.home,
        waitForTarget: true,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.below,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.meals,
        title: 'Refeições',
        description:
            'Aqui ficam as refeições do dia. Use o botão Adicionar refeição ou o botão central da barra de navegação para adicionar uma nova refeição.',
        tab: AppMainBottomTab.home,
        waitForTarget: true,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.below,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.more,
        title: 'Mais',
        description:
            'Aqui ficam Missões, Treino, Perfil e outras funções existentes no app. Toque em Missões para continuar.',
        openMoreMenu: true,
        allowHighlightTap: true,
        nextLabel: 'Abrir Missões',
        tooltipPlacement: HomeShellProductTourTooltipPlacement.above,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.missions,
        title: 'Missões',
        description:
            'Esta é a página de missões. Em destaque estão as missões do dia, mas também existem semanais, mensais, de fim de semana e eventos especiais. Complete elas para ganhar ouro e XP.',
        tab: AppMainBottomTab.missions,
        waitForTarget: true,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.below,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.store,
        title: 'Loja',
        description:
            'Troque o ouro das missões por molduras, fundos e outras recompensas acessando a loja.',
        tab: AppMainBottomTab.missions,
        waitForTarget: true,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.below,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.social,
        title: 'Social',
        description:
            'Acesse o Social através do botão em destaque para ver seus amigos, grupos e ranking, assim mantendo a consistência juntos!',
        tab: AppMainBottomTab.social,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.above,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.socialTabs,
        title: 'Abas do Social',
        description:
            'Navegue entre Amigos, onde você pode adicionar e ver o perfil deles; Grupos, onde você acompanha seus desafios em equipe; e Ranking, uma lista de quem tem mais XP entre todos os usuários do app.',
        tab: AppMainBottomTab.social,
        waitForTarget: true,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.below,
      ),
      HomeShellProductTourStep(
        id: HomeShellProductTourStepId.performance,
        title: 'Progresso',
        description: 'Acompanhe sua evolução ao longo dos dias e semanas.',
        tab: AppMainBottomTab.performance,
        tooltipPlacement: HomeShellProductTourTooltipPlacement.above,
      ),
    ];
