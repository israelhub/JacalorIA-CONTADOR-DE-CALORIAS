import { MissionAccent, MissionType } from '../models/mission.model';

/**
 * Economia de missões (ouro + XP).
 *
 * Princípios de retenção:
 * - Loop diário barato e frequente (dopamina de hábito).
 * - Semanais com prêmio maior (compromisso de 7 dias).
 * - Mensais como clímax de esforço (goal gradient).
 * - Fim de semana: evento sexta–domingo com prêmio alto (combate queda de acesso).
 * - Recompensa escala com dificuldade real da missão.
 * - XP = 2× ouro (progressão social/status sem sink).
 *
 * Rendimento aproximado (jogador engajado ~40 ouro/dia de diárias):
 * - Diárias perfeitas: 40 ouro / 80 XP por dia
 * - Evento de fim de semana: 120 ouro / 240 XP (meta em sex + sáb + dom)
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

export const WEEKEND_GOAL_MISSION_KEY = 'weekend_goal_trio';
export const WEEKLY_UPDATE_WEIGHT_MISSION_KEY = 'weekly_update_weight';

export const DEFAULT_MISSIONS: MissionSeedItem[] = [
  {
    key: 'daily_three_meals',
    type: 'daily',
    title: 'Registre uma refeição de café, almoço e jantar',
    description: 'Registre uma refeição de café, almoço e jantar',
    targetValue: 3,
    rewardGold: 15,
    rewardXp: 30,
    sortOrder: 1,
    accent: 'action',
  },
  {
    key: 'daily_protein_goal',
    type: 'daily',
    title: 'Atinja sua meta diária de proteínas',
    description: 'Atinja sua meta diária de proteínas',
    targetValue: 1,
    rewardGold: 25,
    rewardXp: 50,
    sortOrder: 2,
    accent: 'action',
  },
  {
    key: 'weekly_variety_15_foods',
    type: 'weekly',
    title: 'Registre 15 alimentos diferentes na semana',
    description: 'Registre 15 alimentos diferentes na semana',
    targetValue: 15,
    rewardGold: 60,
    rewardXp: 120,
    sortOrder: 1,
    accent: 'accent',
  },
  {
    key: 'weekly_goal_4_times',
    type: 'weekly',
    title: 'Bata sua meta calórica em 4 dias da semana',
    description: 'Bata sua meta calórica em 4 dias da semana',
    targetValue: 4,
    rewardGold: 80,
    rewardXp: 160,
    sortOrder: 2,
    accent: 'accent',
  },
  {
    key: 'weekly_streak_5_days',
    type: 'weekly',
    title: 'Registre refeições por 5 dias seguidos',
    description: 'Registre refeições por 5 dias seguidos',
    targetValue: 5,
    rewardGold: 100,
    rewardXp: 200,
    sortOrder: 3,
    accent: 'accent',
  },
  {
    key: WEEKLY_UPDATE_WEIGHT_MISSION_KEY,
    type: 'weekly',
    title: 'Atualize o seu peso na semana',
    description: 'Atualize o seu peso na semana',
    targetValue: 1,
    rewardGold: 30,
    rewardXp: 60,
    sortOrder: 4,
    accent: 'accent',
  },
  {
    key: 'monthly_objective_focus',
    type: 'monthly',
    title: 'Registre refeições em 20 dias no mês',
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
    title: 'Bata seu objetivo diário em 20 dias no mês',
    description: 'Bata seu objetivo diário em 20 dias no mês',
    targetValue: 20,
    rewardGold: 250,
    rewardXp: 500,
    sortOrder: 2,
    accent: 'challenge',
  },
  {
    key: 'monthly_macro_hunter',
    type: 'monthly',
    title: 'Atinja todas as metas de macros em 10 dias',
    description: 'Atinja todas as metas de macros em 10 dias',
    targetValue: 10,
    rewardGold: 320,
    rewardXp: 640,
    sortOrder: 3,
    accent: 'challenge',
  },
  {
    key: WEEKEND_GOAL_MISSION_KEY,
    type: 'weekend',
    title: 'Bata a meta diária na sexta, sábado e domingo',
    description: 'Bata a meta diária na sexta, sábado e domingo',
    targetValue: 3,
    rewardGold: 120,
    rewardXp: 240,
    sortOrder: 1,
    accent: 'challenge',
  },
];
