# Contrato API ↔ web (rascunho)

Contrato entre a API e a Web, comum aos municípios. Caminhos relativos ao toolkit. Estado observado em Vera Mendes em 2026-10-23. `TODO:` = não confirmado ou a decidir.

## Base

- A web usa `VUE_APP_API_HOST` (raiz da API, com `/` no final, sem `/api`). Ex.: `GET {host}atendimentos`.
- Rotas por domínio: `../<municipio>-api/routes/<dominio>.php`, prefixadas em `../<municipio>-api/app/Providers/RouteServiceProvider.php`.
- JSON em todas as respostas, exceto PDF/planilha (binário).

## Autenticação (Sanctum, token)

1. `GET sanctum/csrf-cookie` (a web chama, mas o fluxo é por token).
2. `POST login` com `email`, `password`, `device_name` → `{ user_id, access_token, token_type, expires_at }`.
   - O login **apaga todos os tokens anteriores** do usuário: uma sessão ativa por usuário.
   - As permissões do usuário viram `abilities` do token no momento do login.
3. Requisições: `Authorization: Bearer <access_token>`. A web guarda o token em `localStorage.access_token`.
4. `GET current-user` → usuário com `permissions` (abilities do token), `roles`, `franquia`, `ano`.
5. `GET logout`.

- Validade do token: `../<municipio>-api/config/sanctum.php` (valor atual ~150 dias, o comentário diz 12h). TODO: confirmar intenção.
- A web desloga ao receber 401 (`../<municipio>-web/src/plugins/Axios.js`).
- Logins separados para apps: `login-aluno`, `login-notifiq`, `v1/.../login` (Mobile). TODO: documentar quando necessário.

## Permissões

- API: middleware `can:perm1,perm2` (`../<municipio>-api/app/Http/Middleware/Can.php`) passa se o token tiver qualquer uma.
- Web: `$can([...])` (`../<municipio>-web/src/plugins/can.js`) compara com `current-user.permissions`.
- `recurso.*` é um nome de permissão literal (não é curinga): rotas aceitam `recurso.acao` **ou** `recurso.*`.
- Permissão nova só chega ao usuário após novo login.

## Sucesso

- Código novo: model ou array cru, sem envelope `data`.
  - 200 leitura/atualização, 201 criação, 204 exclusão (corpo vazio).
- Legado: varia (às vezes `{ message }`, às vezes `response.data.data`). Leia o controller antes de consumir.
- Mobile V1 (`app/Http/Controllers/Mobile/V1`): `{ success, message, ... }`.

## Paginação

Paginator padrão do Laravel, sem envelope:

```json
{ "current_page": 1, "data": [...], "last_page": 5, "per_page": 10, "total": 48, "...": "links do Laravel" }
```

A web usa `current_page` e `last_page` no `<e-paginate>`. Parâmetros: `page` e filtros via query string (`query`). TODO: padronizar nome dos filtros e `per_page`.

## Erros

Formato comum (legado e Handler):

```json
{ "error": { "message": "texto pt-BR", "status": 403, "type": "PermissionsException", "timestamp": "..." } }
```

| Status | Origem | Observação |
|---|---|---|
| 401 | `app/Exceptions/Handler.php` | web mostra "Sua sessão expirou" e desloga |
| 403 | `Can` middleware / `abort(403)` | web mostra `error.message` |
| 404 | `findOrFail` / `abort(404)` | |
| 422 | FormRequest | Laravel: `{ message, errors: { campo: [..] } }`. **Em produção (`APP_DEBUG=false`) o Handler converte em 500** com `{ error: {...} }`. TODO: corrigir no Handler e definir se a web deve exibir `errors` por campo (hoje só mostra a mensagem). |
| 500 | `respondWithError` / Handler | inclui `file` e `line` (vazamento). TODO: remover. |

A web lê a mensagem por `error.message || error.error.message` (`../<municipio>-web/src/plugins/handleError.js`). Toda mensagem de erro de negócio deve vir em pt-BR no campo `message`.

## Arquivos

- Imagens e anexos servidos por `{host}storage/...` ou rotas específicas em `../<municipio>-api/routes/api.php`.
- PDF: gerado sob demanda (snappy/wkhtmltopdf); a web pede `responseType: arraybuffer|blob`.
