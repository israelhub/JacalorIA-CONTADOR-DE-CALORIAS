(() => {
  const TOKEN_KEY = "jacaloria_beta_dashboard_token";
  // Em localhost: API same-origin (Nest local) — features novas como notificações
  // ainda não estão no deploy. Performance/infra usa a AWS (CPU/RAM do EC2).
  const isLocalHost = /^(localhost|127\.0\.0\.1)$/i.test(
    window.location.hostname,
  );
  const apiBase = `${window.location.origin}/api`;
  const cloudApiBase = "https://jacaloria.online/api";
  const analyticsApiBase = (path) => {
    if (!isLocalHost) return apiBase;
    // Só a view Performance precisa do EC2 (CPU/RAM). IA/suporte usam Nest local.
    if (path === "performance" && currentView === "performance") {
      return cloudApiBase;
    }
    return apiBase;
  };

  const gate = document.getElementById("gate");
  const app = document.getElementById("app");
  const tokenInput = document.getElementById("tokenInput");
  const gateError = document.getElementById("gateError");
  const loadError = document.getElementById("loadError");
  const meta = document.getElementById("meta");
  const startDate = document.getElementById("startDate");
  const endDate = document.getElementById("endDate");
  const presets = document.getElementById("presets");
  const sidebar = document.getElementById("sidebar");
  const scrim = document.getElementById("scrim");
  const pageTitle = document.getElementById("pageTitle");

  let charts = {};
  let currentView = "engagement";
  const VIEW_TITLES = {
    engagement: "Engajamento",
    performance: "Performance",
    ai: "IA",
    support: "Suporte",
    notifications: "Notificações",
  };

  // Sem animação no resize: evita o gráfico aparecer comprimido enquanto redesenha.
  Chart.defaults.animation.duration = 400;
  Chart.defaults.transitions.resize.animation.duration = 0;

  function getToken() {
    return localStorage.getItem(TOKEN_KEY) || "";
  }
  function setToken(token) {
    localStorage.setItem(TOKEN_KEY, token);
  }
  function clearToken() {
    localStorage.removeItem(TOKEN_KEY);
  }

  function showGate(message) {
    app.hidden = true;
    gate.hidden = false;
    if (message) {
      gateError.hidden = false;
      gateError.textContent = message;
    } else {
      gateError.hidden = true;
      gateError.textContent = "";
    }
  }

  function showApp() {
    gate.hidden = true;
    app.hidden = false;
    window.scrollTo(0, 0);
  }

  /* ---------------- Date helpers ---------------- */
  function toInputValue(date) {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, "0");
    const d = String(date.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }

  function parseInputValue(value) {
    const [y, m, d] = value.split("-").map(Number);
    return new Date(y, (m || 1) - 1, d || 1);
  }

  // 00:00 local do dia (início inclusivo)
  function startOfDayISO(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).toISOString();
  }
  // 00:00 local do dia seguinte (fim exclusivo -> inclui o dia "Até" inteiro)
  function endExclusiveISO(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1).toISOString();
  }

  function setRangeDays(days) {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - (days - 1));
    startDate.value = toInputValue(start);
    endDate.value = toInputValue(end);
  }

  function initRange() {
    setRangeDays(30);
  }

  function highlightPreset() {
    const start = parseInputValue(startDate.value);
    const end = parseInputValue(endDate.value);
    const isToday = toInputValue(end) === toInputValue(new Date());
    const days = Math.round((end - start) / 86400000) + 1;
    presets.querySelectorAll(".chip").forEach((chip) => {
      const match = isToday && Number(chip.dataset.days) === days;
      chip.classList.toggle("active", match);
    });
  }

  /* ---------------- Formatting ---------------- */
  function formatDuration(sec) {
    const s = Math.round(Number(sec) || 0);
    if (s < 60) return `${s}s`;
    const m = Math.floor(s / 60);
    const r = s % 60;
    return r ? `${m}m ${r}s` : `${m}m`;
  }

  function destroyCharts() {
    Object.values(charts).forEach((c) => c.destroy());
    charts = {};
  }

  function escapeHtml(text) {
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function tipBadge(text, tip) {
    return `<span class="tip" tabindex="0" data-tip="${escapeHtml(tip)}">${escapeHtml(text)}</span>`;
  }

  function kpi(label, value, tip, { acronym, hero, foot } = {}) {
    const badge = acronym
      ? ` ${tipBadge(acronym, tip)}`
      : tip
        ? ` ${tipBadge("?", tip)}`
        : "";
    const footHtml = foot ? `<p class="foot">${escapeHtml(foot)}</p>` : "";
    return `<div class="kpi${hero ? " hero" : ""}"><p class="label">${escapeHtml(label)}${badge}</p><p class="value">${escapeHtml(value)}</p>${footHtml}</div>`;
  }

  function renderOverview(data) {
    const o = data.overview;
    const activationPct =
      o.signups > 0 ? Math.round((1000 * o.activated) / o.signups) / 10 : 0;
    const onboardingPct =
      o.signups > 0
        ? Math.round((1000 * o.onboardingComplete) / o.signups) / 10
        : 0;

    document.getElementById("kpis").innerHTML = [
      kpi("Cadastros", o.signups, "Quantas pessoas criaram conta no período selecionado.", {
        hero: true,
        foot: "No período selecionado",
      }),
      kpi(
        "Completaram o perfil",
        o.onboardingComplete,
        "Preencheram dados do onboarding (peso, altura, objetivo, etc.).",
        { foot: `${onboardingPct}% dos cadastros` },
      ),
      kpi(
        "Já usaram de verdade",
        o.activated,
        "Salvaram pelo menos 1 refeição. É o sinal de que começaram a usar o produto.",
        { foot: `${activationPct}% de ativação` },
      ),
      kpi(
        "Ativos hoje",
        o.dauToday,
        "DAU = Daily Active Users. Pessoas distintas que abriram o app hoje (horário de Brasília).",
        { acronym: "DAU", foot: "Horário de Brasília" },
      ),
    ].join("");
  }

  function renderRetention(data) {
    const r = data.retention;
    document.getElementById("retentionCards").innerHTML = `
      <div class="ret-card">
        <span class="ret-label">
          Dia seguinte
          ${tipBadge("D1", "D1 = Day 1. Percentual que voltou no dia seguinte ao cadastro.")}
        </span>
        <strong>${r.d1.pct}%</strong>
        <small>${r.d1.users} de ${r.cohortSize} pessoas</small>
      </div>
      <div class="ret-card">
        <span class="ret-label">
          Após 7 dias
          ${tipBadge("D7", "D7 = Day 7. Percentual que voltou 7 dias depois do cadastro.")}
        </span>
        <strong>${r.d7.pct}%</strong>
        <small>${r.d7.users} de ${r.cohortSize} pessoas</small>
      </div>
      <div class="ret-card">
        <span class="ret-label">
          Após 14 dias
          ${tipBadge("D14", "D14 = Day 14. Percentual que voltou 14 dias depois do cadastro.")}
        </span>
        <strong>${r.d14.pct}%</strong>
        <small>${r.d14.users} de ${r.cohortSize} pessoas</small>
      </div>
    `;
  }

  function renderSessions(data) {
    const s = data.sessions;
    document.getElementById("sessionStats").innerHTML = `
      <div>
        <span>
          Visitas
          ${tipBadge("?", "Quantas vezes o app foi aberto (sessões) no período.")}
        </span>
        <strong>${s.visits}</strong>
      </div>
      <div>
        <span>
          Média
          ${tipBadge("?", "Tempo médio com o app aberto por visita.")}
        </span>
        <strong>${formatDuration(s.avgSec)}</strong>
      </div>
      <div>
        <span>
          Mediana
          ${tipBadge("?", "Valor do meio: metade das visitas durou menos, metade durou mais. Menos distorcido por outliers.")}
        </span>
        <strong>${formatDuration(s.medianSec)}</strong>
      </div>
    `;
  }

  function renderFeatureTable(data) {
    const tbody = document.querySelector("#featureTable tbody");
    tbody.innerHTML = data.featureRetention
      .map(
        (row) => `
      <tr>
        <td>${escapeHtml(row.feature)}</td>
        <td>${row.usedFeature ? "Sim" : "Não"}</td>
        <td>${row.users}</td>
        <td>${row.retainedD7}</td>
        <td><strong>${row.pctD7}%</strong></td>
      </tr>`,
      )
      .join("");
  }

  const EVENT_LABELS = {
    app_open: "Abriu o app",
    meal_saved: "Salvou refeição",
    meal_capture_started: "Começou a fotografar",
    ai_analyze_succeeded: "IA analisou a comida",
    ai_analyze_failed: "IA falhou na análise",
    screen_view: "Viu uma tela",
    onboarding_complete: "Concluiu o perfil",
    session_end: "Encerrou sessão",
    session_start: "Iniciou sessão",
  };

  function friendlyEventName(name) {
    return EVENT_LABELS[name] || name;
  }

  function renderEventsTable(data) {
    const tbody = document.querySelector("#eventsTable tbody");
    tbody.innerHTML = data.eventCounts
      .map(
        (row) => `
      <tr>
        <td>
          ${escapeHtml(friendlyEventName(row.eventName))}
          <code class="event-code" title="Nome técnico do evento">${escapeHtml(row.eventName)}</code>
        </td>
        <td>${row.count}</td>
      </tr>`,
      )
      .join("");
  }

  function lineChart(id, labels, values, color) {
    const ctx = document.getElementById(id);
    charts[id] = new Chart(ctx, {
      type: "line",
      data: {
        labels,
        datasets: [
          {
            data: values,
            borderColor: color,
            backgroundColor: color + "22",
            fill: true,
            tension: 0.4,
            pointRadius: 0,
            pointHoverRadius: 4,
            borderWidth: 2.5,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: "#99a1af", font: { size: 11, family: "Inter" } },
            border: { display: false },
          },
          y: {
            beginAtZero: true,
            ticks: { precision: 0, color: "#99a1af", font: { size: 11, family: "Inter" } },
            grid: { color: "#eef1ec" },
            border: { display: false },
          },
        },
      },
    });
  }

  const TICK_FONT = { size: 11, family: "Inter" };

  function barChart(id, labels, values, color) {
    const horizontal = labels.length > 5;
    const valueAxis = {
      beginAtZero: true,
      ticks: { precision: 0, color: "#99a1af", font: TICK_FONT },
      grid: { color: "#eef1ec" },
      border: { display: false },
    };
    const categoryAxis = {
      ticks: {
        color: "#99a1af",
        font: TICK_FONT,
        autoSkip: false,
        callback(index) {
          const label = String(this.getLabelForValue(index));
          return label.length > 18 ? `${label.slice(0, 17)}…` : label;
        },
      },
      grid: { display: false },
      border: { display: false },
    };

    charts[id] = new Chart(document.getElementById(id), {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            data: values,
            backgroundColor: color,
            borderRadius: 6,
            borderSkipped: false,
            maxBarThickness: horizontal ? 16 : 36,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: horizontal ? "y" : "x",
        layout: { padding: { right: 4 } },
        plugins: { legend: { display: false } },
        scales: horizontal
          ? { x: valueAxis, y: categoryAxis }
          : { x: categoryAxis, y: valueAxis },
      },
    });
  }

  function doughnutChart(id, labels, values) {
    const ctx = document.getElementById(id);
    charts[id] = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels,
        datasets: [
          {
            data: values,
            backgroundColor: ["#0f5132", "#166534", "#22c55e", "#86efac", "#dcfce7"],
            borderWidth: 0,
            hoverOffset: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "62%",
        plugins: {
          legend: {
            position: "right",
            labels: {
              boxWidth: 8,
              boxHeight: 8,
              usePointStyle: true,
              pointStyle: "circle",
              padding: 10,
              font: TICK_FONT,
              color: "#6a7282",
            },
          },
        },
      },
    });
  }

  const FUNNEL_LABELS = {
    Signups: "Cadastrou",
    "Onboarding completo": "Completou o perfil",
    "Iniciou captura": "Começou a fotografar",
    "IA analisou": "IA analisou a comida",
    "Salvou refeição": "Salvou a refeição",
  };

  function friendlyFunnelStep(step) {
    return FUNNEL_LABELS[step] || step;
  }

  function renderCharts(data) {
    destroyCharts();
    lineChart(
      "dauChart",
      data.dauSeries.map((d) => d.day.slice(5)),
      data.dauSeries.map((d) => d.dau),
      "#0f5132",
    );
    barChart(
      "funnelChart",
      data.funnel.map((d) => friendlyFunnelStep(d.step)),
      data.funnel.map((d) => d.users),
      "#0f5132",
    );
    const topScreens = data.topScreens.slice(0, 8);
    barChart(
      "screensChart",
      topScreens.map((d) => d.screen.replace(/^\//, "")),
      topScreens.map((d) => d.views),
      "#22c55e",
    );
    doughnutChart(
      "platformChart",
      data.platforms.map((d) => d.platform || "outro"),
      data.platforms.map((d) => d.users),
    );
  }

  function multiLineChart(id, labels, series) {
    charts[id] = new Chart(document.getElementById(id), {
      type: "line",
      data: {
        labels,
        datasets: series.map((s) => ({
          label: s.label,
          data: s.values,
          borderColor: s.color,
          backgroundColor: s.color + "22",
          fill: false,
          tension: 0.35,
          pointRadius: 0,
          pointHoverRadius: 4,
          borderWidth: 2.5,
        })),
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: "bottom",
            labels: {
              boxWidth: 8,
              usePointStyle: true,
              pointStyle: "circle",
              font: TICK_FONT,
              color: "#6a7282",
            },
          },
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: "#99a1af", font: TICK_FONT },
            border: { display: false },
          },
          y: {
            beginAtZero: true,
            ticks: { precision: 0, color: "#99a1af", font: TICK_FONT },
            grid: { color: "#eef1ec" },
            border: { display: false },
          },
        },
      },
    });
  }

  function formatMs(ms) {
    const n = Number(ms) || 0;
    if (n < 1000) return `${Math.round(n)}ms`;
    return `${(n / 1000).toFixed(1)}s`;
  }

  function formatUptime(sec) {
    const s = Math.max(0, Math.round(Number(sec) || 0));
    const d = Math.floor(s / 86400);
    const h = Math.floor((s % 86400) / 3600);
    const m = Math.floor((s % 3600) / 60);
    if (d > 0) return `${d}d ${h}h`;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  }

  function shortBucket(bucket) {
    const raw = String(bucket || "");
    if (raw.length >= 16) return raw.slice(5, 16);
    return raw.slice(5);
  }

  function formatQuotaNumber(n) {
    const value = Number(n) || 0;
    if (value >= 1000) return value.toLocaleString("pt-BR");
    return String(value);
  }

  function quotaTone(pct) {
    if (pct >= 90) return "danger";
    if (pct >= 70) return "warn";
    return "ok";
  }

  function quotaMeter(label, used, limit, pct) {
    const tone = quotaTone(pct);
    return `
      <div class="quota-meter">
        <div class="quota-meter-top">
          <span>${escapeHtml(label)}</span>
          <strong>${formatQuotaNumber(used)} / ${formatQuotaNumber(limit)}</strong>
        </div>
        <div class="quota-track" aria-hidden="true">
          <div class="quota-fill tone-${tone}" style="width:${Math.min(100, pct)}%"></div>
        </div>
        <small>${pct}% usado</small>
      </div>
    `;
  }

  function renderAiQuotas(quotas) {
    const grid = document.getElementById("aiQuotaGrid");
    const hint = document.getElementById("aiQuotaHint");
    if (!grid) return;

    if (!quotas?.models?.length) {
      grid.innerHTML = `<p class="quota-empty">Cotas indisponíveis neste ambiente.</p>`;
      return;
    }

    if (hint) {
      hint.textContent =
        quotas.note ||
        "RPM / TPM (último minuto) e RPD (hoje, fuso Pacific).";
    }

    grid.innerHTML = quotas.models
      .map((row) => {
        return `
          <div class="quota-card">
            <header>
              <h3>${escapeHtml(row.label || row.model)}</h3>
              <code>${escapeHtml(row.model)}</code>
            </header>
            ${quotaMeter("RPM", row.rpm.used, row.rpm.limit, row.rpm.pct)}
            ${quotaMeter("TPM", row.tpm.used, row.tpm.limit, row.tpm.pct)}
            ${quotaMeter("RPD", row.rpd.used, row.rpd.limit, row.rpd.pct)}
          </div>
        `;
      })
      .join("");
  }

  function renderPerformance(data) {
    const ai = data.ai.overview;
    const support = data.support.overview;
    const infra = data.infra || {
      live: {},
      overview: {},
      series: [],
      concurrentSeries: [],
    };
    const live = infra.live || {};
    const infraOverview = infra.overview || {};

    document.getElementById("infraKpis").innerHTML = [
      kpi(
        "CPU agora",
        live.cpuPct == null ? "—" : `${live.cpuPct}%`,
        "Uso de CPU do host visto de dentro do container (última amostra).",
        {
          hero: true,
          foot: `média ${infraOverview.avgCpuPct || 0}% · pico ${infraOverview.maxCpuPct || 0}%`,
        },
      ),
      kpi(
        "RAM agora",
        live.memUsedPct == null ? "—" : `${live.memUsedPct}%`,
        "Memória do sistema em uso. RSS = memória do processo Nest.",
        {
          foot: `Nest ${live.processRssMb || 0} MB · pico ${infraOverview.maxMemPct || 0}%`,
        },
      ),
      kpi(
        "Uptime do processo",
        formatUptime(live.processUptimeSec),
        "Tempo desde o último start/deploy do Nest. Host uptime é o da máquina/container.",
        { foot: `host ${formatUptime(live.hostUptimeSec)}` },
      ),
      kpi(
        "Simultâneos agora",
        live.concurrentUsers ?? 0,
        "Usuários distintos com heartbeat nos últimos ~3 minutos.",
        {
          foot: `${live.concurrentSessions || 0} sessões · pico ${infraOverview.maxConcurrentUsers || 0}`,
        },
      ),
      kpi(
        "Disponibilidade",
        `${infraOverview.availabilityPct || 0}%`,
        "Horas do período com amostra de infra. Gaps = restart, deploy ou queda.",
        {
          foot: `${infraOverview.hoursWithSample || 0}/${infraOverview.expectedHours || 0} horas com sinal`,
        },
      ),
    ].join("");

    document.getElementById("infraLiveStats").innerHTML = `
      <div>
        <span>Load 1m</span>
        <strong>${live.loadAvg1m ?? "—"}</strong>
      </div>
      <div>
        <span>RAM host</span>
        <strong>${live.memUsedMb || 0}/${live.memTotalMb || 0} MB</strong>
      </div>
      <div>
        <span>Hostname</span>
        <strong style="font-size:13px">${escapeHtml(live.hostname || "—")}</strong>
      </div>
    `;

    document.getElementById("availabilityStats").innerHTML = `
      <div>
        <span>Cobertura</span>
        <strong>${infraOverview.availabilityPct || 0}%</strong>
      </div>
      <div>
        <span>Amostras</span>
        <strong>${infraOverview.samples || 0}</strong>
      </div>
      <div>
        <span>Pico simultâneos</span>
        <strong>${infraOverview.maxConcurrentUsers || 0}</strong>
      </div>
    `;

    document.getElementById("perfKpis").innerHTML = [
      kpi("Chamadas de IA", ai.requested, "Pedidos de análise enviados ao backend no período.", {
        hero: true,
        foot: `${ai.uniqueUsers} usuários distintos`,
      }),
      kpi(
        "Taxa de erro",
        `${ai.errorRatePct}%`,
        "Percentual de análises que falharam entre sucessos + falhas.",
        { foot: `${ai.failed} falhas · ${ai.succeeded} ok` },
      ),
      kpi(
        "Latência p95",
        formatMs(ai.p95LatencyMs),
        "95% das análises terminaram em até esse tempo (inclui cache).",
        { foot: `p50 ${formatMs(ai.p50LatencyMs)} · média ${formatMs(ai.avgLatencyMs)}` },
      ),
      kpi(
        "Tokens consumidos",
        ai.totalTokens.toLocaleString("pt-BR"),
        "Total de tokens informados pelo provedor nas chamadas novas.",
        { foot: `${ai.cacheHitRatePct}% atendidas pelo cache` },
      ),
    ].join("");

    renderAiQuotas(data.ai?.quotas);

    document.getElementById("supportKpis").innerHTML = [
      kpi(
        "Acionamentos",
        support.total,
        "Total de mensagens enviadas pelo canal de suporte no período.",
        { hero: true, foot: "Bugs + sugestões" },
      ),
      kpi(
        "Bugs reportados",
        support.bugs,
        "Mensagens de suporte classificadas como bug.",
        { foot: `${support.total ? Math.round((1000 * support.bugs) / support.total) / 10 : 0}% dos acionamentos` },
      ),
      kpi(
        "Sugestões",
        support.suggestions,
        "Ideias e melhorias enviadas pelos usuários.",
        { foot: `${support.total ? Math.round((1000 * support.suggestions) / support.total) / 10 : 0}% dos acionamentos` },
      ),
    ].join("");

    document.getElementById("supportStats").innerHTML = `
      <div>
        <span>Total</span>
        <strong>${support.total}</strong>
      </div>
      <div>
        <span>Bugs</span>
        <strong>${support.bugs}</strong>
      </div>
      <div>
        <span>Sugestões</span>
        <strong>${support.suggestions}</strong>
      </div>
    `;

    const modelsBody = document.querySelector("#aiModelsTable tbody");
    modelsBody.innerHTML = data.ai.models.length
      ? data.ai.models
          .map(
            (row) => `
        <tr>
          <td><code>${escapeHtml(row.model)}</code></td>
          <td>${row.calls}</td>
          <td>${row.succeeded}</td>
          <td>${row.failed}</td>
          <td>${row.errorRatePct}%</td>
          <td>${formatMs(row.avgLatencyMs)}</td>
          <td>${row.totalTokens.toLocaleString("pt-BR")}</td>
        </tr>`,
          )
          .join("")
      : `<tr><td colspan="7">Sem dados de modelo no período. Chamadas novas já registram o modelo (legado = eventos antigos sem essa info).</td></tr>`;

    const errorsBody = document.querySelector("#aiErrorsTable tbody");
    errorsBody.innerHTML = data.ai.errors.length
      ? data.ai.errors
          .map(
            (row) => `
        <tr>
          <td><code>${escapeHtml(row.errorCode)}</code></td>
          <td>${row.count}</td>
        </tr>`,
          )
          .join("")
      : `<tr><td colspan="2">Nenhuma falha de IA no período.</td></tr>`;

    const supportBody = document.querySelector("#supportTable tbody");
    supportBody.innerHTML = data.support.recent.length
      ? data.support.recent
          .map((row) => {
            const when = new Date(row.createdAt).toLocaleString("pt-BR");
            const who = row.userName || row.contactEmail || "anônimo";
            const typeLabel = row.subjectType === "bug" ? "Bug" : "Sugestão";
            const desc =
              row.description.length > 140
                ? `${row.description.slice(0, 139)}…`
                : row.description;
            return `
        <tr>
          <td>${escapeHtml(when)}</td>
          <td><span class="pill ${row.subjectType === "bug" ? "pill-bug" : "pill-ok"}">${typeLabel}</span></td>
          <td>${escapeHtml(who)}</td>
          <td>${escapeHtml(desc)}</td>
        </tr>`;
          })
          .join("")
      : `<tr><td colspan="4">Nenhum acionamento de suporte no período.</td></tr>`;

    destroyCharts();

    if (currentView === "performance") {
      const infraSeries = infra.series || [];
      multiLineChart(
        "infraResourceChart",
        infraSeries.map((d) => shortBucket(d.bucket)),
        [
          {
            label: "CPU %",
            values: infraSeries.map((d) => d.cpuPct),
            color: "#0f5132",
          },
          {
            label: "RAM %",
            values: infraSeries.map((d) => d.memUsedPct),
            color: "#166534",
          },
        ],
      );

      const concurrentSeries = infra.concurrentSeries || [];
      // Série temporal: lineChart (barChart vira horizontal com >5 labels).
      lineChart(
        "concurrentChart",
        concurrentSeries.map((d) => shortBucket(d.bucket)),
        concurrentSeries.map((d) => d.peak),
        "#22c55e",
      );
    }

    if (currentView === "ai") {
      multiLineChart(
        "aiSeriesChart",
        data.ai.series.map((d) => d.day.slice(5)),
        [
          {
            label: "Pedidos",
            values: data.ai.series.map((d) => d.requested),
            color: "#0f5132",
          },
          {
            label: "Sucesso",
            values: data.ai.series.map((d) => d.succeeded),
            color: "#22c55e",
          },
          {
            label: "Falhas",
            values: data.ai.series.map((d) => d.failed),
            color: "#fb2c36",
          },
        ],
      );

      const modelRows = data.ai.models
        .filter((m) => m.model !== "cache")
        .slice(0, 8);
      const chartModels = modelRows.length
        ? modelRows
        : data.ai.models.slice(0, 8);
      barChart(
        "aiModelsChart",
        chartModels.map((d) => d.model),
        chartModels.map((d) => d.calls),
        "#166534",
      );
    }
  }

  function setView(view) {
    currentView = VIEW_TITLES[view] ? view : "engagement";
    pageTitle.textContent = VIEW_TITLES[currentView];

    document.querySelectorAll("[data-view-panel]").forEach((panel) => {
      panel.hidden = panel.dataset.viewPanel !== currentView;
    });

    sidebar.querySelectorAll(".nav-item[data-view]").forEach((item) => {
      item.classList.toggle("active", item.dataset.view === currentView);
    });

    if (location.hash.replace("#", "") !== currentView) {
      history.replaceState(null, "", `#${currentView}`);
    }
  }

  function rangeParams(token) {
    let start = parseInputValue(startDate.value);
    let end = parseInputValue(endDate.value);
    if (start > end) {
      const tmp = startDate.value;
      startDate.value = endDate.value;
      endDate.value = tmp;
      start = parseInputValue(startDate.value);
      end = parseInputValue(endDate.value);
    }
    highlightPreset();

    const betaStart = startOfDayISO(start);
    const betaEnd = endExclusiveISO(end);
    const days = Math.round((end - start) / 86400000) + 1;

    return new URLSearchParams({
      days: String(days),
      betaStart,
      betaEnd,
      token,
    });
  }

  async function fetchDashboard(path, token) {
    const params = rangeParams(token);
    const base = analyticsApiBase(path);
    const url = `${base}/analytics/${path}?${params.toString()}`;
    const res = await fetch(url, {
      headers: { "x-dashboard-token": token },
    });
    if (res.status === 401) {
      clearToken();
      let detail = "Token inválido.";
      try {
        const body = await res.json();
        if (body?.message) detail = body.message;
      } catch (_) {
        /* ignore */
      }
      const hint =
        base === cloudApiBase
          ? " Use o token de produção (AWS), não o de desenvolvimento local."
          : "";
      showGate(`${detail}${hint}`);
      return null;
    }
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    const data = await res.json();
    const rangeStartLabel = startDate.value
      ? parseInputValue(startDate.value).toLocaleDateString("pt-BR")
      : new Date(data.range.betaStart).toLocaleDateString("pt-BR");
    const rangeEndLabel = endDate.value
      ? parseInputValue(endDate.value).toLocaleDateString("pt-BR")
      : new Date(data.range.betaEnd).toLocaleDateString("pt-BR");
    meta.textContent = `Atualizado em ${new Date(data.generatedAt).toLocaleString("pt-BR")} · período ${rangeStartLabel} → ${rangeEndLabel}`;
    return data;
  }

  function channelLabel(channel) {
    if (channel === "email") return "E-mail";
    if (channel === "both") return "Caixa + e-mail";
    return "Só caixa";
  }

  function renderBroadcastHistory(rows) {
    const tbody = document.querySelector("#broadcastTable tbody");
    if (!tbody) return;
    tbody.innerHTML = rows.length
      ? rows
          .map((row) => {
            const when = new Date(row.createdAt).toLocaleString("pt-BR");
            const emailSummary =
              row.channel === "inbox"
                ? "—"
                : `${row.emailSentCount || 0} ok · ${row.emailFailedCount || 0} falha`;
            return `<tr>
              <td>${escapeHtml(when)}</td>
              <td>${escapeHtml(channelLabel(row.channel))}</td>
              <td>${escapeHtml(row.title || "")}</td>
              <td>${row.recipientCount ?? 0}</td>
              <td>${escapeHtml(emailSummary)}</td>
            </tr>`;
          })
          .join("")
      : `<tr><td colspan="5">Nenhum aviso enviado ainda.</td></tr>`;
  }

  async function loadNotifications() {
    loadError.hidden = true;
    const token = getToken();
    if (!token) {
      showGate();
      return;
    }

    try {
      const res = await fetch(`${apiBase}/notifications/broadcasts?limit=50`, {
        headers: { "x-dashboard-token": token },
      });
      if (res.status === 401) {
        clearToken();
        showGate("Token inválido.");
        return;
      }
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }
      const rows = await res.json();
      showApp();
      setView("notifications");
      renderBroadcastHistory(Array.isArray(rows) ? rows : []);
      meta.textContent = `Notificações · ${Array.isArray(rows) ? rows.length : 0} envios recentes`;
    } catch (err) {
      loadError.hidden = false;
      loadError.textContent = `Falha ao carregar notificações: ${err.message}`;
    }
  }

  async function loadDashboard() {
    loadError.hidden = true;
    const token = getToken();
    if (!token) {
      showGate();
      return;
    }

    try {
      if (currentView === "notifications") {
        await loadNotifications();
        return;
      }
      if (currentView !== "engagement") {
        const data = await fetchDashboard("performance", token);
        if (!data) return;
        showApp();
        setView(currentView);
        renderPerformance(data);
      } else {
        const data = await fetchDashboard("dashboard", token);
        if (!data) return;
        showApp();
        setView("engagement");
        renderOverview(data);
        renderRetention(data);
        renderSessions(data);
        renderFeatureTable(data);
        renderEventsTable(data);
        renderCharts(data);
      }
    } catch (err) {
      loadError.hidden = false;
      loadError.textContent = `Falha ao carregar métricas: ${err.message}`;
    }
  }

  /* ---------------- Sidebar (mobile) ---------------- */
  function openSidebar() {
    sidebar.classList.add("open");
    scrim.hidden = false;
  }
  function closeSidebar() {
    sidebar.classList.remove("open");
    scrim.hidden = true;
  }

  /* ---------------- Wiring ---------------- */
  document.getElementById("unlockBtn").addEventListener("click", () => {
    const token = tokenInput.value.trim();
    if (!token) {
      gateError.hidden = false;
      gateError.textContent = "Informe o token.";
      return;
    }
    setToken(token);
    loadDashboard();
  });

  document.getElementById("applyRangeBtn").addEventListener("click", loadDashboard);
  document.getElementById("logoutBtn").addEventListener("click", () => {
    clearToken();
    showGate();
  });

  startDate.addEventListener("change", highlightPreset);
  endDate.addEventListener("change", highlightPreset);

  presets.addEventListener("click", (e) => {
    const chip = e.target.closest(".chip");
    if (!chip) return;
    setRangeDays(Number(chip.dataset.days));
    loadDashboard();
  });

  document.getElementById("menuBtn").addEventListener("click", openSidebar);
  scrim.addEventListener("click", closeSidebar);

  sidebar.querySelectorAll(".nav-item[data-view]").forEach((item) => {
    item.addEventListener("click", (e) => {
      e.preventDefault();
      const view = item.dataset.view;
      if (!view || view === currentView) {
        if (window.innerWidth <= 820) closeSidebar();
        return;
      }
      setView(view);
      loadDashboard();
      if (window.innerWidth <= 820) closeSidebar();
    });
  });

  sidebar.querySelectorAll(".nav-item.logout").forEach((item) => {
    item.addEventListener("click", () => {
      if (window.innerWidth <= 820) closeSidebar();
    });
  });

  const broadcastForm = document.getElementById("broadcastForm");
  if (broadcastForm) {
    broadcastForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      const token = getToken();
      if (!token) {
        showGate();
        return;
      }

      const title = document.getElementById("broadcastTitle").value.trim();
      const body = document.getElementById("broadcastBody").value.trim();
      const channelInput = broadcastForm.querySelector(
        'input[name="channel"]:checked',
      );
      const channel = channelInput ? channelInput.value : "inbox";
      const statusEl = document.getElementById("broadcastStatus");
      const submitBtn = document.getElementById("broadcastSubmit");

      statusEl.hidden = true;
      statusEl.classList.remove("error");
      submitBtn.disabled = true;
      submitBtn.textContent = "Enviando…";

      try {
        const res = await fetch(`${apiBase}/notifications/broadcasts`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-dashboard-token": token,
          },
          body: JSON.stringify({ title, body, channel }),
        });
        if (res.status === 401) {
          clearToken();
          showGate("Token inválido.");
          return;
        }
        const data = await res.json().catch(() => ({}));
        if (!res.ok) {
          const msg = Array.isArray(data?.message)
            ? data.message.join(" ")
            : data?.message || `HTTP ${res.status}`;
          throw new Error(msg);
        }

        broadcastForm.reset();
        const inboxRadio = broadcastForm.querySelector(
          'input[name="channel"][value="inbox"]',
        );
        if (inboxRadio) inboxRadio.checked = true;

        statusEl.hidden = false;
        statusEl.textContent = `Enviado para ${data.recipientCount ?? 0} usuários (${channelLabel(data.channel)}).`;
        await loadNotifications();
      } catch (err) {
        statusEl.hidden = false;
        statusEl.classList.add("error");
        statusEl.textContent = `Falha ao enviar: ${err.message}`;
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = "Enviar para todos";
      }
    });
  }

  tokenInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") document.getElementById("unlockBtn").click();
  });

  initRange();
  const hashView = location.hash.replace("#", "");
  if (VIEW_TITLES[hashView]) {
    setView(hashView);
  } else {
    setView("engagement");
  }
  if (getToken()) {
    loadDashboard();
  }
})();
