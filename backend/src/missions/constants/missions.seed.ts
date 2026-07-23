import { MissionAccent, MissionType } from '../models/mission.model';

/**
 * Economia de missões (ouro + XP).
 *
 * Princípios de retenção:
 * - Loop diário barato e frequente (dopamina de hábito).
 * - Semanais com prêmio maior (compromisso de 7 dias).
 * - Mensais como clímax de esforço (goal gradient).
 * - Recompensa escala com dificuldade real da missão.
 * - XP = 2× ouro (progressão social/status sem sink).
 *
 * Rendimento aproximado (jogador engajado ~40 ouro/dia de diárias):
 * - Diárias perfeitas: 40 ouro / 80 XP por dia
 * - Semanais perfeitas: 270 ouro / 540 XP por semana
 * - Mensais perfeitos: 750 ouro / 1500 XP por mês
 * - Mês “perfeito”: ~3030 ouro (diárias + ~4 semanas + mensais)
 */
export type MissionSeedItem = {
  key: string;
  type: MissionType;
  title: string;
  description: string;
  targetValue: number;
  rewardGold: number;
  rewardXp: number;
  sortOrder: number;
  accent: MissionAccent;
};

export const DEFAULT_MISSIONS: MissionSeedItem[] = [
  {
    key: 'daily_three_meals',
    type: 'daily',
    title: 'Refeições completas',
    description: 'Café, almoço e jantar',
    targetValue: 3,
    rewardGold: 15,
    rewardXp: 30,
    sortOrder: 1,
    accent: 'action',
  },
  {
    key: 'daily_protein_goal',
    type: 'daily',
    title: 'Atinja sua meta de proteínas',
    description: 'Consuma sua meta diária de proteína',
    targetValue: 1,
    rewardGold: 25,
    rewardXp: 50,
    sortOrder: 2,
    accent: 'action',
  },
  {
    key: 'weekly_variety_15_foods',
    type: 'weekly',
    title: 'Variedade alimentar',
    description: 'Registre 15 alimentos diferentes',
    targetValue: 15,
    rewardGold: 70,
    rewardXp: 140,
    sortOrder: 1,
    accent: 'accent',
  },
  {
    key: 'weekly_goal_4_times',
    type: 'weekly',
    title: 'Bata a meta 4 vezes',
    description: 'Atinja sua meta calórica em 4 dias da semana',
    targetValue: 4,
    rewardGold: 90,
    rewardXp: 180,
    sortOrder: 2,
    accent: 'accent',
  },
  {
    key: 'weekly_streak_5_days',
    type: 'weekly',
    title: 'Sequência de 5 dias',
    description: 'Registre refeições por 5 dias seguidos',
    targetValue: 5,
    rewardGold: 110,
    rewardXp: 220,
    sortOrder: 3,
    accent: 'accent',
  },
  {
    key: 'monthly_objective_focus',
    type: 'monthly',
    title: 'Foco no objetivo',
    description: 'Registre refeições em 20 dias no mês',
    targetValue: 20,
    rewardGold: 180,
    rewardXp: 360,
    sortOrder: 1,
    accent: 'challenge',
  },
  {
    key: 'monthly_master_consistency',
    type: 'monthly',
    title: 'Mestre da consistência',
    description: 'Bata sua meta diária em 20 dias',
    targetValue: 20,
    rewardGold: 250,
    rewardXp: 500,
    sortOrder: 2,
    accent: 'challenge',
  },
  {
    key: 'monthly_macro_hunter',
    type: 'monthly',
    title: 'Caçador de macros',
    description: 'Atinja todas as metas de macros em 10 dias',
    targetValue: 10,
    rewardGold: 320,
    rewardXp: 640,
    sortOrder: 3,
    accent: 'challenge',
  },
];
