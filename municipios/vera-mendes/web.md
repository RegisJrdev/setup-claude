# Vera Mendes: Web (`../vera-mendes-web`)

- Push em `veramendes-**` faz deploy automático no servidor de dev (`.github/workflows/develop.yml`); `homologacao` e `main` também fazem deploy.
- Node: CI usa 16.x. Não há `.nvmrc`. CI não roda testes nem lint.
- Lint: TODO: existem duas configs ESLint em conflito (`package.json` airbnb x `src/.eslintrc.js` prettier); não use lint como critério até o time decidir.
- `yarn.lock` está no `.gitignore` e `yalc.lock` aponta para pacote local de outra máquina (`vuetify-snackbar-toast`). Instalação pode divergir.
- Módulo de referência mais recente: Diário de Atendimentos (`src/Pages/DiarioAtendimentos/`, `src/router/diarioAtendimentos.js`, `src/Services/AtendimentosService.js`).
- Id `943` hardcoded no legado (`src/router/guards/semPermissao.js`): não replique.
