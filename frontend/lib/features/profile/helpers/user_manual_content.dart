import 'package:flutter/material.dart';

enum UserManualTopicId {
  home,
  missions,
  store,
  social,
  performance,
  workout,
  profile,
  reminders,
  notifications,
  support,
}

enum UserManualGuidedTourId {
  initial,
  workout,
  profile,
  reminders,
  notifications,
  hydration,
}

class UserManualSection {
  const UserManualSection({required this.title, required this.body});

  final String title;
  final String body;
}

class UserManualTopic {
  const UserManualTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
    this.coveredInInitialTour = false,
  });

  final UserManualTopicId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<UserManualSection> sections;
  final bool coveredInInitialTour;
}

class UserManualGuidedTourEntry {
  const UserManualGuidedTourEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final UserManualGuidedTourId id;
  final String title;
  final String subtitle;
  final IconData icon;
}

const List<UserManualGuidedTourEntry> userManualGuidedTours =
    <UserManualGuidedTourEntry>[
      UserManualGuidedTourEntry(
        id: UserManualGuidedTourId.initial,
        title: 'Tour inicial',
        subtitle: 'O mapa rápido do app, do Início ao Progresso',
        icon: Icons.tour_rounded,
      ),
      UserManualGuidedTourEntry(
        id: UserManualGuidedTourId.workout,
        title: 'Treino',
        subtitle: 'Monte rotinas e registre suas cargas',
        icon: Icons.fitness_center_rounded,
      ),
      UserManualGuidedTourEntry(
        id: UserManualGuidedTourId.profile,
        title: 'Perfil',
        subtitle: 'Foto, visual e dados da conta',
        icon: Icons.person_rounded,
      ),
      UserManualGuidedTourEntry(
        id: UserManualGuidedTourId.reminders,
        title: 'Lembretes',
        subtitle: 'Receba um toque na hora da refeição',
        icon: Icons.alarm_rounded,
      ),
      UserManualGuidedTourEntry(
        id: UserManualGuidedTourId.notifications,
        title: 'Notificações',
        subtitle: 'Onde ficam os avisos do JacalorIA',
        icon: Icons.notifications_rounded,
      ),
      UserManualGuidedTourEntry(
        id: UserManualGuidedTourId.hydration,
        title: 'Água, passos e peso',
        subtitle: 'Os atalhos do dia no Início',
        icon: Icons.water_drop_rounded,
      ),
    ];

const List<UserManualTopic> userManualTopics = <UserManualTopic>[
  UserManualTopic(
    id: UserManualTopicId.home,
    title: 'Início',
    subtitle: 'Meta, refeições, água, passos e peso',
    icon: Icons.home_rounded,
    coveredInInitialTour: true,
    sections: [
      UserManualSection(
        title: 'O que é esta página',
        body:
            'O Início é o centro do seu dia no JacalorIA. Ali você vê a meta de calorias, as refeições registradas, água, passos e atalhos rápidos para manter o ritmo.',
      ),
      UserManualSection(
        title: 'Meta diária',
        body:
            'O card de meta mostra quanto você já consumiu, quanto ainda cabe no dia e o objetivo escolhido no perfil. Ele atualiza quando você confirma uma refeição.',
      ),
      UserManualSection(
        title: 'Como registrar comida',
        body:
            'Use o botão Adicionar refeição na seção de refeições ou o botão central da barra inferior. Dá para fotografar o prato, buscar alimentos ou montar a refeição manualmente.',
      ),
      UserManualSection(
        title: 'Água',
        body:
            'No Início, o atalho de água abre uma folha para somar o que você bebeu. Vá registrando ao longo do dia para a meta de hidratação acompanhar a realidade.',
      ),
      UserManualSection(
        title: 'Passos',
        body:
            'Os passos vêm da integração com o Health Connect / sensores do aparelho quando disponíveis. A Home mostra o total do dia para cruzar com o gasto e a rotina.',
      ),
      UserManualSection(
        title: 'Peso',
        body:
            'Atualize o peso pelo atalho rápido na Home quando a balança mudar. Isso refina metas e o histórico sem precisar abrir o editor completo toda vez.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.missions,
    title: 'Missões',
    subtitle: 'Desafios diários, ouro e XP',
    icon: Icons.flag_rounded,
    coveredInInitialTour: true,
    sections: [
      UserManualSection(
        title: 'Como chegar',
        body:
            'Abra Mais na barra inferior e toque em Missões. Lá ficam missões do dia, semanais, mensais, de fim de semana e eventos especiais.',
      ),
      UserManualSection(
        title: 'Recompensas',
        body:
            'Completar missões rende ouro e XP. Use o ouro na Loja para comprar molduras, fundos e emojis.',
      ),
      UserManualSection(
        title: 'Dica',
        body:
            'Priorize as missões do dia: elas resetam com frequência e ajudam a manter a sequência de uso do app.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.store,
    title: 'Loja',
    subtitle: 'Molduras, fundos e emojis',
    icon: Icons.storefront_rounded,
    coveredInInitialTour: true,
    sections: [
      UserManualSection(
        title: 'Como chegar',
        body:
            'Abra a Loja pelo botão na página de Missões ou pelo menu Mais. Lá você gasta o ouro das missões.',
      ),
      UserManualSection(
        title: 'O que comprar',
        body:
            'Há molduras e fundos para o avatar, emojis de reação e bloqueadores. Itens exclusivos do tutorial ou de check-in ficam sinalizados.',
      ),
      UserManualSection(
        title: 'Equipar',
        body:
            'Toque em um item que você já possui para equipar. Emoticons desbloqueados também podem ser adicionados como reação no preview do perfil.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.social,
    title: 'Social',
    subtitle: 'Amigos, grupos e ranking',
    icon: Icons.groups_rounded,
    coveredInInitialTour: true,
    sections: [
      UserManualSection(
        title: 'Abas',
        body:
            'Em Social você navega entre Amigos, Grupos e Ranking. Em Amigos dá para buscar pessoas e ver o perfil público. Em Grupos você cria ou entra em desafios em equipe. No Ranking aparece quem tem mais XP no app.',
      ),
      UserManualSection(
        title: 'Consistência em grupo',
        body:
            'Grupos e desafios ajudam a manter o hábito: combine metas, acompanhe o chat do grupo e celebre as conquistas juntos.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.performance,
    title: 'Progresso',
    subtitle: 'Evolução ao longo dos dias',
    icon: Icons.insights_rounded,
    coveredInInitialTour: true,
    sections: [
      UserManualSection(
        title: 'Para que serve',
        body:
            'A aba Progresso resume sua evolução: calorias, macros e tendências ao longo dos dias e semanas, para você enxergar o que está funcionando.',
      ),
      UserManualSection(
        title: 'Como usar bem',
        body:
            'Olhe tendências, não só um dia isolado. Se a média de calorias ou proteína estiver fora da meta, ajuste as refeições no Início e volte ao Progresso depois de alguns dias.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.workout,
    title: 'Treino',
    subtitle: 'Rotinas, exercícios e cargas',
    icon: Icons.fitness_center_rounded,
    sections: [
      UserManualSection(
        title: 'O que é esta página',
        body:
            'Em Treino você organiza fichas, monta exercícios e registra cargas. Todo mundo já começa com a ficha Treino A pronta para preencher.',
      ),
      UserManualSection(
        title: 'Fichas',
        body:
            'Use a ficha Treino A ou crie outras (Treino B, Empurrar, Inferiores). Adicione exercícios com séries e repetições. O peso de cada exercício você anota na Home.',
      ),
      UserManualSection(
        title: 'Cargas e histórico',
        body:
            'Ao treinar, registre a carga usada. Com o tempo você vê se está progredindo e pode ajustar o volume sem perder o histórico.',
      ),
      UserManualSection(
        title: 'Importação',
        body:
            'Se já tiver uma planilha ou lista pronta, use a importação de treino para acelerar a montagem da rotina.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.profile,
    title: 'Perfil',
    subtitle: 'Dados, visual e privacidade',
    icon: Icons.person_rounded,
    sections: [
      UserManualSection(
        title: 'Visão geral',
        body:
            'O Perfil mostra quem você é no app: avatar, moldura, fundo, dados pessoais, conquistas e atalhos para editar ou personalizar.',
      ),
      UserManualSection(
        title: 'Editar dados',
        body:
            'Em Editar dados pessoais você ajusta peso, altura, objetivo, nível de atividade e preferências de privacidade do perfil público. O formulário começa em modo leitura: toque em Editar para liberar os campos.',
      ),
      UserManualSection(
        title: 'Personalização',
        body:
            'Molduras, fundos e bloqueadores vêm da Loja. Equipe o visual no Perfil ou na loja e veja o resultado no banner. O Manual do usuário fica acima do botão Sair.',
      ),
      UserManualSection(
        title: 'Privacidade e LGPD',
        body:
            'Nas edições de dados você encontra Termos, Política de Privacidade, exportação e exclusão de conta. Também dá para ocultar refeições ou treinos do perfil público.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.reminders,
    title: 'Lembretes',
    subtitle: 'Avisos de refeição no horário',
    icon: Icons.alarm_rounded,
    sections: [
      UserManualSection(
        title: 'Para que serve',
        body:
            'Lembretes ajudam a não esquecer de registrar (ou fazer) refeições em horários fixos. Útil se você pula café da manhã ou jantar com frequência.',
      ),
      UserManualSection(
        title: 'Como configurar',
        body:
            'Crie um lembrete com nome e horário. Ative as notificações do app no sistema do celular para o aviso chegar na hora certa.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.notifications,
    title: 'Notificações',
    subtitle: 'Avisos e mensagens do app',
    icon: Icons.notifications_rounded,
    sections: [
      UserManualSection(
        title: 'Central de avisos',
        body:
            'A página de Notificações reúne mensagens do JacalorIA: lembretes, novidades e avisos importantes da sua conta.',
      ),
      UserManualSection(
        title: 'Boas práticas',
        body:
            'Abra a lista com frequência no começo. Depois que a rotina estiver clara, use os lembretes e missões como âncora principal.',
      ),
    ],
  ),
  UserManualTopic(
    id: UserManualTopicId.support,
    title: 'Suporte',
    subtitle: 'Fale com a gente',
    icon: Icons.support_agent_rounded,
    sections: [
      UserManualSection(
        title: 'Quando usar',
        body:
            'Use o Suporte para bugs, dúvidas de conta, privacidade ou sugestões. Descreva o problema com pelo menos algumas frases para agilizar a resposta.',
      ),
      UserManualSection(
        title: 'Como enviar',
        body:
            'Em Mais, abra Suporte, escolha o assunto e envie a mensagem. Se estiver deslogado, informe um e-mail válido para retorno.',
      ),
    ],
  ),
];

UserManualTopic? userManualTopicById(UserManualTopicId id) {
  for (final topic in userManualTopics) {
    if (topic.id == id) {
      return topic;
    }
  }
  return null;
}
