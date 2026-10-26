# Arquitetura da API (código novo)

Vale para funcionalidades novas. Código legado não é refatorado: altere só o necessário e mantenha o estilo do arquivo.

## Camadas

```
Rota (routes/<dominio>.php, middleware can:)
  └─ Controller por recurso       app/Http/Controllers/<Recurso>Controller.php
       ├─ FormRequest             app/Http/Requests/<Verbo><Entidade>Request.php
       └─ Action (1 por método)   app/Actions/<Dominio>/<Verbo><Entidade>Action.php
            └─ Service (opcional) app/Services/<Entidade>Service.php
```

### Por que Action

Cada operação de negócio vira uma classe pequena, testável sozinha e reaproveitável em controller, job ou command. O controller do recurso só traduz HTTP: valida, chama a Action, devolve JSON. Os controllers grandes do legado (`app/Http/Controllers/RelatoriosController.php`, 4.500+ linhas) são o que esse padrão evita.

### Controller

- Um controller por recurso. Cada método público = uma Action.
- Não estenda a lógica do `Controller` base (ele injeta ~40 models: não use `$this->turmas` etc. em código novo).
- Valida com FormRequest, nunca com `$request->validate()` ou `Validator::make` em código novo.
- Não envolva a chamada em `try/catch(\Exception)` para devolver erro: deixe a exceção subir (ver `docs/api-contract.md`).
- Referência de formato de controller enxuto (hoje usa Service, o código novo usa Action): `app/Http/Controllers/FeriadoController.php`.

```php
class AtendimentoController extends Controller
{
    public function store(StoreAtendimentoRequest $request, CriarAtendimentoAction $criar)
    {
        $atendimento = $criar->handle($request->validated(), getFranquia()->id, getAno()->id);

        return response()->json($atendimento, 201);
    }

    public function destroy(int $id, ExcluirAtendimentoAction $excluir)
    {
        $excluir->handle($id, getFranquia()->id);

        return response()->json(null, 204);
    }
}
```

### Action

- `final class`, um único método público `handle(...)`, injetada no método do controller.
- Recebe dados já validados (array ou tipos escalares) e ids de contexto (`configuracao_id`, `ano_id`) por parâmetro. Nunca recebe `Request`, nunca devolve `response()`.
- Devolve model, coleção, array ou nada.
- Erro de negócio: `abort(403|404|422, 'mensagem em pt-BR')` ou exceção que o Handler converta.
- Mais de uma escrita no banco: `DB::transaction(...)`.
- Nome: verbo em português + entidade: `CriarFeriadoAction`, `ConfirmarAtendimentoAction`, `ListarTurmasDaFranquiaAction`.
- Precedente no legado (mesma ideia, em `app/Domain`, que não deve receber código novo): `app/Domain/Notifiq/Actions/Matriculas/RecuperarMatriculasAnoAction.php`.

```php
final class CriarAtendimentoAction
{
    public function handle(array $dados, int $configuracaoId, int $anoId): Atendimento
    {
        return DB::transaction(fn () => Atendimento::create([
            ...$dados,
            'configuracao_id' => $configuracaoId,
            'ano_id' => $anoId,
        ]));
    }
}
```

### Service

Só quando o fluxo orquestra várias Actions ou integrações externas (Firebase, Hikvision, PDF, importação). Service chama Action; Action não chama Service. Formato plano `app/Services/<Entidade>Service.php`. A variante de pasta por caso de uso (`app/Services/Pendencias/GetPendenciasAulas/`) é legado. Não crie novos `app/Repositories` nem `app/Domain`.

### FormRequest

- `authorize()` retorna `true` (autorização é feita pelo middleware `can:`).
- Mensagens em pt-BR no método `messages()`.
- Modelo: `app/Http/Requests/StoreFeriadoRequest.php`.

## Respostas

- Sem API Resource. `response()->json($modelOuArray, $status)`.
- 200 leitura/atualização, 201 criação, 204 exclusão com corpo `null`.
- Paginação: `->paginate()` do Laravel devolvido direto (a web espera `current_page`/`last_page`).
- `{success, message}` só nos controllers de `app/Http/Controllers/Mobile/V1`.

## Tenant (franquia + ano)

- Filtre explicitamente: `->where('configuracao_id', $configuracaoId)->where('ano_id', $anoId)`.
- `getFranquia()`/`getAno()` só no controller (request autenticado). Actions recebem os ids por parâmetro.
- Recurso de uma franquia acessado por id: confira `configuracao_id` antes de alterar (ex.: `FeriadoController::update`).
