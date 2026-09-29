import { Controller, Get } from '@nestjs/common';
import { InjectConnection } from '@nestjs/sequelize';
import { QueryTypes, Sequelize } from 'sequelize';
import { InfraMetricsService } from '../analytics/infra-metrics.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly infraMetrics: InfraMetricsService,
    @InjectConnection()
    private readonly sequelize: Sequelize,
  ) {}

  @Get()
  async check() {
    let database: 'up' | 'down' = 'down';
    let dbLatencyMs: number | null = null;

    const started = Date.now();
    try {
      await this.sequelize.query('SELECT 1', { type: QueryTypes.SELECT });
      dbLatencyMs = Date.now() - started;
      database = 'up';
    } catch {
      database = 'down';
      dbLatencyMs = Date.now() - started;
    }

    const snapshot =
      this.infraMetrics.getLastSnapshot() ??
      (await this.infraMetrics.captureSnapshot());

    return {
      status: database === 'up' ? 'ok' : 'degraded',
      database,
      dbLatencyMs,
      processUptimeSec: this.infraMetrics.getProcessUptimeSec(),
      bootAt: this.infraMetrics.getBootAtIso(),
      infra: {
        cpuPct: snapshot.cpuPct,
        memUsedPct: snapshot.memUsedPct,
        concurrentUsers: snapshot.concurrentUsers,
        concurrentSessions: snapshot.concurrentSessions,
      },
    };
  }
}
