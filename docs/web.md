# Web: regras do produto

Leia antes de qualquer mudança em `../<municipio>-web`. Depois, leia `municipios/<municipio>/web.md` (particularidades do município).

Front-end Vue 2.7 (Options API, JS puro) + Vuetify 2 + Vuex 3 + vee-validate 3.

## Comandos (yarn)
- Dev: `yarn serve`. Build: `yarn build --mode develop|homologacao|production` (modo escolhe o `.env.<modo>`).
- Testes: `yarn test:unit` (Jest 24, `tests/unit/**/*.spec.js`).
- Lint: `yarn lint --no-fix`. Sem `--no-fix` o vue-cli reescreve arquivos.

## Regras inegociáveis (código novo)
- Options API (`export default {}`), sem composition API, sem TypeScript, sem mixins.
- Chamada HTTP só via service: classe em `src/Services/<Plural>Service.js` usando `Axios()` de `src/plugins/Axios.js`, registrada em `src/Services/index.js` e usada como `this.$services.<nome>Service`. Nunca axios direto no componente.
- Query string via `{ params }`, nunca montada à mão na URL.
- Erro: `try/catch` com `this.$handleError(error)`. Loading global: `this.$loaderService.open()/close()`.
- Toast: `this.$toast.success|danger|warn|info`. **`$toast.error` não existe** (há usos quebrados no legado).
- Permissão: rota com guard `can()`, tela/menu com `$can([...])`. Mesmos nomes de permissão da API. Não cheque `roleName` nem id de usuário em código novo.
- Nunca use sintaxe de Vue 3, Vuetify 3, vee-validate 4, Vuex 4 ou vue-router 4.
- Não refatore telas legadas: só a mudança pedida.

## Armadilhas
- `VUE_APP_API_HOST` termina com `/` e não tem `/api`: paths de service são relativos (`"atendimentos"`), e concatenações como `${VUE_APP_API_HOST}storage/...` dependem da barra.
- O store inteiro é persistido em localStorage (`src/store/index.js`, `createPersistedState`). Não guarde listas grandes no Vuex.
- Componentes `E*` são globais (`src/plugins/components.js`); componente compartilhado novo é registrado lá.
- `.env*` são versionados: não coloque segredo neles.

## Docs sob demanda
- Ao criar página, componente, service, rota ou módulo Vuex: `docs/frontend-vue.md`
- Ao escrever ou rodar testes: `docs/testes.md` (seção Web)
- Ao consumir endpoint (resposta, erro, paginação, auth): `docs/api-contract.md`
- Versão instalada de pacote: `../<municipio>-web/node_modules/<pacote>/package.json`
