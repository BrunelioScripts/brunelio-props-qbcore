# Verificação do `client.lua` (Moneywash)

Resumo rápido da análise do código enviado pelo utilizador.

## Pontos críticos encontrados

1. **Funções não definidas no trecho enviado**
   - `SpawnNpc(...)`
   - `SpawnProp(...)`
   - `MissionCleanupStepEntities()`
   - variável/tabela `MissionEnt`

   Se essas funções/estruturas não existirem em outra parte do ficheiro, o script irá quebrar em runtime quando uma missão iniciar.

2. **`GlobalSettings` declarado, mas não utilizado de forma efetiva**
   - `GetInteractionType(...)` consulta `GlobalSettings`, porém o fluxo principal usa `Settings.interaction`.
   - Isso não quebra o script por si só, mas indica código morto/inconsistente.

3. **Comentário de código “continua igual” no meio do ficheiro**
   - O comentário `-- ... (o resto do código continua exatamente igual...)` foi deixado entre blocos reais.
   - Não é erro de execução, mas dificulta manutenção e revisão.

4. **Dependência de framework target sem fallback explícito de notificação**
   - Quando `Settings.interaction = "target"` e nenhum target framework está ativo (`qb-target`/`ox_target`), partes de interação podem ficar sem ação para o jogador.
   - Recomendação: notificar no load/rebuild quando o modo target estiver ativo sem framework disponível.

## Recomendações imediatas

- Garantir que as funções abaixo existam no mesmo arquivo ou sejam importadas com segurança:
  - `SpawnNpc`
  - `SpawnProp`
  - `MissionCleanupStepEntities`
- Garantir inicialização de `MissionEnt`, por exemplo:

```lua
local MissionEnt = {
  peds = {},
  props = {},
  targets = {}
}
```

- Remover/alinhar `GlobalSettings` para evitar divergência com `Settings`.
- Adicionar aviso quando `interaction = "target"` e nenhum target framework estiver disponível.

## Conclusão

A arquitetura geral está consistente com o objetivo (Settings a comandar interação global e targets), mas o trecho depende de definições externas que **precisam existir** para evitar erro em runtime.
