# agent-toolkit

Instruções para agentes de código (Claude Code) compartilhadas pelos sistemas municipais. Nada fica dentro dos repos de app.

## Setup (uma vez por município)

```text
<MUNICIPIO>/
├── agent-toolkit/      ← este repo; abra o Claude Code aqui
├── <municipio>-api/
└── <municipio>-web/
```

```bash
cd <MUNICIPIO>
git clone <url>/agent-toolkit.git
cd agent-toolkit && ./setup.sh <municipio>   # ex.: ./setup.sh vera-mendes
claude
```

Atualizar: `git pull` no `agent-toolkit`.

## Organização

| Onde | O quê |
|---|---|
| `AGENTS.md` | Regras comuns e quando usar `dev-api`/`dev-web`, sempre carregadas |
| `docs/api.md`, `docs/web.md` | Regras de cada repo, lidas antes de mexer nele (fonte única: agentes e `AGENTS.md` apontam para cá) |
| `docs/` (demais) | Docs detalhadas, lidas sob demanda (gatilhos em `docs/api.md`/`docs/web.md`) |
| `municipios/<municipio>/contexto.md` | Domínio e regras de negócio (API + Web), sempre carregado |
| `municipios/<municipio>/api.md`, `web.md` | Particularidades técnicas de cada repo, lidas junto com `docs/api.md`/`docs/web.md` |
| `municipios/<municipio>/docs/` | Docs de módulo e ADRs do município |
| `.claude/skills/` | Procedimentos reutilizáveis |
| `.claude/hooks/exigir-regras.sh` | Bloqueia edição em `../*-api`/`../*-web` até o agente (principal ou subagente) ler `docs/api.md`/`docs/web.md` na sessão. Não cobre edição via Bash |
| `.claude/hooks/docs-check.sh` | Ao final, avisa se arquivo de padrão mudou nos repos sem atualizar o toolkit |
| `.claude/agents/` | Subagentes `dev-api`, `dev-web`: papel e escopo; as regras eles leem de `docs/api.md`/`docs/web.md` |
| `CLAUDE.local.md` (gerado) | Seleciona o município deste clone |

Regra: só sobe para `AGENTS.md`/`docs/` o que vale para todos os municípios. Na dúvida, fica em `municipios/<municipio>/`.

Os agentes em `.claude/agents/` não repetem nem contradizem o `AGENTS.md` e as `docs/`: regra mora em arquivo, agente só aponta. Ao mudar uma regra, revise os agentes no mesmo commit.

O conteúdo inicial foi extraído de Vera Mendes. Os exemplos de arquivo em `docs/` (ex.: `FeriadoController`) só foram confirmados lá: ao adicionar o segundo município, mova para `municipios/` o que divergir.

## Município novo

1. Crie `municipios/<municipio>/` com `contexto.md`, `api.md` e `web.md` (use `municipios/vera-mendes/` como modelo).
2. Rode `./setup.sh <municipio>` no clone daquele município.
