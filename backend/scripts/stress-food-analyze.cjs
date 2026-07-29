/**
 * Stress test: POST /api/ai/food/analyze com varias imagens.
 *
 * Uso:
 *   node scripts/stress-food-analyze.mjs
 *   node scripts/stress-food-analyze.mjs --base https://jacaloria.online/api --n 12 --concurrency 4
 *
 * Autenticacao: JWT assinado com JWT_SECRET do backend/.env (payload sub+email).
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const http = require('http');
const https = require('https');

function loadEnv(filePath) {
  const env = {};
  if (!fs.existsSync(filePath)) return env;
  for (const line of fs.readFileSync(filePath, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    env[trimmed.slice(0, eq).trim()] = value;
  }
  return env;
}

function b64url(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function signJwt(payload, secret) {
  const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = b64url(JSON.stringify(payload));
  const sig = crypto
    .createHmac('sha256', secret)
    .update(`${header}.${body}`)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return `${header}.${body}.${sig}`;
}

function parseArgs(argv) {
  const args = {
    base: 'http://127.0.0.1:3000/api',
    n: 12,
    concurrency: 4,
    userId: '2b27ad07-2d0e-46c4-ae02-6f94af879e6d',
    email: 'stress-test@jacaloria.local',
    timeoutMs: 80_000,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const val = argv[i + 1];
    if (key === '--base' && val) args.base = val.replace(/\/$/, '');
    if (key === '--n' && val) args.n = Number(val);
    if (key === '--concurrency' && val) args.concurrency = Number(val);
    if (key === '--userId' && val) args.userId = val;
    if (key === '--email' && val) args.email = val;
    if (key === '--timeoutMs' && val) args.timeoutMs = Number(val);
  }
  return args;
}

function download(url) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    lib
      .get(url, { headers: { 'User-Agent': 'jacaloria-stress/1.0' } }, (res) => {
        if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          download(res.headers.location).then(resolve, reject);
          return;
        }
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => resolve(Buffer.concat(chunks)));
        res.on('error', reject);
      })
      .on('error', reject);
  });
}

function mutateJpeg(base, salt) {
  // Altera bytes no fim para hash SHA diferente (cache miss) sem quebrar o JPEG.
  return Buffer.concat([base, Buffer.from(`\n#stress-${salt}-${crypto.randomBytes(8).toString('hex')}`)]);
}

function postJson(urlString, { token, body, timeoutMs }) {
  return new Promise((resolve) => {
    const started = Date.now();
    const url = new URL(urlString);
    const lib = url.protocol === 'https:' ? https : http;
    const payload = Buffer.from(JSON.stringify(body));
    const req = lib.request(
      {
        protocol: url.protocol,
        hostname: url.hostname,
        port: url.port || (url.protocol === 'https:' ? 443 : 80),
        path: `${url.pathname}${url.search}`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
          'Content-Length': payload.length,
          Accept: 'application/json',
        },
        timeout: timeoutMs,
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          const raw = Buffer.concat(chunks).toString('utf8');
          const latencyMs = Date.now() - started;
          const trimmed = raw.trimStart();
          const isHtml = trimmed.startsWith('<!') || trimmed.startsWith('<html');
          let json = null;
          try {
            json = JSON.parse(raw);
          } catch {
            json = null;
          }
          resolve({
            ok: res.statusCode >= 200 && res.statusCode < 300 && json != null,
            status: res.statusCode,
            latencyMs,
            isHtml,
            bodyPreview: raw.slice(0, 180).replace(/\s+/g, ' '),
            meta: json?.meta ?? null,
            itemCount: Array.isArray(json?.items) ? json.items.length : null,
            errorMessage:
              (typeof json?.message === 'string' && json.message) ||
              (Array.isArray(json?.message) ? json.message.join('; ') : null),
          });
        });
      },
    );
    req.on('timeout', () => {
      req.destroy();
      resolve({
        ok: false,
        status: 0,
        latencyMs: Date.now() - started,
        isHtml: false,
        bodyPreview: 'CLIENT_TIMEOUT',
        meta: null,
        itemCount: null,
        errorMessage: `timeout after ${timeoutMs}ms`,
      });
    });
    req.on('error', (err) => {
      resolve({
        ok: false,
        status: 0,
        latencyMs: Date.now() - started,
        isHtml: false,
        bodyPreview: String(err.message || err),
        meta: null,
        itemCount: null,
        errorMessage: String(err.message || err),
      });
    });
    req.write(payload);
    req.end();
  });
}

async function mapPool(items, concurrency, worker) {
  const results = new Array(items.length);
  let next = 0;
  async function run() {
    while (next < items.length) {
      const i = next;
      next += 1;
      results[i] = await worker(items[i], i);
    }
  }
  await Promise.all(
    Array.from({ length: Math.min(concurrency, items.length) }, () => run()),
  );
  return results;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const env = loadEnv(path.join(__dirname, '..', '.env'));
  if (!env.JWT_SECRET) {
    console.error('JWT_SECRET ausente em backend/.env');
    process.exit(1);
  }

  const token = signJwt(
    {
      sub: args.userId,
      email: args.email,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 60 * 60,
    },
    env.JWT_SECRET,
  );

  console.log(`Baixando imagem de comida de teste...`);
  const imageUrl =
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=70';
  const baseImage = await download(imageUrl);
  console.log(`Imagem base: ${(baseImage.length / 1024).toFixed(1)} KB`);

  const jobs = Array.from({ length: args.n }, (_, i) => ({
    index: i + 1,
    imageBase64: mutateJpeg(baseImage, i).toString('base64'),
  }));

  console.log(
    `\nStress: ${args.n} req | concurrency ${args.concurrency} | ${args.base}/ai/food/analyze\n`,
  );

  const startedAll = Date.now();
  const results = await mapPool(jobs, args.concurrency, async (job) => {
    const result = await postJson(`${args.base}/ai/food/analyze`, {
      token,
      timeoutMs: args.timeoutMs,
      body: {
        imageBase64: job.imageBase64,
        mimeType: 'image/jpeg',
      },
    });
    const model = result.meta?.model ?? '-';
    const attempts = result.meta?.attempts ?? '-';
    const failed = Array.isArray(result.meta?.failedModels)
      ? result.meta.failedModels.join('|') || '-'
      : '-';
    console.log(
      `#${String(job.index).padStart(2, '0')} ` +
        `${result.ok ? 'OK ' : 'ERR'} status=${result.status} ` +
        `${result.latencyMs}ms html=${result.isHtml} ` +
        `model=${model} attempts=${attempts} failed=[${failed}] ` +
        `items=${result.itemCount ?? '-'} ` +
        `${result.errorMessage ? `msg=${result.errorMessage}` : ''}`.trim(),
    );
    return result;
  });

  const totalMs = Date.now() - startedAll;
  const ok = results.filter((r) => r.ok);
  const fail = results.filter((r) => !r.ok);
  const html = results.filter((r) => r.isHtml);
  const latencies = ok.map((r) => r.latencyMs).sort((a, b) => a - b);
  const p50 = latencies[Math.floor(latencies.length * 0.5)] ?? null;
  const p95 = latencies[Math.floor(latencies.length * 0.95)] ?? null;
  const max = latencies.length ? latencies[latencies.length - 1] : null;
  const withFallback = ok.filter(
    (r) => (r.meta?.attempts ?? 1) > 1 || (r.meta?.failedModels?.length ?? 0) > 0,
  );

  console.log('\n=== RESUMO ===');
  console.log(`base: ${args.base}`);
  console.log(`total: ${results.length} | ok: ${ok.length} | fail: ${fail.length} | html: ${html.length}`);
  console.log(`wall: ${totalMs}ms | concurrency: ${args.concurrency}`);
  console.log(
    `latency ok: p50=${p50 ?? '-'}ms p95=${p95 ?? '-'}ms max=${max ?? '-'}ms`,
  );
  console.log(`ok com fallback (attempts>1): ${withFallback.length}`);
  if (fail.length) {
    const byStatus = {};
    for (const f of fail) {
      const key = `${f.status}:${f.isHtml ? 'html' : 'other'}`;
      byStatus[key] = (byStatus[key] || 0) + 1;
    }
    console.log('falhas por status:', byStatus);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
