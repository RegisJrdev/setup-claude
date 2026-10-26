# Testes

## API

### Rodar

```bash
vendor/bin/pest                       # tudo
vendor/bin/pest --filter=Feriado      # por nome
vendor/bin/pest tests/Feature/Feriados
```

`php artisan test` também funciona (usa o mesmo runner).

### Ambiente

- `phpunit.xml` força sqlite em memória, cache/sessão em array e fila `sync`.
- `tests/TestCase.php` usa `DatabaseTransactions` e oferece `authUser()` (cria usuário e faz `Sanctum::actingAs`).
- `tests/Pest.php` liga `Tests\TestCase` + `RefreshDatabase` aos testes Pest de `tests/Feature` e `Tests\TestCase` aos de `tests/Unit`.

### Escrever teste novo (Pest)

- Testes novos em Pest. Os testes antigos em classe PHPUnit continuam e rodam no mesmo comando; não converta.
- Feature: um arquivo por recurso em `tests/Feature/<Dominio>/`. Unit de Action: `tests/Unit/Actions/<Dominio>/`.
- Nome do teste em pt-BR descrevendo o comportamento.
- Use factories (`database/factories/`); crie a factory que faltar em vez de inserir com `DB::table`.
- Não use `WithoutMiddleware` em teste novo de rota: ele desliga o `can:`. Para autenticar com permissões: `Sanctum::actingAs($user, ['recurso.acao'])`.
- Teste o isolamento por franquia: dado de outra `configuracao_id` não aparece / não pode ser alterado.

```php
use App\Models\Feriado;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

it('cria feriado municipal na franquia do usuário', function () {
    $user = User::factory()->create();
    Sanctum::actingAs($user, ['feriados.gerenciar']);

    $this->postJson('ponto-colaboradores/admin/feriados', ['data' => '2026-04-21', 'tipo' => 'municipal', 'descricao' => 'Teste'])
        ->assertCreated();

    expect(Feriado::first()->configuracao_id)->toBe($user->configuracao_id);
});
```

Rota e permissão reais (`routes/pontoColaboradores.php`). Campos obrigatórios em `app/Http/Requests/StoreFeriadoRequest.php`.

Referências em PHPUnit (legado, mas bons exemplos de cenário): `tests/Feature/Feriados/FeriadoTest.php`, `tests/Feature/GestaoDeAulaCriarTest.php`, `tests/Unit/Services/FeriadoServiceTest.php`.

## Web

### Rodar

```bash
yarn test:unit
yarn test:unit tests/unit/components/Colaboradores
```

CI não roda testes: rode antes de abrir PR.

### Escrever

- Jest 24 + `@vue/test-utils` 1, em `tests/unit/**/*.spec.js`; `tests/unit/setup.js` registra Vuetify.
- Modelo: `tests/unit/components/Colaboradores/FaltaJustificadaForm.spec.js` (`mount` com `createLocalVue`, `new Vuetify()`, helper `factory()`, nomes em pt-BR).
- Componente que usa `ValidationProvider` precisa registrá-lo no teste (o setup não registra vee-validate).
