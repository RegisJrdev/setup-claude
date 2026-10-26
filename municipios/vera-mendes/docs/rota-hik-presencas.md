# Documentação Técnica: Endpoint de Recebimento de Presenças via Reconhecimento Facial (`/hik`)

> **Autor**: Desenvolvedor de Software Sênior / Arquiteto de Soluções  
> **Módulo**: Integração IoT / Controle de Acesso Facial (Hikvision & Dispositivos Biométricos)  
> **Arquitetura**: SaaS Multi-tenant (Laravel API 10+ / PHP 8.4)  
> **Rota**: `Route::any('/hik', HikController::class);`  
> **Data de Atualização**: 30/07/2026  

---

## 1. Visão Geral da Funcionalidade

A rota `/hik` é o **Webhook central de recepção de eventos de acesso e presença** em tempo real no ecossistema SaaS. Ela recebe requisições HTTP enviadas diretamente por equipamentos de reconhecimento facial (como terminais Hikvision da série DS-K1T) ou gateways locais instalados nos clientes (escolas, faculdades ou empresas).

### 1.1 Objetivo do Negócio
- **Automação de Frequência Escolar/Corporativa**: Registrar presença (Entrada e Saída) no momento exato em que o indivíduo (aluno ou colaborador) passa pelo dispositivo de reconhecimento facial.
- **Notificação em Tempo Real (Push FCM)**: Notificar imediatamente responsáveis legais (pais/tutores) ou gestores assim que a presença for confirmada pelo hardware.
- **Diferenciação de Perfis (Alunos vs. Colaboradores)**: Processar automaticamente a frequência escolar para alunos e o espelho de ponto jornada para funcionários/instrutores com base no identificador da credencial (`employeeNoString`).
- **Suporte Multi-tenant em Escala SaaS**: Processar eventos vindos de múltiplos dispositivos distribuídos em diferentes unidades/clientes com resiliência, auditabilidade total e proteção contra registros duplicados.

---

## 2. Especificação da Rota e Contrato da API

### 2.1 Mapeamento de Rota

No arquivo `routes/api.php`:
```php
use App\Http\Controllers\HikController;

Route::any('/hik', HikController::class);
```

> **Por que `Route::any`?**  
> Os equipamentos de reconhecimento facial e gateways IoT Hikvision podem utilizar variações nos métodos HTTP (`POST`, `PUT`, `GET` em simulações) dependendo do firmware ou configuração da notificação de evento (ISAPI / Event Notification Server). O uso do `Route::any` garante tolerância total às diretivas do hardware.

### 2.2 Estrutura do Payload (Request)

O controller espera receber os dados do evento codificados em JSON dentro do campo `event_log` do corpo da requisição (`application/x-www-form-urlencoded` ou `application/json`).

#### Parâmetros Recebidos no Webhook:

| Parâmetro | Tipo | Obrigatório | Descrição |
| :--- | :--- | :--- | :--- |
| `event_log` | `string` (JSON String) | **Sim** | String JSON envelopada contendo o payload estruturado do evento de acesso da Hikvision. |

#### Estrutura Interna de `AccessControllerEvent` (dentro de `event_log`):

```json
{
  "dateTime": "2026-07-30T07:30:00-03:00",
  "eventType": 196893,
  "AccessControllerEvent": {
    "employeeNoString": "1042",
    "deviceName": "RECONHECIMENTO_FACIAL_ENTRADA_PRINCIPAL",
    "subEventType": 75,
    "attendanceStatus": "checkIn"
  }
}
```

#### Detalhamento dos Campos Extraídos:
- **`employeeNoString`**: Código identificador único cadastrado no dispositivo facial (ID do Aluno no banco ou ID de Funcionário prefixado com `F`, ex: `F204`).
- **`deviceName`**: Nome identificador do dispositivo que leu a face.
- **`dateTime`**: Data e hora exata da leitura biométrica no formato ISO 8601.
- **`eventType` / `subEventType`**: Código numérico do evento no padrão de firmware Hikvision (ex: 75 = Leitura Facial bem-sucedida).
- **`attendanceStatus`**: Status do evento informado pelo equipamento (`checkIn`, `checkOut`, etc.).

---

## 3. Fluxo de Processamento Arquitetural (Backend / Controller)

O ciclo de vida de uma requisição que chega na rota `/hik` segue uma pipeline de 6 etapas bem definidas:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. RECEPÇÃO E LOGS DE DIAGNÓSTICO (IP, Headers, Content-Type)               │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────────┐
│ 2. VALIDAÇÃO E DECODIFICAÇÃO DO PAYLOAD (`event_log` -> JSON array)          │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────────┐
│ 3. REGISTRO DE AUDITORIA BRUTA (Tabela: `hikvision_events`)                 │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ├───────────────────────────────────────┐
                                      │ (Se employeeNoString inicia com 'F')  │
                                      ▼                                       │
┌─────────────────────────────────────────────────────────┐                   │
│ 4A. PROCESSAR PONTO COLABORADOR                         │                   │
│ - InstrutorBatidaImportacaoService                      │                   │
│ - InstrutorJornadaService (recalcula jornada do dia)    │                   │
└─────────────────────────────────────────────────────────┘                   │
                                                                              │
                                      ┌───────────────────────────────────────┘
                                      │ (Caso contrário: Aluno)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 4B. PROCESSAR PRESENÇA DE ALUNO (`processarPresenca`)                       │
│ - Valida existência do Aluno no banco                                        │
│ - Busca matrículas ativas para o ano letivo do evento                       │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────────┐
│ 5. APLICAÇÃO DE REGRAS DE NEGÓCIO DA PRESENÇA                               │
│ - Verificação Anti-passback / Debounce (`hikvision.intervalo_minutos`)      │
│ - Alternância Inteligente: ENTRADA (0) <-> SAÍDA (1)                        │
│ - Persistência na tabela `presencas_hikvision`                              │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────────┐
│ 6. DISPARO DE NOTIFICAÇÃO PUSH EM TEMPO REAL (FcmService -> App Responsável)│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Regras de Negócio e Tratamento de Exceções

### 4.1 Triagem de Perfil pelo Identificador (`employeeNoString`)

1. **Perfil Colaborador / Instrutor**:
   - Detectado quando `employeeNoString` inicia com a letra **`F`** (exemplo: `F15`).
   - **Ação**: Redireciona o payload para `processarBatidaColaborador()`.
   - **Serviços Envolvidos**: `InstrutorBatidaImportacaoService` grava a batida de ponto e `InstrutorJornadaService` recalcula as horas/jornada do funcionário.

2. **Perfil Aluno**:
   - Detectado quando `employeeNoString` é um número inteiro puramente numérico (ID da tabela `alunos`).
   - **Ação**: Executa `processarPresenca($employeeNo, $eventTime)`.

### 4.2 Regra de Validação de Matrícula Ativa
Para registrar a presença de um aluno, o sistema valida se o aluno possui matrícula vinculada a um ano letivo vigente:
- Busca o ano letivo correspondente à data do evento (`Ano::where('descricao', $anoEvento)`).
- Filtra matrículas nas situações aceitas: `RECEBIDA`, `CURSANDO`, `0`, `APROVADO`, `REPROVADO`.
- Se o aluno não for encontrado ou não possuir matrícula válida no ano, o evento é registrado na auditoria mas a presença é ignorada com aviso nos logs (`Log::warning`).

### 4.3 Alternância Inteligente (Entrada / Saída) e Trava de Debounce (Anti-Passback)

Para evitar duplicidade de registros (por exemplo, quando o aluno fica parado em frente à câmera e o leitor captura a face 3 vezes seguidas):

1. **Primeira presença do dia**:
   - O sistema define o evento como **ENTRADA** (`evento = 0`).

2. **Leituras subsequentes no mesmo dia**:
   - O sistema calcula a diferença em minutos entre o horário do evento atual e o registro anterior (`$dataUltimaPresenca->diffInMinutes($dataEventoCarbon)`).
   - **Intervalo Mínimo (Debounce)**: Se a diferença for menor que a configurada no sistema (`config('hikvision.intervalo_minutos')`, padrão 5 min), a leitura é **descartada** e um log informativo é gerado (`Presença ignorada - intervalo de tempo não respeitado`).
   - **Inversão de Tipo**: Se a diferença respeitar o intervalo mínimo, o tipo de evento é alternado automaticamente:
     - Se a última foi `0` (ENTRADA), a nova será `1` (SAÍDA).
     - Se a última foi `1` (SAÍDA), a nova será `0` (ENTRADA).

### 4.4 Disparo de Notificações Push (FCM)

Assim que o registro de presença é persistido na tabela `presencas_hikvision`:
- O sistema verifica se o aluno possui uma conta de usuário/responsável associada (`$aluno->user`).
- Instancia o `FcmService` para enviar uma notificação push para o smartphone do responsável com a mensagem:
  > *"Olá {NomeCompleto},\n\nUma entrada/saída foi registrada hoje às {HH:MM:SS}, na turma {Turma}. Atenção à sua frequência!"*

---

## 5. Estrutura das Tabelas do Banco de Dados

### 5.1 Tabela `hikvision_events` (Log de Auditoria Bruto)
Armazena a cópia exata do payload de todas as requisições que chegam no webhook `/hik`.

```sql
CREATE TABLE hikvision_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_no VARCHAR(255) NULL,
    device_name VARCHAR(255) NULL,
    event_type VARCHAR(255) NULL,
    sub_event_type VARCHAR(255) NULL,
    attendance_status VARCHAR(255) NULL,
    event_time DATETIME NULL,
    payload JSON NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

### 5.2 Tabela `presencas_hikvision` (Registros de Presença Processados)
Armazena as presenças consolidadas que alimentam o diário de classe e relatórios do SaaS.

```sql
CREATE TABLE presencas_hikvision (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    matricula_id BIGINT NOT NULL,
    evento INT NOT NULL COMMENT '0: Entrada, 1: Saída',
    data_evento DATETIME NOT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (matricula_id) REFERENCES matriculas(id) ON DELETE CASCADE
);
```

---

## 6. Boas Práticas SaaS, Resiliência e Escalabilidade

### 6.1 Isolamento Multi-tenant
No modelo SaaS, múltiplos clientes utilizam a mesma instância da API. Cada dispositivo cadastrado na tabela `hikvision_configuracoes` possui vínculo com a tenant/escola (`configuracao_id`). Ao receber o `deviceName` ou serial, o sistema identifica a tenant correspondente para isolamento dos dados.

### 6.2 Processamento Assíncrono (Recomendação para Alto Volume)
Em cenários de pico (ex: 7:00 AM com 2.000 alunos entrando simultaneamente em diversas unidades), o processamento síncrono das notificações FCM e consultas de matrícula pode sobrecarregar a requisição HTTP do webhook.

**Recomendação de Arquitetura Sênior**:
- Responda rapidamente `HTTP 200 OK` no webhook após gravar na tabela `hikvision_events`.
- Despache um Job no Laravel Queues (`ProcessarPresencaHikvisionJob::dispatch($hikvisionEvent)`) processado via Redis / Horizon para garantir resposta abaixo de 50ms para os equipamentos IoT.

### 6.3 Resposta aos Erros (HTTP Status Codes)

| Status Code | Causa | Resposta JSON |
| :--- | :--- | :--- |
| `200 OK` | Evento recebido e processado com sucesso. | `{"message": "Evento salvo com sucesso", "event_id": 123}` |
| `400 Bad Request` | Payload ausente, malformatado ou JSON inválido. | `{"message": "Payload vazio ou inválido"}` |
| `500 Internal Error` | Erro não tratado de banco ou runtime. | `{"message": "Erro interno", "error": "..."}` |

---

## 7. Exemplo de Código do Controller (`HikController.php`)

```php
<?php

namespace App\Http\Controllers;

use App\Models\Aluno;
use App\Models\Ano;
use App\Models\HikvisionEvent;
use App\Models\PresencaHikvision;
use App\Services\FcmService;
use App\Services\InstrutorBatidaImportacaoService;
use App\Services\InstrutorJornadaService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class HikController extends Controller
{
    public function __invoke(Request $request)
    {
        Log::info('🔔 WEBHOOK HIKVISION INICIADO', [
            'ip' => $request->ip(),
            'method' => $request->method(),
        ]);

        try {
            $data = $request->input('event_log');

            if (!$data) {
                return response()->json(['message' => 'Payload vazio ou inválido'], 400);
            }

            $payload = json_decode($data, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return response()->json(['message' => 'Erro ao decodificar JSON'], 400);
            }

            $event = $payload['AccessControllerEvent'] ?? null;
            if (!$event) {
                return response()->json(['message' => 'Evento não encontrado'], 400);
            }

            $employeeNo = $event['employeeNoString'] ?? null;
            $deviceName = $event['deviceName'] ?? null;
            $eventType = $payload['eventType'] ?? null;
            $subEventType = $event['subEventType'] ?? null;
            $attendanceStatus = $event['attendanceStatus'] ?? null;
            $eventTime = $payload['dateTime'] ?? now();

            if ($employeeNo) {
                // 1. Auditoria bruta
                $hikvisionEvent = HikvisionEvent::create([
                    'employee_no' => $employeeNo,
                    'device_name' => $deviceName,
                    'event_type' => $eventType,
                    'sub_event_type' => $subEventType,
                    'attendance_status' => $attendanceStatus,
                    'event_time' => $eventTime,
                    'payload' => $payload,
                ]);

                // 2. Roteamento por perfil
                if (str_starts_with((string) $employeeNo, 'F')) {
                    $this->processarBatidaColaborador($payload);
                } else {
                    $this->processarPresenca($employeeNo, $eventTime);
                }

                return response()->json([
                    'message' => 'Evento salvo com sucesso',
                    'event_id' => $hikvisionEvent->id,
                    'employee_no' => $employeeNo,
                ], 200);
            }

            return response()->json(['message' => 'Sem identificação de usuário'], 400);

        } catch (\Throwable $e) {
            Log::error('💥 ERRO CRÍTICO NO WEBHOOK HIKVISION', [
                'error_message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'message' => 'Erro interno',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }
}
```

---

## 8. Guia de Diagnóstico e Monitoramento de Logs

Para auditar e monitorar as presenças via leitor facial em ambiente de produção SaaS, consulte os logs do Laravel:

```bash
# Monitorar entradas de webhook em tempo real
tail -f storage/logs/laravel.log | grep -E "WEBHOOK HIKVISION|PRESENÇA PROCESSADA|Notificação enviada"

# Investigar falhas e rejeições de intervalo mínimo (debounce)
grep "Presença ignorada - intervalo de tempo não respeitado" storage/logs/laravel.log
```

---

### Conclusão
A arquitetura do endpoint `/hik` garante desacoplamento, alta auditabilidade de eventos brutos de hardware e processamento seguro de presenças com notificações em tempo real, atendendo aos padrões exigidos por plataformas SaaS multi-tenant enterprise.
