#!/usr/bin/env python3
"""Gera figuras do Capítulo 4.2 (Metodologia de software) do TCC JacalorIA."""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle
from matplotlib.path import Path as MplPath
import matplotlib.patches as mpatches

OUT = Path(__file__).resolve().parent / "figuras"
OUT.mkdir(parents=True, exist_ok=True)

NAVY = "#1B365D"
TEAL = "#2A6F7F"
GOLD = "#C4A35A"
SLATE = "#4A5568"
LIGHT = "#F4F6F8"
BOX = "#FFFFFF"
EDGE = "#1B365D"
ACCENT = "#3D7A4C"
SOFT = "#E8EEF4"
ORANGE = "#C05621"

plt.rcParams.update(
    {
        "font.family": "DejaVu Sans",
        "font.size": 9,
        "axes.unicode_minus": False,
        "figure.facecolor": "white",
        "savefig.facecolor": "white",
        "savefig.dpi": 220,
        "pdf.fonttype": 42,
    }
)


def rounded(ax, x, y, w, h, text, fc=BOX, ec=EDGE, lw=1.4, fontsize=8.5, color=NAVY, weight="medium", va="center"):
    patch = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.012,rounding_size=0.04",
        facecolor=fc,
        edgecolor=ec,
        linewidth=lw,
        zorder=3,
    )
    ax.add_patch(patch)
    ax.text(
        x + w / 2,
        y + h / 2,
        text,
        ha="center",
        va=va,
        fontsize=fontsize,
        color=color,
        weight=weight,
        zorder=4,
        wrap=True,
        linespacing=1.25,
    )
    return patch


def arrow(ax, x1, y1, x2, y2, color=NAVY, style="-|>", lw=1.3, rad=0):
    ax.annotate(
        "",
        xy=(x2, y2),
        xytext=(x1, y1),
        arrowprops=dict(
            arrowstyle=style,
            color=color,
            lw=lw,
            connectionstyle=f"arc3,rad={rad}",
            shrinkA=0,
            shrinkB=0,
        ),
        zorder=2,
    )


def save(fig, name):
    png = OUT / f"{name}.png"
    pdf = OUT / f"{name}.pdf"
    fig.savefig(png, bbox_inches="tight", pad_inches=0.18)
    fig.savefig(pdf, bbox_inches="tight", pad_inches=0.18)
    plt.close(fig)
    print(f"ok {png.name}")


def fig_dsr_adr():
    fig, ax = plt.subplots(figsize=(11.2, 6.4))
    ax.set_xlim(0, 11.2)
    ax.set_ylim(0, 6.4)
    ax.axis("off")

    ax.add_patch(Rectangle((0.25, 0.35), 10.7, 5.75, facecolor=LIGHT, edgecolor="none", zorder=0))
    ax.text(5.6, 5.85, "Integração entre Design Science Research e Action Design Research", ha="center", fontsize=12, color=NAVY, weight="bold")

    stages = [
        (0.5, 3.9, "1. Identificação\ndo problema"),
        (2.7, 3.9, "2. Objetivos\nda solução"),
        (4.9, 3.9, "3. Projeto e\ndesenvolvimento"),
        (7.1, 3.9, "4. Demonstração\ndo artefato"),
        (9.3, 3.9, "5. Avaliação e\ncomunicação"),
    ]
    ax.text(5.6, 5.25, "Ciclo DSR (Peffers et al., 2007)", ha="center", fontsize=10, color=TEAL, weight="bold")
    for i, (x, y, t) in enumerate(stages):
        rounded(ax, x, y, 1.9, 1.15, t, fc="#DCE8F2", fontsize=8)
        if i < len(stages) - 1:
            arrow(ax, x + 1.9, y + 0.57, stages[i + 1][0], y + 0.57)

    # feedback arrow
    ax.annotate(
        "",
        xy=(1.45, 3.9),
        xytext=(10.25, 3.9),
        arrowprops=dict(
            arrowstyle="-|>",
            color=GOLD,
            lw=1.2,
            connectionstyle="arc3,rad=0.42",
        ),
    )
    ax.text(5.6, 3.55, "refinamento iterativo do artefato", ha="center", fontsize=7.5, color=GOLD, style="italic")

    ax.text(5.6, 3.15, "Ciclos BIE do ADR (Sein et al., 2011) aplicados ao JacalorIA", ha="center", fontsize=10, color=TEAL, weight="bold")

    bie = [
        (0.7, 1.15, "Formulação\ndo problema", "Atrito no registro\nalimentar digital"),
        (3.15, 1.15, "Construção\n(Building)", "Artefato JacalorIA:\nIA + TACO + app"),
        (5.6, 1.15, "Intervenção\n(Intervention)", "Uso por 30 dias\ncom 20 participantes"),
        (8.05, 1.15, "Avaliação e\naprendizado", "Logs, questionário\ne reflexão formal"),
    ]
    for i, (x, y, title, sub) in enumerate(bie):
        rounded(ax, x, y, 2.2, 1.55, f"{title}\n\n{sub}", fc="#F7F1E3", fontsize=8)
        if i < len(bie) - 1:
            arrow(ax, x + 2.2, y + 0.77, bie[i + 1][0], y + 0.77)

    save(fig, "figura-dsr-adr")


def fig_etapas():
    fig, ax = plt.subplots(figsize=(11.2, 5.8))
    ax.set_xlim(0, 11.2)
    ax.set_ylim(0, 5.8)
    ax.axis("off")

    ax.text(5.6, 5.4, "Etapas do desenvolvimento do JacalorIA (execução iterativa)", ha="center", fontsize=12, color=NAVY, weight="bold")
    ax.text(
        5.6,
        5.05,
        "As etapas clássicas da engenharia de software foram percorridas em ciclos incrementais, e não em uma única passagem sequencial.",
        ha="center",
        fontsize=8,
        color=SLATE,
    )

    steps = [
        "Planejamento",
        "Análise de\nrequisitos",
        "Diagramas",
        "Design",
        "Codificação",
        "Testes",
        "Deploy",
    ]
    xs = [0.35 + i * 1.55 for i in range(7)]
    for i, (x, title) in enumerate(zip(xs, steps)):
        rounded(ax, x, 3.15, 1.4, 1.35, f"{i+1}\n{title}", fc="#DCE8F2", fontsize=8.5, weight="bold")
        if i < 6:
            arrow(ax, x + 1.4, 3.82, xs[i + 1], 3.82)

    # cycle
    ax.annotate(
        "",
        xy=(1.05, 3.15),
        xytext=(10.15, 3.15),
        arrowprops=dict(arrowstyle="-|>", color=GOLD, lw=1.4, connectionstyle="arc3,rad=0.55"),
    )
    ax.text(5.6, 2.55, "novo ciclo a cada incremento (auth, refeições, IA/TACO, gamificação, social, infra)", ha="center", fontsize=8, color=GOLD, style="italic")

    increments = [
        (0.4, 0.45, "Incremento 1\nContas, perfil e\nmetas calóricas"),
        (3.1, 0.45, "Incremento 2\nRegistro de refeições\ne reconhecimento IA"),
        (5.8, 0.45, "Incremento 3\nMissões, loja,\nstreak e social"),
        (8.5, 0.45, "Incremento 4\nCI/CD, produção e\nrefinos de UX"),
    ]
    for x, y, t in increments:
        rounded(ax, x, y, 2.3, 1.55, t, fc="#F7F1E3", fontsize=8)

    save(fig, "figura-etapas-desenvolvimento")


def fig_arquitetura():
    fig, ax = plt.subplots(figsize=(12.4, 8.4))
    ax.set_xlim(0, 12.4)
    ax.set_ylim(0, 8.4)
    ax.axis("off")
    ax.text(6.2, 8.1, "Arquitetura lógica do JacalorIA", ha="center", fontsize=13, color=NAVY, weight="bold")

    # Client layer
    ax.add_patch(FancyBboxPatch((0.25, 6.15), 11.9, 1.75, boxstyle="round,pad=0.02,rounding_size=0.05", fc="#EAF3EA", ec=ACCENT, lw=1.2))
    ax.text(0.45, 7.65, "Camada de apresentação — Flutter (Android, iOS e Web)", fontsize=9, color=ACCENT, weight="bold", ha="left")
    clients = [
        (0.5, 6.35, "Autenticação\ne onboarding"),
        (2.55, 6.35, "Início e\nrefeições"),
        (4.6, 6.35, "Captura e\nanálise IA"),
        (6.65, 6.35, "Missões\ne loja"),
        (8.7, 6.35, "Social e\nranking"),
        (10.55, 6.35, "Desempenho\ne perfil"),
    ]
    for x, y, t in clients:
        rounded(ax, x, y, 1.85, 1.15, t, fc="white", ec=ACCENT, fontsize=8)

    arrow(ax, 6.2, 6.15, 6.2, 5.55)

    # API
    ax.add_patch(FancyBboxPatch((0.25, 3.55), 11.9, 2.0, boxstyle="round,pad=0.02,rounding_size=0.05", fc="#E7EEF6", ec=NAVY, lw=1.2))
    ax.text(0.45, 5.28, "Camada de aplicação — API REST NestJS (prefixo /api, JWT)", fontsize=9, color=NAVY, weight="bold", ha="left")
    mods = [
        "auth",
        "ai",
        "meals",
        "missions",
        "social",
        "performance",
        "notifications",
        "analytics",
    ]
    for i, m in enumerate(mods):
        x = 0.5 + (i % 8) * 1.45
        y = 4.45 if i < 8 else 3.7
        rounded(ax, x, 3.75, 1.35, 1.25, f"Módulo\n{m}", fc="white", fontsize=8)

    # arrows down
    for x in (2.2, 6.2, 10.2):
        arrow(ax, x, 3.55, x, 2.95)

    # Data / AI / storage
    boxes = [
        (0.35, 0.45, 3.7, 2.45, TEAL, "#E5F2F4", "Dados e persistência", "PostgreSQL (Supabase)\nSequelize + migrações SQL\nTabela TACO (4ª edição)\nCache de análises (SHA-256)"),
        (4.35, 0.45, 3.7, 2.45, GOLD, "#F7F1E3", "Inteligência Artificial", "Google Gemini (visão)\nCadeia de fallback\nEnriquecimento TACO\nProvedor desacoplado"),
        (8.35, 0.45, 3.7, 2.45, ORANGE, "#F8EDE6", "Armazenamento e e-mail", "Supabase Storage\n(avatars, meals, chat)\nNodemailer (verificação)\nAnalytics de uso"),
    ]
    for x, y, w, h, ec, fc, title, body in boxes:
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.05", fc=fc, ec=ec, lw=1.3))
        ax.text(x + w / 2, y + h - 0.32, title, ha="center", fontsize=9, color=ec, weight="bold")
        ax.text(x + w / 2, y + h / 2 - 0.15, body, ha="center", va="center", fontsize=8, color=NAVY, linespacing=1.45)

    save(fig, "figura-arquitetura-logica")


def fig_implantacao():
    fig, ax = plt.subplots(figsize=(12.2, 7.2))
    ax.set_xlim(0, 12.2)
    ax.set_ylim(0, 7.2)
    ax.axis("off")
    ax.text(6.1, 6.9, "Arquitetura de implantação do JacalorIA", ha="center", fontsize=13, color=NAVY, weight="bold")

    # User
    rounded(ax, 0.35, 3.15, 1.8, 1.2, "Usuário\n(navegador ou\napp Flutter)", fc="#EAF3EA", ec=ACCENT, fontsize=8.5)

    arrow(ax, 2.15, 3.75, 3.15, 3.75)

    # CloudFront
    rounded(ax, 3.15, 2.85, 2.5, 1.8, "Amazon CloudFront\njacaloria.online\n\nHTTPS  •  HTTP/2-3\n/*  →  S3\n/api/*  →  backend", fc="#DCE8F2", fontsize=8)

    # split arrows
    arrow(ax, 5.65, 4.2, 7.0, 5.35)
    arrow(ax, 5.65, 3.25, 7.0, 2.15)

    rounded(ax, 7.0, 4.85, 2.55, 1.55, "Amazon S3\n(Flutter Web)\n\nbucket privado\n+ OAC", fc="#EAF3EA", ec=ACCENT, fontsize=8.5)
    rounded(ax, 7.0, 1.35, 2.55, 1.7, "Elastic Beanstalk\n(Docker / NestJS)\n\nimagem no ECR\ninstância t3.micro", fc="#E7EEF6", fontsize=8.5)

    arrow(ax, 9.55, 5.6, 10.55, 5.6)
    arrow(ax, 9.55, 2.2, 10.55, 3.35)
    arrow(ax, 9.55, 1.85, 10.55, 1.55)

    rounded(ax, 10.55, 5.15, 1.4, 0.95, "GitHub\nActions\n(CI/CD)", fc="#F7F1E3", ec=GOLD, fontsize=8)
    rounded(ax, 10.55, 2.85, 1.4, 1.15, "Supabase\nPostgreSQL\n+ Storage", fc="#F8EDE6", ec=ORANGE, fontsize=8)
    rounded(ax, 10.55, 0.95, 1.4, 1.15, "Google\nGemini\n(visão)", fc="#F7F1E3", ec=GOLD, fontsize=8)

    # CI legend
    rounded(ax, 0.35, 0.4, 6.3, 1.55, "Pipeline de deploy (push em main)\nFrontend: flutter build web  →  S3  →  invalidação CloudFront\nBackend: Docker multi-stage  →  ECR  →  Elastic Beanstalk\nAutenticação AWS via OIDC (sem chaves estáticas)", fc=LIGHT, ec=SLATE, fontsize=8, color=SLATE)

    save(fig, "figura-arquitetura-implantacao")


def fig_fluxo_ia():
    fig, ax = plt.subplots(figsize=(12.4, 8.6))
    ax.set_xlim(0, 12.4)
    ax.set_ylim(0, 8.6)
    ax.axis("off")
    ax.text(6.2, 8.3, "Fluxo de reconhecimento alimentar com IA e tabela TACO", ha="center", fontsize=13, color=NAVY, weight="bold")

    # Client column
    ax.add_patch(FancyBboxPatch((0.25, 0.35), 3.55, 7.7, boxstyle="round,pad=0.02,rounding_size=0.05", fc="#EAF3EA", ec=ACCENT, lw=1.1))
    ax.text(2.02, 7.8, "Cliente Flutter", ha="center", fontsize=10, color=ACCENT, weight="bold")

    client_steps = [
        (0.5, 6.55, "1. Captura\ncâmera, galeria, texto\nou refeição salva"),
        (0.5, 5.15, "2. Otimização da imagem\n≤ 1920 px  •  JPEG 90%"),
        (0.5, 3.75, "3. POST /ai/food/analyze\nJWT  •  imageBase64\nou manualText"),
        (0.5, 2.2, "4. Revisão humana\nedita itens e porções"),
        (0.5, 0.6, "5. Recalcula + persiste\nfoto no Storage\nrefeição no PostgreSQL"),
    ]
    for x, y, t in client_steps:
        rounded(ax, x, y, 3.05, 1.25, t, fc="white", ec=ACCENT, fontsize=8)
        if y != 0.6:
            pass
    for y1, y2 in ((6.55, 6.4),):
        pass
    arrow(ax, 2.02, 6.55, 2.02, 6.4)
    arrow(ax, 2.02, 5.15, 2.02, 5.0)
    arrow(ax, 2.02, 3.75, 2.02, 3.45)
    arrow(ax, 2.02, 2.2, 2.02, 1.85)

    # Server
    ax.add_patch(FancyBboxPatch((4.05, 0.35), 8.1, 7.7, boxstyle="round,pad=0.02,rounding_size=0.05", fc="#E7EEF6", ec=NAVY, lw=1.1))
    ax.text(8.1, 7.8, "Backend NestJS  •  módulo ai", ha="center", fontsize=10, color=NAVY, weight="bold")

    rounded(ax, 4.3, 6.45, 3.55, 1.15, "Cache por usuário + SHA-256\nda imagem (food_image_analyses)", fc="white", fontsize=8)
    rounded(ax, 8.15, 6.45, 3.75, 1.15, "Miss: Gemini Flash (visão)\ncadeia de fallback + timeout 55 s", fc="#F7F1E3", ec=GOLD, fontsize=8)

    arrow(ax, 3.55, 4.35, 4.3, 7.0)
    arrow(ax, 7.85, 7.02, 8.15, 7.02)

    rounded(ax, 4.3, 4.55, 7.6, 1.5, "Saída da IA: itens (nome, gramas, kcal, macros) + justificativa\nO modelo descreve o prato brasileiro com preparo e corte (ex.: Arroz branco cozido)", fc="white", fontsize=8.2)

    arrow(ax, 8.1, 6.45, 8.1, 6.05)

    rounded(ax, 4.3, 2.55, 7.6, 1.7, "Enriquecimento nutricional (FoodNutritionRagService)\nPrioridade:  rótulo informado  →  correspondência TACO (limiar 0,58)  →  decomposição de receita  →  estimativa da IA\nCálculo:  (valor por 100 g da TACO × gramas estimadas) / 100", fc="#F7F1E3", ec=GOLD, fontsize=8)

    arrow(ax, 8.1, 4.55, 8.1, 4.25)

    rounded(ax, 4.3, 0.55, 3.55, 1.65, "Tabela TACO 4ª edição\nenergia_kcal, proteina_g,\ncarboidrato_g, lipideos_g", fc="#F8EDE6", ec=ORANGE, fontsize=8)
    rounded(ax, 8.15, 0.55, 3.75, 1.65, "Resposta ao cliente\nitems[], totals, source,\nmatchedFood, justification", fc="white", fontsize=8)

    arrow(ax, 8.1, 2.55, 8.1, 2.2)
    arrow(ax, 3.55, 1.2, 4.3, 1.2)

    save(fig, "figura-fluxo-reconhecimento")


def fig_casos_uso():
    fig, ax = plt.subplots(figsize=(11.6, 7.4))
    ax.set_xlim(0, 11.6)
    ax.set_ylim(0, 7.4)
    ax.axis("off")
    ax.text(5.8, 7.1, "Diagrama de casos de uso do JacalorIA (visão consolidada)", ha="center", fontsize=12.5, color=NAVY, weight="bold")

    # system box
    ax.add_patch(FancyBboxPatch((2.15, 0.45), 7.3, 6.25, boxstyle="round,pad=0.02,rounding_size=0.04", fc=LIGHT, ec=NAVY, lw=1.3))
    ax.text(5.8, 6.4, "JacalorIA", ha="center", fontsize=11, color=NAVY, weight="bold")

    uses = [
        (2.5, 5.35, "Autenticar-se e completar onboarding"),
        (2.5, 4.55, "Registrar refeição por foto, texto ou modelo"),
        (2.5, 3.75, "Revisar e confirmar análise nutricional"),
        (2.5, 2.95, "Acompanhar metas, peso e desempenho"),
        (2.5, 2.15, "Cumprir missões e usar a loja"),
        (2.5, 1.35, "Interagir com amigos, grupos e ranking"),
        (2.5, 0.55, "Receber lembretes e mensagens in-app"),
    ]
    for x, y, t in uses:
        rounded(ax, x, y, 6.6, 0.68, t, fc="white", fontsize=8.5)

    # actors
    rounded(ax, 0.2, 3.15, 1.75, 1.3, "Usuário\nautenticado", fc="#EAF3EA", ec=ACCENT, fontsize=8.5)
    rounded(ax, 9.65, 4.55, 1.75, 1.2, "Gemini\n(visão)", fc="#F7F1E3", ec=GOLD, fontsize=8.5)
    rounded(ax, 9.65, 2.55, 1.75, 1.2, "Tabela\nTACO", fc="#F8EDE6", ec=ORANGE, fontsize=8.5)
    rounded(ax, 9.65, 0.7, 1.75, 1.2, "Serviços\nde nuvem", fc="#E7EEF6", fontsize=8.5)

    arrow(ax, 1.95, 3.8, 2.5, 5.7, rad=0.12)
    arrow(ax, 1.95, 3.8, 2.5, 1.7, rad=-0.08)
    arrow(ax, 9.1, 4.05, 9.65, 5.15)
    arrow(ax, 9.1, 4.05, 9.65, 3.15)
    arrow(ax, 9.1, 0.9, 9.65, 1.3)

    save(fig, "figura-casos-de-uso")


if __name__ == "__main__":
    fig_dsr_adr()
    fig_etapas()
    fig_arquitetura()
    fig_implantacao()
    fig_fluxo_ia()
    fig_casos_uso()
    print("Figuras geradas em", OUT)
