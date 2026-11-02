# Organização dos arquivos SQL individuais

## Objetivo

Registrar a comparação dos objetos dos scripts consolidados com os arquivos
individuais, após o merge do PR #38 (alertas e metas).

## Revisão de 02/11/2026

Foram comparados 170 objetos de `script-schema.sql`, `script-optimization.sql`,
`script-audit.sql`, `script-datamart.sql` e `script-indexes.sql`: tabelas,
functions, procedures, triggers, views, índices e schemas. As definições foram
comparadas desconsiderando comentários e espaços.

Foram adicionados 12 arquivos em `datamart/`, seguindo as pastas existentes:

| Camada | Tabelas | Procedures | Views |
| --- | --- | --- | --- |
| Stage | `user_preferences`, `alerts_history` | — | — |
| Silver | `ft_alert`, `dm_user_preference` | `sp_load_ft_alert`, `sp_load_dm_user_preference` | — |
| Gold | `ft_alert`, `dm_user_preference` | `sp_load_ft_alert`, `sp_load_dm_user_preference` | — |
| DW | — | — | `vw_ft_alert`, `vw_ft_user_goal` |

Também foram sincronizados:

- `silver.sp_load` e `gold.sp_load`, incluindo as chamadas de alertas e preferências;
- `tables/tb_address.sql`, incluindo a unicidade do CEP já existente no consolidado;
- `script-audit.sql`, restaurando `organization_id` e `built_area_m2` no histórico
  e na function de auditoria de propriedades, conforme os arquivos individuais.

Ao final, os 170 objetos consolidados possuem uma definição individual equivalente.
Existe um objeto apenas individual: `functions/fn_calculate_water_cost.sql`.
Sua inclusão no consolidado foi mantida fora desta alteração, pois o `TASK.md`
registra outro PR responsável por esse ponto.

## Validação

Em PostgreSQL 16 descartável, os scripts foram executados na ordem de `setup_db.py`.
Depois, os objetos foram recriados com as definições individuais na mesma ordem.
As cargas Silver/Gold e as consultas às duas novas views passaram.

Limitação preexistente: `script-roles.sql` começa com revogações que exigem schemas
analíticos e roles já existentes. No teste, os schemas foram preparados antes e
somente o bloco inicial de revogações foi omitido. Portanto, essa execução não
comprova que `setup_db.py` funciona sem ajustes num banco completamente vazio.
O script de roles não foi alterado nesta revisão. O container de teste foi removido.
