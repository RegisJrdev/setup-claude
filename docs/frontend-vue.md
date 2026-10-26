# Convenções da web (código novo)

Vale para funcionalidades novas. Telas legadas não são refatoradas. Módulo de referência mais recente: Diário de Atendimentos (`src/Pages/DiarioAtendimentos/`, `src/router/diarioAtendimentos.js`, `src/Services/AtendimentosService.js`).

## Estrutura de um módulo

| O quê | Onde | Exemplo |
|---|---|---|
| Lista | `src/Pages/<Dominio>/index.vue` | `src/Pages/DiarioAtendimentos/Atendimentos/index.vue` |
| Formulário criar/editar | `src/Pages/<Dominio>/NewEdit<Entidade>Page.vue` | `src/Pages/DiarioAtendimentos/Atendimentos/NewEditAtendimentoPage.vue` |
| Componentes do domínio | `src/components/<Dominio>/` | `src/components/Colaboradores/` |
| Service | `src/Services/<Plural>Service.js` + `src/Services/index.js` | `src/Services/AtendimentosService.js` |
| Rotas | `src/router/<dominio>.js` (camelCase) + spread em `src/router/index.js` | `src/router/diarioAtendimentos.js` |

Pastas e nomes em português, componentes e páginas em PascalCase.

## Service

```js
import Axios from "@/plugins/Axios";

export class AtendimentosService {
  async syncAll(query = null) {
    const response = await Axios().get("atendimentos", { params: { query } });
    return response.data;
  }

  async criar(payload) {
    const response = await Axios().post("atendimentos", payload);
    return response.data;
  }
}

export default new AtendimentosService();
```

- Métodos: `syncAll`, `find`, `criar`, `atualizar`, `deletar` (+ verbos de negócio, ex.: `confirmar`).
- Devolve `response.data` (a API não envolve em `data`; ver `docs/api-contract.md`).
- Download/PDF: `responseType: "arraybuffer"` ou `"blob"`; o interceptor já decodifica erro 404 em ArrayBuffer.

## Componente / página

Fluxo padrão de ação assíncrona:

```js
async salvar() {
  try {
    this.$loaderService.open("Salvando");
    await this.$services.atendimentosService.criar(this.form);
    this.$toast.success("Atendimento salvo com sucesso");
    this.$router.push({ name: "diarioAtendimentos" });
  } catch (error) {
    this.$handleError(error);
  } finally {
    this.$loaderService.close();
  }
}
```

- Formulário: `ValidationObserver` + `ValidationProvider` (vee-validate 3, regras globais e customizadas em `src/plugins/veeValidate.js`, como `no_special_chars`).
- Confirmação destrutiva: `this.$modals.danger(...)` / `this.$modals.warn(...)` (`src/plugins/EModals.js`).
- Paginação: componente `<e-paginate>` alimentado pelo paginator da API (`current_page`, `last_page`). Ex.: `src/Pages/Disciplinas/index.vue`.
- Componente compartilhado novo: prefixo `E`, registro global em `src/plugins/components.js`. Antes de criar, procure lá (há duplicatas no legado, ex.: `src/components/EmodalConfirm.vue` e `src/components/EModalConfirmacao.vue`).
- `<style scoped>`.
- Sem `console.log` em código commitado.

## Rotas e permissões

- Nome de rota pontuado: `<modulo>.<tela>`, ex.: `diarioAtendimentos.tipos`.
- Guard de permissão com `can()` de `src/plugins/can.js`, redirecionando para `NaoAutorizado`, como `exigirPermissao` em `src/router/diarioAtendimentos.js`.
- Menu/botões: `$can(["recurso.acao", "recurso.*"])` (array = basta ter uma). Os nomes são os mesmos do middleware `can:` da API.
- Não use `user.roleName ===` nem ids fixos (há `943` hardcoded no legado: `src/router/guards/semPermissao.js`).

## Vuex

- Módulo namespaced em `src/store/modules/<Entidade>.js` (ex.: `src/store/modules/Turmas.js`), acesso via `mapGetters`/`mapActions`.
- Tudo no Vuex vai para localStorage. Prefira estado local da página para listas e formulários; use Vuex só para o que é compartilhado entre telas.
