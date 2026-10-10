---
name: ux-copy-desafios
description: >-
  Escreve microcopy de regras de desafio e competição social do Jacaloria
  (o que fazer + como ganhar). Use when writing or editing challenge rules,
  competition type helper text, socialCompetitionRule, getCompetitionRule,
  descrições de tipo de competição, ou copy introdutória de desafios em grupo.
---

# Microcopy de desafios

Texto de regra fica **embaixo do nome do tipo**.

Na criação do grupo, cada tipo aparece como opção com nome + as duas frases. No detalhe, a regra fica abaixo do nome no card do grupo. Não vai no card da lista.

## Fórmula

Duas frases curtas:

1. O que a pessoa faz
2. Como se ganha (ou o risco, se for coletivo)

Sem fórmula, jargão interno, nem detalhe de implementação.

## Não fazer

- Técnico: `A média é o total de calorias ÷ dias decorridos...`
- Didático demais: `O desafio olha o seu ritmo no período todo, não um dia isolado.`
- Slogan seco: `Ganha quem ficar mais perto da sua meta.`
- Jargão: ofensiva, dias decorridos, membros ativos, meia-noite
- Caveats que a UI já mostra: "desde que o grupo começou", prazo

## Aprovado

```
offensive:
Registre as refeições todos os dias. Ganha quem mantiver a sequência mais longa.

daily_goal:
Tente bater a sua meta de calorias todo dia. Ganha quem acertar mais vezes.

goal_average:
Acompanhe sua meta de calorias ao longo do desafio. Ganha quem ficar mais perto.

xp:
Complete missões para ganhar XP. Ganha quem juntar mais pontos.

group_streak:
Todos precisam registrar as refeições no dia. Se alguém pular, o desafio acaba.
```

## Onde alterar

Manter o mesmo texto nos dois lados:

- `frontend/lib/features/social/helpers/social_group_helpers.dart` (`socialCompetitionRule`)
- `backend/src/social/social.service.ts` (`getCompetitionRule`)

Atualizar fixtures/testes que copiam a string (`social_group_card_test`, `social_page_test`, `social_create_group_sheet_test`, `main_showcase`).
