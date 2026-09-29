import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectConnection } from '@nestjs/sequelize';
import { cpus, freemem, hostname, loadavg, totalmem, uptime } from 'os';
import { QueryTypes, Sequelize } from 'sequelize';
import { AnalyticsService } from './analytics.service';

const SAMPLE_INTERVAL_MS = 60_000;
const CONCURRENT_WINDOW_MS = 3 * 60 * 1000;

export type InfraSnapshot = {
  sampledAt: string;
  hostname: string;
  instanceTypeHint: string | null;
  processUptimeSec: number;
  hostUptimeSec: number;
  cpuPct: number | null;
  loadAvg1m: number;
  memUsedPct: number;
  memUsedMb: number;
  memTotalMb: number;
  processRssMb: number;
  processHeapMb: number;
  concurrentSessions: number;
  concurrentUsers: number;
};

@Injectable()
export class InfraMetricsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(InfraMetricsService.name);
  private timer: NodeJS.Timeout | null = null;
  private lastCpu: { idle: number; total: number } | null = null;
  private lastSnapshot: InfraSnapshot | null = null;
  private bootAt = Date.now();

  constructor(
    private readonly analyticsService: AnalyticsService,
    @InjectConnection()
    private readonly sequelize: Sequelize,
  ) {}

  onModuleInit() {
    // Primeira leitura só “armazena” ticks de CPU; a segunda já calcula %.
    void this.captureAndPersist();
    setTimeout(() => {
      void this.captureAndPersist();
    }, 1500);

    this.timer = setInterval(() => {
      void this.captureAndPersist();
    }, SAMPLE_INTERVAL_MS);
    this.timer.unref?.();
  }

  onModuleDestroy() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  getLastSnapshot(): InfraSnapshot | null {
    return this.lastSnapshot;
  }

  getProcessUptimeSec(): number {
    return Math.round(process.uptime());
  }

  async captureSnapshot(): Promise<InfraSnapshot> {
    const [concurrent, mem] = await Promise.all([
      this.getConcurrentNow(),
      Promise.resolve(this.readMemory()),
    ]);
    const cpuPct = this.sampleCpuPercent();

    const snapshot: InfraSnapshot = {
      sampledAt: new Date().toISOString(),
      hostname: hostname(),
      instanceTypeHint: process.env.INSTANCE_TYPE?.trim() || null,
      processUptimeSec: Math.round(process.uptime()),
      hostUptimeSec: Math.round(uptime()),
      cpuPct,
      loadAvg1m: Math.round(loadavg()[0] * 100) / 100,
      memUsedPct: mem.usedPct,
      memUsedMb: mem.usedMb,
      memTotalMb: mem.totalMb,
      processRssMb: mem.processRssMb,
      processHeapMb: mem.processHeapMb,
      concurrentSessions: concurrent.sessions,
      concurrentUsers: concurrent.users,
    };

    this.lastSnapshot = snapshot;
    return snapshot;
  }

  private isCloudSamplingEnabled(): boolean {
    // Evita poluir o banco de produção com CPU/RAM da máquina local
    // (dev compartilha o mesmo DATABASE_URL do Supabase).
    if (process.env.INFRA_SAMPLE_ENABLED === 'true') return true;
    if (process.env.INFRA_SAMPLE_ENABLED === 'false') return false;
    return process.env.NODE_ENV === 'production';
  }

  private async captureAndPersist(): Promise<void> {
    try {
      const snapshot = await this.captureSnapshot();
      // Só persiste quando já temos CPU (segunda amostra em diante).
      if (snapshot.cpuPct == null) {
        return;
      }

      if (!this.isCloudSamplingEnabled()) {
        return;
      }

      await this.analyticsService.trackSafe(null, {
        eventName: 'infra_sample',
        properties: {
          cpu_pct: snapshot.cpuPct,
          load_1m: snapshot.loadAvg1m,
          mem_used_pct: snapshot.memUsedPct,
          mem_used_mb: snapshot.memUsedMb,
          mem_total_mb: snapshot.memTotalMb,
          process_rss_mb: snapshot.processRssMb,
          process_heap_mb: snapshot.processHeapMb,
          process_uptime_sec: snapshot.processUptimeSec,
          host_uptime_sec: snapshot.hostUptimeSec,
          concurrent_sessions: snapshot.concurrentSessions,
          concurrent_users: snapshot.concurrentUsers,
          hostname: snapshot.hostname,
          instance_type: snapshot.instanceTypeHint,
          source: 'aws',
          env: 'production',
        },
      });
    } catch (error) {
      this.logger.warn(
        `Falha ao amostrar infra: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  private readMemory() {
    const total = totalmem();
    const free = freemem();
    const used = Math.max(0, total - free);
    const usage = process.memoryUsage();
    return {
      totalMb: Math.round(total / (1024 * 1024)),
      usedMb: Math.round(used / (1024 * 1024)),
      usedPct: total > 0 ? Math.round((1000 * used) / total) / 10 : 0,
      processRssMb: Math.round(usage.rss / (1024 * 1024)),
      processHeapMb: Math.round(usage.heapUsed / (1024 * 1024)),
    };
  }

  private sampleCpuPercent(): number | null {
    const times = cpus().map((cpu) => cpu.times);
    let idle = 0;
    let total = 0;
    for (const t of times) {
      idle += t.idle;
      total += t.user + t.nice + t.sys + t.idle + t.irq;
    }

    if (!this.lastCpu || total <= this.lastCpu.total) {
      this.lastCpu = { idle, total };
      return null;
    }

    const idleDiff = idle - this.lastCpu.idle;
    const totalDiff = total - this.lastCpu.total;
    this.lastCpu = { idle, total };
    if (totalDiff <= 0) {
      return 0;
    }

    const busy = 1 - idleDiff / totalDiff;
    return Math.max(0, Math.min(100, Math.round(busy * 1000) / 10));
  }

  private async getConcurrentNow(): Promise<{
    sessions: number;
    users: number;
  }> {
    const since = new Date(Date.now() - CONCURRENT_WINDOW_MS).toISOString();
    try {
      const rows = await this.sequelize.query<{
        sessions: string;
        users: string;
      }>(
        `
        SELECT
          COUNT(DISTINCT session_id)::text AS sessions,
          COUNT(DISTINCT user_id)::text AS users
        FROM analytics_events
        WHERE event_name = 'session_heartbeat'
          AND occurred_at >= :since
          AND session_id IS NOT NULL
        `,
        {
          replacements: { since },
          type: QueryTypes.SELECT,
        },
      );
      return {
        sessions: Number(rows[0]?.sessions || 0),
        users: Number(rows[0]?.users || 0),
      };
    } catch {
      return { sessions: 0, users: 0 };
    }
  }

  /** Tempo desde o boot deste processo Nest (não do host AWS). */
  getBootAtIso(): string {
    return new Date(this.bootAt).toISOString();
  }
}
