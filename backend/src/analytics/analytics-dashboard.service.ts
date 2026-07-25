import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectConnection } from '@nestjs/sequelize';
import { QueryTypes, Sequelize } from 'sequelize';
import { resolveGeminiQuotaLimits } from '../ai/gemini-quota.config';
import { InfraMetricsService } from './infra-metrics.service';

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
    private readonly infraMetrics: InfraMetricsService,
    private readonly configService: ConfigService,
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
      this.getDauSeries(betaStart, betaEnd),
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

  async getPerformance(query: DashboardQuery = {}) {
    const days = Math.min(Math.max(Number(query.days) || 30, 7), 90);
    const betaStart =
      query.betaStart?.trim() ||
      new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
    const betaEnd = query.betaEnd?.trim() || new Date().toISOString();

    const [
      aiOverview,
      aiSeries,
      models,
      errors,
      quotas,
      supportOverview,
      recentSupport,
      infraLive,
      infraOverview,
      infraSeries,
      concurrentSeries,
    ] = await Promise.all([
      this.getAiOverview(betaStart, betaEnd),
      this.getAiSeries(betaStart, betaEnd),
      this.getAiModels(betaStart, betaEnd),
      this.getAiErrors(betaStart, betaEnd),
      this.getAiQuotas(),
      this.getSupportOverview(betaStart, betaEnd).catch(() => ({
        total: 0,
        bugs: 0,
        suggestions: 0,
      })),
      this.getRecentSupport(betaStart, betaEnd).catch(() => []),
      this.getInfraLive(),
      this.getInfraOverview(betaStart, betaEnd),
      this.getInfraSeries(betaStart, betaEnd),
      this.getConcurrentSeries(betaStart, betaEnd),
    ]);

    return {
      generatedAt: new Date().toISOString(),
      range: { betaStart, betaEnd, days },
      infra: {
        live: infraLive,
        overview: infraOverview,
        series: infraSeries,
        concurrentSeries,
      },
      ai: {
        overview: aiOverview,
        series: aiSeries,
        models,
        errors,
        quotas,
      },
      support: {
        overview: supportOverview,
        recent: recentSupport,
      },
    };
  }

  private async getInfraLive() {
    // Prefere a última amostra persistida pela AWS (source=aws).
    // Assim, mesmo que alguém consulte via backend local, o live não mostra a máquina do dev.
    const rows = await this.sequelize.query<{
      occurred_at: Date;
      properties: Record<string, unknown> | null;
    }>(
      `
      SELECT occurred_at, properties
      FROM analytics_events
      WHERE event_name = 'infra_sample'
        AND COALESCE(properties->>'source', '') = 'aws'
      ORDER BY occurred_at DESC
      LIMIT 1
      `,
      { type: QueryTypes.SELECT },
    );

    const row = rows[0];
    if (row?.properties) {
      const p = row.properties;
      return {
        sampledAt: new Date(row.occurred_at).toISOString(),
        hostname: String(p.hostname ?? '—'),
        instanceTypeHint:
          p.instance_type != null ? String(p.instance_type) : null,
        processUptimeSec: Number(p.process_uptime_sec || 0),
        hostUptimeSec: Number(p.host_uptime_sec || 0),
        cpuPct: p.cpu_pct != null ? Number(p.cpu_pct) : null,
        loadAvg1m: Number(p.load_1m || 0),
        memUsedPct: Number(p.mem_used_pct || 0),
        memUsedMb: Number(p.mem_used_mb || 0),
        memTotalMb: Number(p.mem_total_mb || 0),
        processRssMb: Number(p.process_rss_mb || 0),
        processHeapMb: Number(p.process_heap_mb || 0),
        concurrentSessions: Number(p.concurrent_sessions || 0),
        concurrentUsers: Number(p.concurrent_users || 0),
      };
    }

    // Só cai no snapshot do processo atual em produção (antes da 1ª persistência).
    if (process.env.NODE_ENV === 'production') {
      return (
        this.infraMetrics.getLastSnapshot() ??
        (await this.infraMetrics.captureSnapshot())
      );
    }

    return null;
  }

  private async getInfraOverview(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      samples: string;
      avg_cpu: string | null;
      max_cpu: string | null;
      avg_mem: string | null;
      max_mem: string | null;
      avg_concurrent: string | null;
      max_concurrent: string | null;
      hours_with_sample: string;
    }>(
      `
      WITH samples AS (
        SELECT
          occurred_at,
          CASE
            WHEN (properties->>'cpu_pct') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (properties->>'cpu_pct')::numeric
            ELSE NULL
          END AS cpu_pct,
          CASE
            WHEN (properties->>'mem_used_pct') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (properties->>'mem_used_pct')::numeric
            ELSE NULL
          END AS mem_used_pct,
          CASE
            WHEN (properties->>'concurrent_users') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (properties->>'concurrent_users')::numeric
            ELSE NULL
          END AS concurrent_users
        FROM analytics_events
        WHERE event_name = 'infra_sample'
          AND COALESCE(properties->>'source', '') = 'aws'
          AND occurred_at >= :betaStart
          AND occurred_at < :betaEnd
      ),
      hours AS (
        SELECT DISTINCT date_trunc('hour', occurred_at) AS hour
        FROM analytics_events
        WHERE event_name = 'infra_sample'
          AND COALESCE(properties->>'source', '') = 'aws'
          AND occurred_at >= :betaStart
          AND occurred_at < :betaEnd
      )
      SELECT
        (SELECT COUNT(*)::text FROM samples) AS samples,
        (SELECT ROUND(AVG(cpu_pct), 1)::text FROM samples) AS avg_cpu,
        (SELECT ROUND(MAX(cpu_pct), 1)::text FROM samples) AS max_cpu,
        (SELECT ROUND(AVG(mem_used_pct), 1)::text FROM samples) AS avg_mem,
        (SELECT ROUND(MAX(mem_used_pct), 1)::text FROM samples) AS max_mem,
        (SELECT ROUND(AVG(concurrent_users), 1)::text FROM samples) AS avg_concurrent,
        (SELECT ROUND(MAX(concurrent_users), 0)::text FROM samples) AS max_concurrent,
        (SELECT COUNT(*)::text FROM hours) AS hours_with_sample
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    const row = rows[0];
    const startMs = new Date(betaStart).getTime();
    const endMs = new Date(betaEnd).getTime();
    const expectedHours = Math.max(
      1,
      Math.round((endMs - startMs) / (60 * 60 * 1000)),
    );
    const hoursWithSample = Number(row?.hours_with_sample || 0);
    const availabilityPct =
      Math.round(
        Math.min(100, (1000 * hoursWithSample) / expectedHours),
      ) / 10;

    return {
      samples: Number(row?.samples || 0),
      avgCpuPct: Number(row?.avg_cpu || 0),
      maxCpuPct: Number(row?.max_cpu || 0),
      avgMemPct: Number(row?.avg_mem || 0),
      maxMemPct: Number(row?.max_mem || 0),
      avgConcurrentUsers: Number(row?.avg_concurrent || 0),
      maxConcurrentUsers: Number(row?.max_concurrent || 0),
      hoursWithSample,
      expectedHours,
      availabilityPct,
      note:
        'Disponibilidade estimada pela cobertura de amostras do processo (gaps = restart/deploy/queda). CPU/RAM = host visto de dentro do container EB.',
    };
  }

  private async getInfraSeries(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      bucket: string;
      cpu_pct: string | null;
      mem_used_pct: string | null;
      concurrent_users: string | null;
      process_rss_mb: string | null;
    }>(
      `
      SELECT
        to_char(
          date_trunc('hour', occurred_at AT TIME ZONE 'America/Sao_Paulo'),
          'YYYY-MM-DD HH24:00'
        ) AS bucket,
        ROUND(AVG(
          CASE
            WHEN (properties->>'cpu_pct') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (properties->>'cpu_pct')::numeric
            ELSE NULL
          END
        ), 1)::text AS cpu_pct,
        ROUND(AVG(
          CASE
            WHEN (properties->>'mem_used_pct') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (properties->>'mem_used_pct')::numeric
            ELSE NULL
          END
        ), 1)::text AS mem_used_pct,
        ROUND(AVG(
          CASE
            WHEN (properties->>'concurrent_users') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (properties->>'concurrent_users')::numeric
            ELSE NULL
          END
        ), 1)::text AS concurrent_users,
        ROUND(AVG(
          CASE
            WHEN (properties->>'process_rss_mb') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (properties->>'process_rss_mb')::numeric
            ELSE NULL
          END
        ), 0)::text AS process_rss_mb
      FROM analytics_events
      WHERE event_name = 'infra_sample'
        AND COALESCE(properties->>'source', '') = 'aws'
        AND occurred_at >= :betaStart
        AND occurred_at < :betaEnd
      GROUP BY 1
      ORDER BY 1
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      bucket: row.bucket,
      cpuPct: Number(row.cpu_pct || 0),
      memUsedPct: Number(row.mem_used_pct || 0),
      concurrentUsers: Number(row.concurrent_users || 0),
      processRssMb: Number(row.process_rss_mb || 0),
    }));
  }

  private async getConcurrentSeries(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      bucket: string;
      peak: string;
    }>(
      `
      WITH minute_buckets AS (
        SELECT
          date_trunc('minute', occurred_at AT TIME ZONE 'America/Sao_Paulo') AS minute,
          COUNT(DISTINCT session_id) AS concurrent
        FROM analytics_events
        WHERE event_name = 'session_heartbeat'
          AND occurred_at >= :betaStart
          AND occurred_at < :betaEnd
          AND session_id IS NOT NULL
        GROUP BY 1
      )
      SELECT
        to_char(date_trunc('hour', minute), 'YYYY-MM-DD HH24:00') AS bucket,
        MAX(concurrent)::text AS peak
      FROM minute_buckets
      GROUP BY 1
      ORDER BY 1
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      bucket: row.bucket,
      peak: Number(row.peak || 0),
    }));
  }

  /**
   * Espelho das cotas do AI Studio a partir dos eventos do Nest.
   * Conta chamadas reais ao Gemini (modelo vencedor + tentativas em failed_models),
   * excluindo cache. RPD usa dia Pacific (igual ao Google).
   */
  private async getAiQuotas() {
    const limits = resolveGeminiQuotaLimits(
      this.configService.get<string>('GEMINI_QUOTA_LIMITS'),
    );
    const modelKeys = limits.map((row) => row.model);

    const rows = await this.sequelize.query<{
      model: string;
      rpd_used: string;
      rpm_used: string;
      tpm_used: string;
    }>(
      `
      WITH base AS (
        SELECT
          occurred_at,
          properties,
          event_name,
          COALESCE((properties->>'cache_hit')::boolean, false) AS cache_hit
        FROM analytics_events
        WHERE event_name IN ('ai_analyze_succeeded', 'ai_analyze_failed')
          AND COALESCE(properties->>'source', 'server') = 'server'
          AND occurred_at >= (NOW() AT TIME ZONE 'America/Los_Angeles')::date
            AT TIME ZONE 'America/Los_Angeles'
      ),
      expanded AS (
        SELECT
          b.occurred_at,
          TRIM(b.properties->>'model') AS model,
          CASE
            WHEN b.event_name = 'ai_analyze_succeeded'
              AND (b.properties->>'total_tokens') ~ '^[0-9]+(\\.[0-9]+)?$'
            THEN (b.properties->>'total_tokens')::numeric
            ELSE 0
          END AS tokens
        FROM base b
        WHERE NOT b.cache_hit
          AND NULLIF(TRIM(b.properties->>'model'), '') IS NOT NULL
          AND TRIM(b.properties->>'model') NOT IN ('cache', 'unknown', 'legado')
          AND (
            b.event_name = 'ai_analyze_succeeded'
            OR jsonb_typeof(COALESCE(b.properties->'failed_models', '[]'::jsonb)) IS DISTINCT FROM 'array'
            OR jsonb_array_length(COALESCE(b.properties->'failed_models', '[]'::jsonb)) = 0
          )

        UNION ALL

        SELECT
          b.occurred_at,
          TRIM(failed.model) AS model,
          0::numeric AS tokens
        FROM base b
        CROSS JOIN LATERAL jsonb_array_elements_text(
          CASE
            WHEN jsonb_typeof(COALESCE(b.properties->'failed_models', '[]'::jsonb)) = 'array'
            THEN COALESCE(b.properties->'failed_models', '[]'::jsonb)
            ELSE '[]'::jsonb
          END
        ) AS failed(model)
        WHERE NULLIF(TRIM(failed.model), '') IS NOT NULL
          AND TRIM(failed.model) NOT IN ('cache', 'unknown', 'legado')
      )
      SELECT
        model,
        COUNT(*) FILTER (
          WHERE occurred_at >= (NOW() AT TIME ZONE 'America/Los_Angeles')::date
            AT TIME ZONE 'America/Los_Angeles'
        )::text AS rpd_used,
        COUNT(*) FILTER (
          WHERE occurred_at >= NOW() - INTERVAL '1 minute'
        )::text AS rpm_used,
        COALESCE(
          SUM(tokens) FILTER (
            WHERE occurred_at >= NOW() - INTERVAL '1 minute'
          )::text,
          '0'
        ) AS tpm_used
      FROM expanded
      WHERE model IN (:models)
      GROUP BY model
      `,
      {
        replacements: { models: modelKeys },
        type: QueryTypes.SELECT,
      },
    );

    const usageByModel = new Map(
      rows.map((row) => [
        row.model,
        {
          rpdUsed: Number(row.rpd_used || 0),
          rpmUsed: Number(row.rpm_used || 0),
          tpmUsed: Number(row.tpm_used || 0),
        },
      ]),
    );

    const models = limits.map((limit) => {
      const usage = usageByModel.get(limit.model) || {
        rpdUsed: 0,
        rpmUsed: 0,
        tpmUsed: 0,
      };
      const pct = (used: number, max: number) =>
        max > 0 ? Math.min(100, Math.round((1000 * used) / max) / 10) : 0;

      return {
        model: limit.model,
        label: limit.label,
        rpm: {
          used: usage.rpmUsed,
          limit: limit.rpm,
          pct: pct(usage.rpmUsed, limit.rpm),
        },
        tpm: {
          used: usage.tpmUsed,
          limit: limit.tpm,
          pct: pct(usage.tpmUsed, limit.tpm),
        },
        rpd: {
          used: usage.rpdUsed,
          limit: limit.rpd,
          pct: pct(usage.rpdUsed, limit.rpd),
        },
      };
    });

    return {
      source: 'analytics_mirror',
      note: 'Espelho interno dos eventos do Nest (não é a API oficial do Google). RPD = dia Pacific. Cache não conta.',
      resetTimezone: 'America/Los_Angeles',
      models,
    };
  }

  private async getAiOverview(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      requested: string;
      succeeded: string;
      failed: string;
      cache_hits: string;
      avg_latency_ms: string | null;
      p50_latency_ms: string | null;
      p95_latency_ms: string | null;
      total_tokens: string | null;
      unique_users: string;
    }>(
      `
      WITH scoped AS (
        SELECT
          event_name,
          user_id,
          properties
        FROM analytics_events
        WHERE occurred_at >= :betaStart
          AND occurred_at < :betaEnd
          AND event_name IN (
            'ai_analyze_requested',
            'ai_analyze_succeeded',
            'ai_analyze_failed'
          )
      ),
      latencies AS (
        SELECT (properties->>'latency_ms')::numeric AS latency_ms
        FROM scoped
        WHERE event_name IN ('ai_analyze_succeeded', 'ai_analyze_failed')
          AND (properties->>'latency_ms') ~ '^[0-9]+(\\.[0-9]+)?$'
      )
      SELECT
        (SELECT COUNT(*)::text FROM scoped WHERE event_name = 'ai_analyze_requested') AS requested,
        (SELECT COUNT(*)::text FROM scoped WHERE event_name = 'ai_analyze_succeeded') AS succeeded,
        (SELECT COUNT(*)::text FROM scoped WHERE event_name = 'ai_analyze_failed') AS failed,
        (
          SELECT COUNT(*)::text
          FROM scoped
          WHERE event_name = 'ai_analyze_succeeded'
            AND COALESCE((properties->>'cache_hit')::boolean, false)
        ) AS cache_hits,
        (SELECT ROUND(AVG(latency_ms))::text FROM latencies) AS avg_latency_ms,
        (
          SELECT ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY latency_ms))::text
          FROM latencies
        ) AS p50_latency_ms,
        (
          SELECT ROUND(percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms))::text
          FROM latencies
        ) AS p95_latency_ms,
        (
          SELECT COALESCE(
            SUM(
              CASE
                WHEN (properties->>'total_tokens') ~ '^[0-9]+(\\.[0-9]+)?$'
                THEN (properties->>'total_tokens')::numeric
                ELSE 0
              END
            )::text,
            '0'
          )
          FROM scoped
          WHERE event_name = 'ai_analyze_succeeded'
        ) AS total_tokens,
        (SELECT COUNT(DISTINCT user_id)::text FROM scoped) AS unique_users
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    const row = rows[0];
    const requested = Number(row?.requested || 0);
    const succeeded = Number(row?.succeeded || 0);
    const failed = Number(row?.failed || 0);
    const decided = succeeded + failed;
    const cacheHits = Number(row?.cache_hits || 0);

    return {
      requested,
      succeeded,
      failed,
      errorRatePct:
        decided > 0 ? Math.round((1000 * failed) / decided) / 10 : 0,
      cacheHits,
      cacheHitRatePct:
        succeeded > 0 ? Math.round((1000 * cacheHits) / succeeded) / 10 : 0,
      avgLatencyMs: Number(row?.avg_latency_ms || 0),
      p50LatencyMs: Number(row?.p50_latency_ms || 0),
      p95LatencyMs: Number(row?.p95_latency_ms || 0),
      totalTokens: Number(row?.total_tokens || 0),
      uniqueUsers: Number(row?.unique_users || 0),
    };
  }

  private async getAiSeries(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      day: string;
      requested: string;
      succeeded: string;
      failed: string;
    }>(
      `
      SELECT
        to_char(
          (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date,
          'YYYY-MM-DD'
        ) AS day,
        COUNT(*) FILTER (WHERE event_name = 'ai_analyze_requested')::text AS requested,
        COUNT(*) FILTER (WHERE event_name = 'ai_analyze_succeeded')::text AS succeeded,
        COUNT(*) FILTER (WHERE event_name = 'ai_analyze_failed')::text AS failed
      FROM analytics_events
      WHERE occurred_at >= :betaStart
        AND occurred_at < :betaEnd
        AND event_name IN (
          'ai_analyze_requested',
          'ai_analyze_succeeded',
          'ai_analyze_failed'
        )
      GROUP BY 1
      ORDER BY 1
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      day: row.day,
      requested: Number(row.requested),
      succeeded: Number(row.succeeded),
      failed: Number(row.failed),
    }));
  }

  private async getAiModels(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      model: string;
      calls: string;
      succeeded: string;
      failed: string;
      avg_latency_ms: string | null;
      total_tokens: string | null;
    }>(
      `
      SELECT
        CASE
          WHEN NULLIF(TRIM(properties->>'model'), '') IS NOT NULL
            THEN TRIM(properties->>'model')
          WHEN COALESCE((properties->>'cache_hit')::boolean, false)
            THEN 'cache'
          ELSE 'legado'
        END AS model,
        COUNT(*)::text AS calls,
        COUNT(*) FILTER (WHERE event_name = 'ai_analyze_succeeded')::text AS succeeded,
        COUNT(*) FILTER (WHERE event_name = 'ai_analyze_failed')::text AS failed,
        ROUND(
          AVG(
            CASE
              WHEN (properties->>'latency_ms') ~ '^[0-9]+(\\.[0-9]+)?$'
              THEN (properties->>'latency_ms')::numeric
              ELSE NULL
            END
          )
        )::text AS avg_latency_ms,
        COALESCE(
          SUM(
            CASE
              WHEN event_name = 'ai_analyze_succeeded'
                AND (properties->>'total_tokens') ~ '^[0-9]+(\\.[0-9]+)?$'
              THEN (properties->>'total_tokens')::numeric
              ELSE 0
            END
          )::text,
          '0'
        ) AS total_tokens
      FROM analytics_events
      WHERE occurred_at >= :betaStart
        AND occurred_at < :betaEnd
        AND event_name IN ('ai_analyze_succeeded', 'ai_analyze_failed')
        AND COALESCE(properties->>'source', 'server') = 'server'
      GROUP BY 1
      ORDER BY COUNT(*) DESC
      LIMIT 12
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => {
      const calls = Number(row.calls);
      const succeeded = Number(row.succeeded);
      const failed = Number(row.failed);
      return {
        model: row.model,
        calls,
        succeeded,
        failed,
        errorRatePct:
          calls > 0 ? Math.round((1000 * failed) / calls) / 10 : 0,
        avgLatencyMs: Number(row.avg_latency_ms || 0),
        totalTokens: Number(row.total_tokens || 0),
      };
    });
  }

  private async getAiErrors(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      error_code: string;
      count: string;
    }>(
      `
      SELECT
        COALESCE(NULLIF(properties->>'error_code', ''), 'error') AS error_code,
        COUNT(*)::text AS count
      FROM analytics_events
      WHERE occurred_at >= :betaStart
        AND occurred_at < :betaEnd
        AND event_name = 'ai_analyze_failed'
      GROUP BY 1
      ORDER BY COUNT(*) DESC
      LIMIT 10
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      errorCode: row.error_code,
      count: Number(row.count),
    }));
  }

  private async getSupportOverview(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      total: string;
      bugs: string;
      suggestions: string;
    }>(
      `
      SELECT
        COUNT(*)::text AS total,
        COUNT(*) FILTER (WHERE subject_type = 'bug')::text AS bugs,
        COUNT(*) FILTER (WHERE subject_type = 'suggestion')::text AS suggestions
      FROM support_messages
      WHERE created_at >= :betaStart
        AND created_at < :betaEnd
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    const row = rows[0];
    return {
      total: Number(row?.total || 0),
      bugs: Number(row?.bugs || 0),
      suggestions: Number(row?.suggestions || 0),
    };
  }

  private async getRecentSupport(betaStart: string, betaEnd: string) {
    const rows = await this.sequelize.query<{
      id: string;
      subject_type: string;
      description: string;
      user_name: string | null;
      contact_email: string | null;
      created_at: Date;
    }>(
      `
      SELECT
        id,
        subject_type,
        description,
        user_name,
        contact_email,
        created_at
      FROM support_messages
      WHERE created_at >= :betaStart
        AND created_at < :betaEnd
      ORDER BY created_at DESC
      LIMIT 20
      `,
      {
        replacements: { betaStart, betaEnd },
        type: QueryTypes.SELECT,
      },
    );

    return rows.map((row) => ({
      id: row.id,
      subjectType: row.subject_type,
      description: row.description,
      userName: row.user_name,
      contactEmail: row.contact_email,
      createdAt: new Date(row.created_at).toISOString(),
    }));
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

  private async getDauSeries(betaStart: string, betaEnd: string) {
    // Uma linha por dia do período (Brasília), preenchendo com 0 os dias sem
    // atividade. betaEnd é exclusivo, então o último dia é (betaEnd - 1 dia).
    const rows = await this.sequelize.query<{ day: string; dau: string }>(
      `
      SELECT
        gs::date::text AS day,
        COALESCE(s.dau, 0)::text AS dau
      FROM generate_series(
        (:betaStart::timestamptz AT TIME ZONE 'America/Sao_Paulo')::date,
        ((:betaEnd::timestamptz AT TIME ZONE 'America/Sao_Paulo') - INTERVAL '1 day')::date,
        INTERVAL '1 day'
      ) AS gs
      LEFT JOIN (
        SELECT
          (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date AS day,
          COUNT(DISTINCT user_id) AS dau
        FROM analytics_events
        WHERE event_name = 'app_open'
          AND occurred_at >= :betaStart
          AND occurred_at < :betaEnd
        GROUP BY 1
      ) s ON s.day = gs::date
      ORDER BY gs
      `,
      {
        replacements: { betaStart, betaEnd },
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
