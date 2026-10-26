# Presença no Notifiq

## Visão Geral

Página de acompanhamento em tempo real das presenças registradas pelo sistema Hikvision (controle de acesso biométrico/facial). Exibe todos os eventos de entrada e saída do dia atual agrupados por escola e turma, com atualização automática a cada 15 segundos.

---

## Fluxo Geral

```
[Menu lateral] → /notifiq/presencas
    ↓
[IndexNotifiq.vue] mounted()
    ↓
refresh({ silent: false })
    ↓
PresencasService.listPresencasNotifiq()
    GET /notifiq/presencas
    ↓
[RouteServiceProvider] prefix: notifiq/presencas
    middleware: auth:sanctum + can:notifiq.listaPresencasNotifiq
    ↓
NotifiqPresencasController@index()
    ↓
NotifiqPresencasService@index()
    SELECT presencas_hikvision WHERE DATE(data_evento) = hoje
    JOIN matriculas → alunos, turmas, configuracoes
    GROUP BY escola → turma → aluno
    ↓
JSON → Vue atualiza escolas[], totais, timestamps

startPolling() → setInterval(15s) → refresh({ silent: true }) → repete
```

---

## Frontend

### Rota Vue

**Arquivo:** `../vera-mendes-web/src/router/notifiq.js`

```js
{
  path: "/notifiq/presencas",
  name: "notifiq.indexNotifiq",
  title: "Presença Notifiq",
  component: IndexNotifiq,
}
```

**Menu lateral** (`src/components/ELeftMenu.vue`):

```js
{ title: "Presença no Notifiq", to: { name: "notifiq.indexNotifiq" } }
```

---

### Página

**Arquivo:** `../vera-mendes-web/src/Pages/Notifiq/IndexNotifiq.vue`

#### Constante de polling

```js
const POLLING_INTERVAL = 15000; // 15 segundos
```

#### Estado (`data`)

| Propriedade | Tipo | Descrição |
|---|---|---|
| `loading` | Boolean | Exibe loader no primeiro carregamento |
| `refreshing` | Boolean | Exibe loading no botão "Atualizar agora" |
| `poller` | Number/null | ID do `setInterval` do polling |
| `escolas` | Array | Lista de escolas com turmas e alunos |
| `date` | String/null | Data do relatório (`YYYY-MM-DD`) |
| `generatedAt` | String/null | Timestamp da última geração |
| `totalEventos` | Number | Total de eventos Hikvision do dia |
| `totalEscolas` | Number | Escolas com movimento hoje |
| `totalTurmas` | Number | Turmas com movimento hoje |
| `openPanels` | Array | Índices dos painéis de escola abertos |
| `turmaOpenPanels` | Object | Map `{ escola_id: [índices] }` dos painéis de turma |

#### Computed

| Propriedade | Descrição |
|---|---|
| `formattedDate` | `date` formatado como `dd/mm/aaaa` |
| `formattedGeneratedAt` | `generatedAt` formatado como `dd/mm/aaaa hh:mm:ss` |

#### Ciclo de vida

```
mounted()       → await refresh({ silent: false }) → startPolling()
beforeDestroy() → stopPolling()
```

#### Methods

**`goBack()`**
Redireciona para `acessoProfessor.home` se o usuário for professor, senão para `home`.

---

**`startPolling()`**
Inicia o `setInterval` de 15s chamando `refresh({ silent: true })`. Chama `stopPolling()` antes para evitar múltiplos intervalos.

**`stopPolling()`**
Limpa o `setInterval` armazenado em `poller`.

---

**`refresh({ silent })`**
Método central de atualização.

```
silent = false  → loading = true    (loader na tela inteira)
silent = true   → refreshing = true (loading no botão)

1. Chama presencasService.listPresencasNotifiq()
2. Atribui escolas, date, generatedAt, totalEventos, totalEscolas, totalTurmas
3. Na primeira carga (openPanels vazio), abre todos os painéis de escola
4. Para cada escola, se turmaOpenPanels[escola_id] ainda não existe,
   cria via $set abrindo todos os painéis de turma
5. Erros silenciosos são ignorados
6. Erros não-silenciosos disparam $handleError
```

---

**`formatDate(value)`**
Formata uma data para `pt-BR` (dd/mm/aaaa). Delega para `parseDateValue()`.

**`formatDateTime(value)`**
Formata data+hora para `pt-BR` (dd/mm/aaaa hh:mm:ss). Delega para `parseDateValue()`.

**`parseDateValue(value)`**
Converte string para objeto `Date` sem usar `new Date(string)` diretamente — evita deslocamento de timezone em datas no formato `YYYY-MM-DD`.

Suporta:
- Instância `Date` → retorna como está
- `YYYY-MM-DD` → `new Date(year, month-1, day, 0, 0, 0)`
- `YYYY-MM-DD HH:MM:SS` → `new Date(year, month-1, day, HH, MM, SS)`
- Outros formatos → `new Date(value)` como fallback

---

#### Estrutura do template

```
v-container
├── Cabeçalho
│   ├── Botão voltar + título "Presença no Notifiq"
│   ├── Chip: total_eventos eventos
│   └── Botão "Atualizar agora" (com :loading="refreshing")
│
├── Cards de resumo (4 colunas md)
│   ├── Data
│   ├── Última atualização
│   ├── Escolas com movimento
│   └── Turmas com movimento
│
└── v-card principal (:loading="loading")
    ├── Estado vazio (v-if="!loading && !escolas.length")
    │   └── ícone mdi-bell-off-outline + mensagem
    └── v-expansion-panels (escolas) [v-model="openPanels" multiple]
        └── v-expansion-panel (por escola)
            ├── Header: nome da escola + chip qtd turmas
            └── v-expansion-panels (turmas) [v-model="turmaOpenPanels[escola_id]" multiple]
                └── v-expansion-panel (por turma)
                    ├── Header: nome da turma + chip qtd eventos
                    └── v-list
                        └── v-list-item (por evento/aluno)
                            ├── avatar: verde mdi-check-circle (entrada)
                            │         azul-cinza mdi-exit-run (saída)
                            ├── nome + "ID {aluno_id} | Matrícula {matricula_id}"
                            └── chip Entrada/Saída + horário (formatDateTime)
```

---

### Service Frontend

**Arquivo:** `../vera-mendes-web/src/Services/PresencasService.js`

```js
async listPresencasNotifiq() {
  const response = await Axios().get("notifiq/presencas");
  return response.data;
}
```

---

## Backend

### Registro da rota

**Arquivo:** `../vera-mendes-api/app/Providers/RouteServiceProvider.php`

```php
Route::prefix('notifiq/presencas')
    ->middleware('api')
    ->middleware('auth:sanctum')
    ->namespace($this->namespace)
    ->group(base_path('routes/notifiq/presencas.php'));
```

**Arquivo de rotas:** `../vera-mendes-api/routes/notifiq/presencas.php`

```php
Route::get('/', [NotifiqPresencasController::class, 'index'])
    ->middleware('can:notifiq.listaPresencasNotifiq');
```

**Endpoint:** `GET /notifiq/presencas`
**Middleware:** `auth:sanctum` + `can:notifiq.listaPresencasNotifiq`

---

### Controller

**Arquivo:** `../vera-mendes-api/app/Http/Controllers/Notifiq/NotifiqPresencasController.php`
**Namespace:** `App\Http\Controllers\Notifiq`

```php
class NotifiqPresencasController extends Controller
{
    public function __construct(
        protected NotifiqPresencasService $service
    ) {}

    public function index(): JsonResponse
    {
        return response()->json($this->service->index());
    }
}
```

Controller fino — toda a lógica de negócio está no service.

---

### Service

**Arquivo:** `../vera-mendes-api/app/Services/notifiq/NotifiqPresencasService.php`
**Namespace:** `App\Services\notifiq`

#### `index(): array`

Busca todos os eventos Hikvision do dia atual e os agrupa em escolas → turmas → alunos.

**Query:**

```php
PresencaHikvision::query()
    ->select([
        'presencas_hikvision.id',
        'presencas_hikvision.matricula_id',
        'presencas_hikvision.evento',
        'presencas_hikvision.data_evento',
        'alunos.id as aluno_id',
        'alunos.nomecompleto as aluno_nome',
        'turmas.id as turma_id',
        'turmas.descricao as turma_nome',
        'configuracoes.id as escola_id',
        'configuracoes.descricao as escola_nome',
    ])
    ->join('matriculas', 'matriculas.id', '=', 'presencas_hikvision.matricula_id')
    ->join('alunos', 'alunos.id', '=', 'matriculas.aluno_id')
    ->join('turmas', 'turmas.id', '=', 'matriculas.turma_id')
    ->join('configuracoes', 'configuracoes.id', '=', 'turmas.configuracao_id')
    ->whereDate('presencas_hikvision.data_evento', $today->toDateString())
    ->orderBy('configuracoes.descricao')
    ->orderBy('turmas.descricao')
    ->orderByDesc('presencas_hikvision.data_evento')
    ->get();
```

**Retorno:**

```php
[
    'date'         => $today->toDateString(),       // "2026-06-03"
    'generated_at' => Carbon::now()->format('Y-m-d H:i:s'),
    'total_eventos' => $registros->count(),
    'total_escolas' => $escolas->count(),
    'total_turmas'  => $escolas->sum(fn($e) => count($e['turmas'])),
    'escolas'       => $escolas->values()->all(),
]
```

#### `groupByEscola(Collection $registros): Collection` (protected)

Transforma a coleção plana em estrutura aninhada:

```
groupBy('escola_id')
└── escola_id, escola
    └── groupBy('turma_id')
        └── turma_id, turma
            └── map → id, matricula_id, aluno_id, nome,
                       data_evento (Y-m-d H:i:s),
                       evento (int),
                       tipo_evento: evento===0 ? 'entrada' : 'saida'
```

---

### Model

**Arquivo:** `../vera-mendes-api/app/Models/PresencaHikvision.php`

```php
class PresencaHikvision extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'presencas_hikvision';

    protected $fillable = ['matricula_id', 'evento', 'data_evento'];

    protected $dates = ['data_evento', 'deleted_at'];
}
```

**Tabela:** `presencas_hikvision`

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | int PK auto-increment | — |
| `matricula_id` | int FK → `matriculas.id` | Matrícula do aluno |
| `evento` | int | `0` = entrada, `1` = saída |
| `data_evento` | datetime | Timestamp do evento Hikvision |
| `deleted_at` | datetime | Soft delete |
| `created_at` | timestamp | — |
| `updated_at` | timestamp | — |

---

### Permissão

**Migration:** `../vera-mendes-api/database/migrations/2026_04_28_000000_add_notifiq_lista_presencas_permission.php`

| Campo | Valor |
|---|---|
| `name` | `notifiq.listaPresencasNotifiq` |
| `readable_name` | Listar presenças do Notifiq |
| `guard_name` | `web` |
| Roles com acesso | `admin`, `super-admin` |

A migration usa `updateOrInsert` e verifica existência antes de criar o vínculo em `permission_role` — pode ser reexecutada com segurança.

---

## Estrutura JSON da resposta

```json
{
  "date": "2026-06-03",
  "generated_at": "2026-06-03 14:32:10",
  "total_eventos": 148,
  "total_escolas": 3,
  "total_turmas": 12,
  "escolas": [
    {
      "escola_id": 1,
      "escola": "Escola Municipal X",
      "turmas": [
        {
          "turma_id": 10,
          "turma": "3º Ano A",
          "alunos": [
            {
              "id": 501,
              "matricula_id": 200,
              "aluno_id": 99,
              "nome": "João da Silva",
              "data_evento": "2026-06-03 07:45:00",
              "evento": 0,
              "tipo_evento": "entrada"
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Checklist para replicar em outro sistema

### Backend

- [ ] Tabela `presencas_hikvision` com colunas: `matricula_id`, `evento` (0/1), `data_evento`, `deleted_at`
- [ ] Model `PresencaHikvision` com `SoftDeletes`, `$fillable` e `$dates`
- [ ] Service `NotifiqPresencasService` com método `index()` e helper `groupByEscola()`
- [ ] Controller `NotifiqPresencasController` thin com injeção do service
- [ ] Arquivo de rotas `routes/notifiq/presencas.php` com `Route::get('/', ...)->middleware('can:...')`
- [ ] Registro no `RouteServiceProvider` com prefix `notifiq/presencas`, middleware `api` + `auth:sanctum`
- [ ] Migration de permissão `notifiq.listaPresencasNotifiq` atribuída às roles necessárias

### Frontend

- [ ] Rota Vue `/notifiq/presencas` com name `notifiq.indexNotifiq` no arquivo de rotas
- [ ] Método `listPresencasNotifiq()` no service de presenças (`GET notifiq/presencas`)
- [ ] Page `IndexNotifiq.vue` com:
  - [ ] Constante `POLLING_INTERVAL = 15000`
  - [ ] Polling via `setInterval` iniciado no `mounted` e destruído no `beforeDestroy`
  - [ ] Distinção `silent/não-silent` no `refresh()` para controlar `loading` vs `refreshing`
  - [ ] `$set` para reatividade em `turmaOpenPanels`
  - [ ] `parseDateValue()` para evitar timezone shift em datas `YYYY-MM-DD`
- [ ] Entrada no menu lateral apontando para `notifiq.indexNotifiq`
