import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/sequelize';
import { QueryTypes, Sequelize } from 'sequelize';

export type DashboardQuery = {
  betaStart?: string;
  betaEnd?: string;
  days?: number;
};

@Injectable()
export class AnalyticsDashboardService {
  constructor(
    @InjectConnection()
    private readonly sequelize: Sequelize,
  ) {}

  async getDashboard(query: DashboardQuery = {}) {
    const days = Math.min(Math.max(Number(query.days) || 30, 7), 90);
    const betaStart =
      query.betaStart?.trim() ||
      new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
    const betaEnd = query.betaEnd?.trim() || new Date().toISOString();

    const [
      overview,
      dauSeries,
      funnel,
      retention,
      featureRetention,
      sessions,
      topScreens,
      eventCounts,
      platforms,
    ] = await Promise.all([
      this.getOverview(betaStart, betaEnd),
      this.getDauSeries(days),
      this.getFunnel(betaStart, betaEnd),
      this.getRetention(betaStart, betaEnd),
      this.getFeatureRetention(betaStart, betaEnd),
      this.getSessionStats(betaStart, betaEnd),
      this.getTopScreens(betaStart, betaEnd),
      this.getEventCounts(betaStart, betaEnd),
      this.getPlatformMix(betaStart, betaEnd),
    ]);

    return {
      generatedAt: new Date().toISOString(),
      range: { betaStart, betaEnd, days },
      overview,
      dauSeries,
      funnel,
      retention,
      featureRetention,
      sessions,
      topScreens,
      eventCounts,
      platforms,
    };
  }

  private async getOverview(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      signups: string;
      onboarding_complete: string;
      activated: string;
      dau_today: string;
      wau: string;
      active_7d: string;
      active_30d: string;
    }>(
      `
      WITH cohort AS (
        SELECT id, created_at,
          (
            birth_date IS NOT NULL
            AND weight IS NOT NULL
            AND height IS NOT NULL
            AND sex IS NOT NULL
            AND objective IS NOT NULL
            AND activity_level IS NOT NULL
          ) AS onboarding_complete
        FROM users
        WHERE created_at >= :betaStart AND created_at < :betaEnd
      ),
      activated AS (
        SELECT DISTINCT user_id
        FROM meals
        WHERE status = 'active' AND user_id IS NOT NULL
      )
      SELECT
        (SELECT COUNT(*)::text FROM cohort) AS signups,
        (SELECT COUNT(*)::text FROM cohort WHERE onboarding_complete) AS onboarding_complete,
        (SELECT COUNT(*)::text FROM cohort c INNER JOIN activated a ON a.user_id = c.id) AS activated,
        (
          SELECT COUNT(DISTINCT user_id)::text
          FROM analytics_events
          WHERE event_name = 'app_open'
            AND (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date
              = (now() AT TIME ZONE 'America/Sao_Paulo')::date
        ) AS dau_today,
        (
          SELECT COUNT(DISTINCT user_id)::text
          FROM analytics_events
          WHERE event_name = 'app_open'
            AND occurred_at >= now() - INTERVAL '7 days'
        ) AS wau,
        (
          SELECT COUNT(*)::text
          FROM users
          WHERE last_active_at >= now() - INTERVAL '7 days'
             OR id IN (
               SELECT DISTINCT user_id FROM analytics_events
               WHERE event_name = 'app_open' AND occurred_at >= now() - INTERVAL '7 days'
             )
        ) AS active_7d,
        (
          SELECT COUNT(*)::text
          FROM users
          WHERE last_active_at >= now() - INTERVAL '30 days'
             OR id IN (
               SELECT DISTINCT user_id FROM analytics_events
               WHERE event_name = 'app_open' AND occurred_at >= now() - INTERVAL '30 days'
             )
        ) AS active_30d
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    const row = rows[0] ?? {
      signups: '0',
      onboarding_complete: '0',
      activated: '0',
      dau_today: '0',
      wau: '0',
      active_7d: '0',
      active_30d: '0',
    };

    return {
      signups: Number(row.signups),
      onboardingComplete: Number(row.onboarding_complete),
      activated: Number(row.activated),
      dauToday: Number(row.dau_today),
      wau: Number(row.wau),
      active7d: Number(row.active_7d),
      active30d: Number(row.active_30d),
    };
  }

  private async getDauSeries(days: number) {
    const rows = await this.sequelize.query<{ day: string; dau: string }>(
      `
      SELECT
        (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date::text AS day,
        COUNT(DISTINCT user_id)::text AS dau
      FROM analytics_events
      WHERE event_name = 'app_open'
        AND occurred_at >= (now() AT TIME ZONE 'America/Sao_Paulo')::date
            - (:days::int - 1)
      GROUP BY 1
      ORDER BY 1
      `,
      {
        replacements: { days },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      day: row.day,
      dau: Number(row.dau),
    }));
  }

  private async getFunnel(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      signups: string;
      onboarding_complete: string;
      capture_started: string;
      ai_succeeded: string;
      meal_saved: string;
    }>(
      `
      WITH cohort AS (
        SELECT id
        FROM users
        WHERE created_at >= :betaStart AND created_at < :betaEnd
      )
      SELECT
        (SELECT COUNT(*)::text FROM cohort) AS signups,
        (
          SELECT COUNT(*)::text FROM users u
          INNER JOIN cohort c ON c.id = u.id
          WHERE u.birth_date IS NOT NULL
            AND u.weight IS NOT NULL
            AND u.height IS NOT NULL
            AND u.sex IS NOT NULL
            AND u.objective IS NOT NULL
            AND u.activity_level IS NOT NULL
        ) AS onboarding_complete,
        (
          SELECT COUNT(DISTINCT user_id)::text
          FROM analytics_events e
          INNER JOIN cohort c ON c.id = e.user_id
          WHERE e.event_name = 'meal_capture_started'
        ) AS capture_started,
        (
          SELECT COUNT(DISTINCT user_id)::text
          FROM analytics_events e
          INNER JOIN cohort c ON c.id = e.user_id
          WHERE e.event_name = 'ai_analyze_succeeded'
            AND COALESCE(e.properties->>'source', 'server') = 'server'
        ) AS ai_succeeded,
        (
          SELECT COUNT(DISTINCT user_id)::text
          FROM analytics_events e
          INNER JOIN cohort c ON c.id = e.user_id
          WHERE e.event_name = 'meal_saved'
        ) AS meal_saved
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    const row = rows[0];
    return [
      { step: 'Signups', users: Number(row?.signups ?? 0) },
      { step: 'Onboarding completo', users: Number(row?.onboarding_complete ?? 0) },
      { step: 'Iniciou captura', users: Number(row?.capture_started ?? 0) },
      { step: 'IA analisou', users: Number(row?.ai_succeeded ?? 0) },
      { step: 'Salvou refeição', users: Number(row?.meal_saved ?? 0) },
    ];
  }

  private async getRetention(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      cohort_size: string;
      retained_d1: string;
      retained_d7: string;
      retained_d14: string;
    }>(
      `
      WITH cohort AS (
        SELECT
          id AS user_id,
          (created_at AT TIME ZONE 'America/Sao_Paulo')::date AS signup_day
        FROM users
        WHERE created_at >= :betaStart AND created_at < :betaEnd
      ),
      activity AS (
        SELECT DISTINCT
          user_id,
          (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date AS activity_day
        FROM analytics_events
        WHERE event_name IN ('app_open', 'meal_saved')
          AND user_id IS NOT NULL
        UNION
        SELECT DISTINCT
          user_id,
          (created_at AT TIME ZONE 'America/Sao_Paulo')::date AS activity_day
        FROM meals
        WHERE status = 'active' AND user_id IS NOT NULL
      )
      SELECT
        COUNT(*)::text AS cohort_size,
        COUNT(*) FILTER (
          WHERE EXISTS (
            SELECT 1 FROM activity a
            WHERE a.user_id = c.user_id AND a.activity_day = c.signup_day + 1
          )
        )::text AS retained_d1,
        COUNT(*) FILTER (
          WHERE EXISTS (
            SELECT 1 FROM activity a
            WHERE a.user_id = c.user_id AND a.activity_day = c.signup_day + 7
          )
        )::text AS retained_d7,
        COUNT(*) FILTER (
          WHERE EXISTS (
            SELECT 1 FROM activity a
            WHERE a.user_id = c.user_id AND a.activity_day = c.signup_day + 14
          )
        )::text AS retained_d14
      FROM cohort c
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    const row = rows[0];
    const cohortSize = Number(row?.cohort_size ?? 0);
    const pct = (n: number) =>
      cohortSize > 0 ? Math.round((1000 * n) / cohortSize) / 10 : 0;

    return {
      cohortSize,
      d1: { users: Number(row?.retained_d1 ?? 0), pct: pct(Number(row?.retained_d1 ?? 0)) },
      d7: { users: Number(row?.retained_d7 ?? 0), pct: pct(Number(row?.retained_d7 ?? 0)) },
      d14: { users: Number(row?.retained_d14 ?? 0), pct: pct(Number(row?.retained_d14 ?? 0)) },
    };
  }

  private async getFeatureRetention(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      feature: string;
      used_feature: boolean;
      users: string;
      retained_d7: string;
      pct_d7: string;
    }>(
      `
      WITH cohort AS (
        SELECT
          id AS user_id,
          created_at AS signed_up_at,
          (created_at AT TIME ZONE 'America/Sao_Paulo')::date AS signup_day
        FROM users
        WHERE created_at >= :betaStart AND created_at < :betaEnd
      ),
      activated AS (
        SELECT DISTINCT user_id
        FROM meals
        WHERE status = 'active' AND user_id IS NOT NULL
      ),
      activity_days AS (
        SELECT DISTINCT
          user_id,
          (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date AS activity_day
        FROM analytics_events
        WHERE event_name IN ('app_open', 'meal_saved') AND user_id IS NOT NULL
        UNION
        SELECT DISTINCT
          user_id,
          (created_at AT TIME ZONE 'America/Sao_Paulo')::date
        FROM meals
        WHERE status = 'active' AND user_id IS NOT NULL
      ),
      base AS (
        SELECT
          c.*,
          EXISTS (
            SELECT 1 FROM meals m
            WHERE m.user_id = c.user_id
              AND m.status = 'active'
              AND m.created_at < c.signed_up_at + INTERVAL '3 days'
              AND (
                m.image_url IS NOT NULL
                OR (
                  m.analysis_items IS NOT NULL
                  AND m.analysis_items::text NOT IN ('null', '[]', '{}')
                )
              )
          ) AS used_ai_meal,
          EXISTS (
            SELECT 1 FROM user_currency_transactions t
            WHERE t.user_id = c.user_id
              AND t.source_type = 'mission_reward'
              AND t.created_at < c.signed_up_at + INTERVAL '7 days'
          ) AS used_gamification,
          (
            EXISTS (
              SELECT 1 FROM social_friendships f
              WHERE (f.user_low_id = c.user_id OR f.user_high_id = c.user_id)
                AND f.created_at < c.signed_up_at + INTERVAL '7 days'
            )
            OR EXISTS (
              SELECT 1 FROM social_group_members gm
              WHERE gm.user_id = c.user_id
                AND gm.created_at < c.signed_up_at + INTERVAL '7 days'
            )
          ) AS used_social,
          EXISTS (
            SELECT 1 FROM activity_days a
            WHERE a.user_id = c.user_id AND a.activity_day = c.signup_day + 7
          ) AS retained_d7
        FROM cohort c
        INNER JOIN activated act ON act.user_id = c.user_id
      )
      SELECT * FROM (
        SELECT 'IA / foto' AS feature, used_ai_meal AS used_feature,
          COUNT(*)::text AS users,
          COUNT(*) FILTER (WHERE retained_d7)::text AS retained_d7,
          ROUND(100.0 * COUNT(*) FILTER (WHERE retained_d7) / NULLIF(COUNT(*), 0), 1)::text AS pct_d7
        FROM base GROUP BY used_ai_meal
        UNION ALL
        SELECT 'Gamificação', used_gamification,
          COUNT(*)::text, COUNT(*) FILTER (WHERE retained_d7)::text,
          ROUND(100.0 * COUNT(*) FILTER (WHERE retained_d7) / NULLIF(COUNT(*), 0), 1)::text
        FROM base GROUP BY used_gamification
        UNION ALL
        SELECT 'Social', used_social,
          COUNT(*)::text, COUNT(*) FILTER (WHERE retained_d7)::text,
          ROUND(100.0 * COUNT(*) FILTER (WHERE retained_d7) / NULLIF(COUNT(*), 0), 1)::text
        FROM base GROUP BY used_social
      ) x
      ORDER BY feature, used_feature DESC
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => {
      const raw = row.used_feature as unknown;
      const usedFeature =
        raw === true || raw === 1 || raw === '1' || raw === 't' || raw === 'true';
      return {
        feature: row.feature,
        usedFeature,
        users: Number(row.users),
        retainedD7: Number(row.retained_d7),
        pctD7: Number(row.pct_d7),
      };
    });
  }

  private async getSessionStats(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      visits: string;
      avg_sec: string | null;
      median_sec: string | null;
    }>(
      `
      SELECT
        COUNT(*)::text AS visits,
        ROUND(AVG(dur), 1)::text AS avg_sec,
        ROUND(
          PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dur)::numeric,
          1
        )::text AS median_sec
      FROM (
        SELECT (properties->>'duration_sec')::numeric AS dur
        FROM analytics_events
        WHERE event_name = 'session_end'
          AND occurred_at >= :betaStart
          AND occurred_at < :betaEnd
          AND (properties->>'duration_sec') ~ '^[0-9]+(\\.[0-9]+)?$'
          AND (properties->>'duration_sec')::numeric > 0
          AND (properties->>'duration_sec')::numeric < 86400
      ) s
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    const row = rows[0];
    return {
      visits: Number(row?.visits ?? 0),
      avgSec: Number(row?.avg_sec ?? 0),
      medianSec: Number(row?.median_sec ?? 0),
    };
  }

  private async getTopScreens(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      screen: string;
      views: string;
    }>(
      `
      SELECT
        COALESCE(properties->>'screen_name', properties->>'screen', '(sem nome)') AS screen,
        COUNT(*)::text AS views
      FROM analytics_events
      WHERE event_name = 'screen_view'
        AND occurred_at >= :betaStart
        AND occurred_at < :betaEnd
      GROUP BY 1
      ORDER BY COUNT(*) DESC
      LIMIT 12
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      screen: row.screen,
      views: Number(row.views),
    }));
  }

  private async getEventCounts(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      event_name: string;
      count: string;
    }>(
      `
      SELECT event_name, COUNT(*)::text AS count
      FROM analytics_events
      WHERE occurred_at >= :betaStart AND occurred_at < :betaEnd
      GROUP BY 1
      ORDER BY COUNT(*) DESC
      LIMIT 20
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      eventName: row.event_name,
      count: Number(row.count),
    }));
  }

  private async getPlatformMix(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      platform: string;
      users: string;
    }>(
      `
      SELECT
        COALESCE(NULLIF(platform, ''), 'unknown') AS platform,
        COUNT(DISTINCT user_id)::text AS users
      FROM analytics_events
      WHERE event_name = 'app_open'
        AND occurred_at >= :betaStart
        AND occurred_at < :betaEnd
      GROUP BY 1
      ORDER BY COUNT(DISTINCT user_id) DESC
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      platform: row.platform,
      users: Number(row.users),
    }));
  }
}
