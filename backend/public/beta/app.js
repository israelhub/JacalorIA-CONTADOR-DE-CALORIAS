(() => {
  const TOKEN_KEY = "jacaloria_beta_dashboard_token";
  const apiBase = `${window.location.origin}/api`;

  const gate = document.getElementById("gate");
  const app = document.getElementById("app");
  const tokenInput = document.getElementById("tokenInput");
  const gateError = document.getElementById("gateError");
  const loadError = document.getElementById("loadError");
  const meta = document.getElementById("meta");
  const daysSelect = document.getElementById("daysSelect");

  let charts = {};

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

  function kpi(label, value, tip, acronym) {
    const badge = acronym
      ? ` ${tipBadge(acronym, tip)}`
      : tip
        ? ` ${tipBadge("?", tip)}`
        : "";
    return `<div class="kpi"><p class="label">${escapeHtml(label)}${badge}</p><p class="value">${escapeHtml(value)}</p></div>`;
  }

  function renderOverview(data) {
    const o = data.overview;
    const s = data.sessions;
    document.getElementById("kpis").innerHTML = [
      kpi(
        "Cadastros",
        o.signups,
        "Quantas pessoas criaram conta no período selecionado.",
      ),
      kpi(
        "Completaram o perfil",
        o.onboardingComplete,
        "Preencheram dados do onboarding (peso, altura, objetivo, etc.).",
      ),
      kpi(
        "Já usaram de verdade",
        o.activated,
        "Salvaram pelo menos 1 refeição. É o sinal de que começaram a usar o produto.",
      ),
      kpi(
        "Ativos hoje",
        o.dauToday,
        "DAU = Daily Active Users. Pessoas distintas que abriram o app hoje (horário de Brasília).",
        "DAU",
      ),
      kpi(
        "Ativos na semana",
        o.wau,
        "WAU = Weekly Active Users. Pessoas distintas que abriram o app nos últimos 7 dias.",
        "WAU",
      ),
      kpi(
        "Ativos nos últimos 7 dias",
        o.active7d,
        "Pessoas com atividade recente (abriu o app ou last_active nos últimos 7 dias).",
      ),
      kpi(
        "Tempo médio por visita",
        formatDuration(s.avgSec),
        "Média de tempo com o app aberto em cada visita.",
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
            backgroundColor: color + "33",
            fill: true,
            tension: 0.35,
            pointRadius: 3,
          },
        ],
      },
      options: {
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, ticks: { precision: 0 } },
        },
      },
    });
  }

  function barChart(id, labels, values, color) {
    const ctx = document.getElementById(id);
    charts[id] = new Chart(ctx, {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            data: values,
            backgroundColor: color,
            borderRadius: 8,
          },
        ],
      },
      options: {
        indexAxis: labels.length > 5 ? "y" : "x",
        plugins: { legend: { display: false } },
        scales: {
          x: { beginAtZero: true, ticks: { precision: 0 } },
          y: { beginAtZero: true, ticks: { precision: 0 } },
        },
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
            backgroundColor: ["#7CBF4D", "#E3B640", "#1E513E", "#CFF2BA", "#F08A24"],
          },
        ],
      },
      options: {
        plugins: { legend: { position: "bottom" } },
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
      "#1E513E",
    );
    barChart(
      "funnelChart",
      data.funnel.map((d) => friendlyFunnelStep(d.step)),
      data.funnel.map((d) => d.users),
      "#7CBF4D",
    );
    barChart(
      "screensChart",
      data.topScreens.map((d) => d.screen),
      data.topScreens.map((d) => d.views),
      "#E3B640",
    );
    doughnutChart(
      "platformChart",
      data.platforms.map((d) => d.platform),
      data.platforms.map((d) => d.users),
    );
  }

  async function loadDashboard() {
    loadError.hidden = true;
    const token = getToken();
    const days = daysSelect.value;
    const url = `${apiBase}/analytics/dashboard?days=${encodeURIComponent(days)}&token=${encodeURIComponent(token)}`;

    try {
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
        showGate(
          `${detail} Use o token de produção (AWS), não o de desenvolvimento local.`,
        );
        return;
      }
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }
      const data = await res.json();
      showApp();
      meta.textContent = `Atualizado em ${new Date(data.generatedAt).toLocaleString("pt-BR")} · período ${new Date(data.range.betaStart).toLocaleDateString("pt-BR")} → ${new Date(data.range.betaEnd).toLocaleDateString("pt-BR")}`;
      renderOverview(data);
      renderRetention(data);
      renderSessions(data);
      renderFeatureTable(data);
      renderEventsTable(data);
      renderCharts(data);
    } catch (err) {
      loadError.hidden = false;
      loadError.textContent = `Falha ao carregar métricas: ${err.message}`;
    }
  }

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

  document.getElementById("refreshBtn").addEventListener("click", loadDashboard);
  daysSelect.addEventListener("change", loadDashboard);
  document.getElementById("logoutBtn").addEventListener("click", () => {
    clearToken();
    showGate();
  });

  tokenInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") document.getElementById("unlockBtn").click();
  });

  if (getToken()) {
    loadDashboard();
  }
})();
