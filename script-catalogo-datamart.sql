
BEGIN;

INSERT INTO tb_data_catalog (table_name, column_name, data_type, description, business_rule, access_level) VALUES

('stage.consumption_reading_raw', 'id', 'BIGSERIAL', 'Identificador da leitura bruta.', 'Chave primária.', 'INTERNO'),
('stage.consumption_reading_raw', 'property_id', 'INTEGER', 'Instalação de origem da leitura.', 'Sem FK declarada (schema stage é cópia bruta) — corresponde a tb_property.id.', 'INTERNO'),
('stage.consumption_reading_raw', 'read_at', 'TIMESTAMP', 'Momento da leitura.', 'Grão de 15 minutos na carga sintética atual.', 'INTERNO'),
('stage.consumption_reading_raw', 'volume_liters', 'NUMERIC(10,3)', 'Volume consumido na janela da leitura, em litros.', 'CHECK: não pode ser negativo. Dado sintético (gerado via generate_series) — ver comentário no arquivo.', 'PUBLICO'),
('stage.consumption_reading_raw', 'flow_lmin', 'NUMERIC(10,3)', 'Vazão instantânea da leitura, em L/min.', 'CHECK: não pode ser negativo. Dado sintético.', 'PUBLICO'),
('stage.consumption_reading_raw', 'loaded_at', 'TIMESTAMP', 'Momento em que a linha foi carregada no stage.', 'Padrão CURRENT_TIMESTAMP.', 'INTERNO'),

('silver.consumption_reading', 'id', 'BIGSERIAL', 'Identificador da leitura tratada.', 'Chave primária.', 'INTERNO'),
('silver.consumption_reading', 'property_id', 'INTEGER', 'Instalação de origem da leitura.', 'Único em conjunto com read_at (evita duplicar reenvio da mesma janela).', 'INTERNO'),
('silver.consumption_reading', 'read_at', 'TIMESTAMP', 'Momento da leitura.', '', 'INTERNO'),
('silver.consumption_reading', 'volume_liters', 'NUMERIC(10,3)', 'Volume consumido na janela, em litros.', '', 'PUBLICO'),
('silver.consumption_reading', 'flow_lmin', 'NUMERIC(10,3)', 'Vazão instantânea, em L/min.', '', 'PUBLICO'),

('silver.consumption_daily', 'id', 'BIGSERIAL', 'Identificador do rollup diário.', 'Chave primária.', 'INTERNO'),
('silver.consumption_daily', 'property_id', 'INTEGER', 'Instalação do rollup.', 'Único em conjunto com consumption_day.', 'INTERNO'),
('silver.consumption_daily', 'consumption_day', 'DATE', 'Dia de referência do rollup.', '', 'PUBLICO'),
('silver.consumption_daily', 'total_liters', 'NUMERIC(12,3)', 'Soma do volume consumido no dia, em litros.', 'Soma de silver.consumption_reading.volume_liters.', 'PUBLICO'),
('silver.consumption_daily', 'avg_flow_lmin', 'NUMERIC(10,3)', 'Vazão média do dia, em L/min.', 'Média de silver.consumption_reading.flow_lmin.', 'PUBLICO'),

('silver.property', 'property_id', 'INTEGER', 'Instalação (residencial ou industrial).', 'Chave primária, corresponde a tb_property.id.', 'INTERNO'),
('silver.property', 'name', 'VARCHAR(100)', 'Nome/apelido da instalação.', '', 'INTERNO'),
('silver.property', 'property_type', 'VARCHAR(20)', 'Tipo do imóvel (CASA/PRÉDIO).', '', 'INTERNO'),
('silver.property', 'classification_id', 'INTEGER', 'Categoria de imóvel, usada na resolução de tarifa vigente.', '', 'INTERNO'),
('silver.property', 'classification_group', 'VARCHAR(20)', 'Grupo da categoria (RESIDENCIAL/COMERCIAL).', '', 'PUBLICO'),
('silver.property', 'region_id', 'INTEGER', 'Região tarifária da instalação.', '', 'INTERNO'),
('silver.property', 'city', 'VARCHAR(60)', 'Cidade da instalação.', '', 'INTERNO'),
('silver.property', 'state', 'VARCHAR(30)', 'Estado da instalação.', '', 'INTERNO'),
('silver.property', 'built_area_m2', 'NUMERIC(10,2)', 'Área construída, em m².', 'Usada para normalizar consumo (L/m²) no ranking.', 'INTERNO'),
('silver.property', 'organization_id', 'INTEGER', 'Organização gestora, quando aplicável.', 'NULL para imóvel residencial de pessoa física.', 'INTERNO'),
('silver.property', 'organization_name', 'VARCHAR(150)', 'Nome fantasia da organização gestora.', '', 'INTERNO'),
('silver.property', 'has_operational_profile', 'BOOLEAN', 'Indica se a instalação passou pelo cadastro industrial completo.', 'TRUE quando existe linha em tb_property_operational_profile.', 'INTERNO'),
('silver.property', 'shift_count', 'SMALLINT', 'Quantidade de turnos, quando aplicável.', '', 'INTERNO'),
('silver.property', 'main_water_source', 'VARCHAR(20)', 'Fonte principal de água, quando aplicável.', '', 'INTERNO'),

('silver.person', 'user_id', 'INTEGER', 'Pessoa (usuário residencial ou gestor).', 'Chave primária, corresponde a tb_user.id.', 'INTERNO'),
('silver.person', 'name', 'VARCHAR(100)', 'Nome da pessoa.', '', 'RESTRITO'),
('silver.person', 'profile_type', 'VARCHAR(20)', 'Perfil de uso da pessoa.', 'RESIDENCIAL ou GESTOR, derivado da existência de vínculo em tb_user_organization. Sem papel/hierarquia.', 'INTERNO'),

('silver.water_bill', 'id', 'BIGSERIAL', 'Identificador da fatura tratada.', 'Chave primária.', 'INTERNO'),
('silver.water_bill', 'user_id', 'INTEGER', 'Usuário dono da fatura.', 'Único em conjunto com bill_month.', 'INTERNO'),
('silver.water_bill', 'user_name', 'VARCHAR(100)', 'Nome do usuário.', 'Denormalizado de tb_user pra evitar join na camada gold.', 'RESTRITO'),
('silver.water_bill', 'bill_month', 'DATE', 'Mês de referência da fatura.', '', 'INTERNO'),
('silver.water_bill', 'total_value', 'NUMERIC(10,2)', 'Valor total pago.', '', 'RESTRITO'),
('silver.water_bill', 'm3_value', 'NUMERIC(10,2)', 'Consumo em m³ registrado na fatura.', '', 'RESTRITO'),

('gold.dm_date', 'date_key', 'INTEGER', 'Chave substituta da data (formato YYYYMMDD).', 'Chave primária.', 'PUBLICO'),
('gold.dm_date', 'full_date', 'DATE', 'Data completa.', 'Única.', 'PUBLICO'),
('gold.dm_date', 'day_of_week', 'SMALLINT', 'Dia da semana (0=domingo).', '', 'PUBLICO'),
('gold.dm_date', 'day_name', 'VARCHAR(20)', 'Nome do dia da semana.', '', 'PUBLICO'),
('gold.dm_date', 'week_of_year', 'SMALLINT', 'Semana do ano.', '', 'PUBLICO'),
('gold.dm_date', 'month_number', 'SMALLINT', 'Mês (1-12).', '', 'PUBLICO'),
('gold.dm_date', 'quarter_number', 'SMALLINT', 'Trimestre (1-4).', '', 'PUBLICO'),
('gold.dm_date', 'year_number', 'SMALLINT', 'Ano.', '', 'PUBLICO'),
('gold.dm_date', 'is_weekend', 'BOOLEAN', 'Indica fim de semana.', '', 'PUBLICO'),

('gold.dm_property', 'property_key', 'SERIAL', 'Chave substituta da instalação.', 'Chave primária.', 'PUBLICO'),
('gold.dm_property', 'property_id', 'INTEGER', 'Chave natural (tb_property.id).', 'Única.', 'INTERNO'),
('gold.dm_property', 'name', 'VARCHAR(100)', 'Nome/apelido da instalação.', '', 'INTERNO'),
('gold.dm_property', 'property_type', 'VARCHAR(20)', 'Tipo do imóvel.', '', 'INTERNO'),
('gold.dm_property', 'classification_group', 'VARCHAR(20)', 'Grupo da categoria (RESIDENCIAL/COMERCIAL).', '', 'PUBLICO'),
('gold.dm_property', 'city', 'VARCHAR(60)', 'Cidade da instalação.', '', 'INTERNO'),
('gold.dm_property', 'state', 'VARCHAR(30)', 'Estado da instalação.', '', 'INTERNO'),
('gold.dm_property', 'built_area_m2', 'NUMERIC(10,2)', 'Área construída, em m².', '', 'INTERNO'),
('gold.dm_property', 'organization_name', 'VARCHAR(150)', 'Nome fantasia da organização gestora, denormalizado (star schema puro, sem braço snowflake).', '', 'INTERNO'),
('gold.dm_property', 'has_operational_profile', 'BOOLEAN', 'Indica cadastro industrial completo.', '', 'INTERNO'),

('gold.dm_person', 'person_key', 'SERIAL', 'Chave substituta da pessoa.', 'Chave primária.', 'PUBLICO'),
('gold.dm_person', 'user_id', 'INTEGER', 'Chave natural (tb_user.id).', 'Única.', 'INTERNO'),
('gold.dm_person', 'name', 'VARCHAR(100)', 'Nome da pessoa.', '', 'RESTRITO'),
('gold.dm_person', 'profile_type', 'VARCHAR(20)', 'Perfil de uso (RESIDENCIAL/GESTOR).', '', 'INTERNO'),

('gold.ft_consumption_daily', 'fact_key', 'BIGSERIAL', 'Identificador do fato.', 'Chave primária.', 'INTERNO'),
('gold.ft_consumption_daily', 'property_key', 'INTEGER', 'Instalação (industrial).', 'FK para gold.dim_property. Única em conjunto com date_key.', 'INTERNO'),
('gold.ft_consumption_daily', 'date_key', 'INTEGER', 'Dia do consumo.', 'FK para gold.dim_date.', 'INTERNO'),
('gold.ft_consumption_daily', 'total_liters', 'NUMERIC(12,3)', 'Consumo total do dia, em litros.', 'Medida — unidade: litros (L).', 'PUBLICO'),
('gold.ft_consumption_daily', 'avg_flow_lmin', 'NUMERIC(10,3)', 'Vazão média do dia, em L/min.', 'Medida — unidade: litros/minuto.', 'PUBLICO'),
('gold.ft_consumption_daily', 'cost_value', 'NUMERIC(12,2)', 'Custo estimado do consumo do dia.', 'Medida — unidade: R$. Calculado via fn_get_current_region_rate.', 'PUBLICO'),

('gold.ft_water_bill_monthly', 'fact_key', 'BIGSERIAL', 'Identificador do fato.', 'Chave primária.', 'INTERNO'),
('gold.ft_water_bill_monthly', 'person_key', 'INTEGER', 'Pessoa (residencial).', 'FK para gold.dim_person. Única em conjunto com date_key.', 'INTERNO'),
('gold.ft_water_bill_monthly', 'date_key', 'INTEGER', 'Mês de referência (primeiro dia do mês).', 'FK para gold.dim_date.', 'INTERNO'),
('gold.ft_water_bill_monthly', 'total_value', 'NUMERIC(10,2)', 'Valor total pago no mês.', 'Medida — unidade: R$.', 'RESTRITO'),
('gold.ft_water_bill_monthly', 'm3_value', 'NUMERIC(10,2)', 'Consumo do mês.', 'Medida — unidade: m³.', 'RESTRITO'),

('gold.ft_investment_scenario', 'scenario_key', 'SERIAL', 'Chave substituta do cenário.', 'Chave primária.', 'PUBLICO'),
('gold.ft_investment_scenario', 'scenario_id', 'INTEGER', 'Chave natural (tb_investment_scenario.id).', 'Única.', 'PUBLICO'),
('gold.ft_investment_scenario', 'name', 'VARCHAR(100)', 'Nome do cenário.', '', 'PUBLICO'),
('gold.ft_investment_scenario', 'investment_value', 'NUMERIC(10,2)', 'Investimento estimado.', 'Medida — unidade: R$.', 'PUBLICO'),
('gold.ft_investment_scenario', 'reduction_pct', 'NUMERIC(5,2)', 'Redução estimada de consumo.', 'Medida — unidade: %.', 'PUBLICO'),
('gold.ft_investment_scenario', 'annual_savings_value', 'NUMERIC(10,2)', 'Economia estimada em um ano.', 'Medida — unidade: R$.', 'PUBLICO'),
('gold.ft_investment_scenario', 'payback_months', 'NUMERIC(6,1)', 'Tempo de retorno estimado.', 'Medida — unidade: meses.', 'PUBLICO'),

('dw.vw_consumption_daily', 'property_id', 'INTEGER', 'Instalação.', 'Grão: instalação x dia.', 'INTERNO'),
('dw.vw_consumption_daily', 'full_date', 'DATE', 'Dia do consumo.', '', 'PUBLICO'),
('dw.vw_consumption_daily', 'total_liters', 'NUMERIC', 'Consumo do dia, em litros.', 'Medida — unidade: L.', 'PUBLICO'),
('dw.vw_consumption_daily', 'cost_value', 'NUMERIC', 'Custo estimado do dia.', 'Medida — unidade: R$.', 'PUBLICO'),
('dw.vw_consumption_daily', 'running_total_liters', 'NUMERIC', 'Total acumulado desde a primeira leitura da instalação.', 'Window function SUM() OVER — running total.', 'PUBLICO'),
('dw.vw_consumption_daily', 'moving_avg_7d_liters', 'NUMERIC', 'Média móvel de 7 dias do consumo diário.', 'Window function AVG() OVER.', 'PUBLICO'),

('dw.vw_property_ranking', 'property_id', 'INTEGER', 'Instalação.', 'Grão: 1 instalação (agregado do período todo).', 'INTERNO'),
('dw.vw_property_ranking', 'liters_per_m2', 'NUMERIC', 'Consumo total normalizado pela área construída.', 'Medida — unidade: L/m².', 'PUBLICO'),
('dw.vw_property_ranking', 'rank_efficiency', 'BIGINT', 'Posição no ranking de eficiência (menor L/m² = melhor).', 'Window function RANK().', 'PUBLICO'),
('dw.vw_property_ranking', 'rank_cost', 'BIGINT', 'Posição no ranking de custo total.', 'Window function DENSE_RANK().', 'PUBLICO'),
('dw.vw_property_ranking', 'consumption_quartile', 'INTEGER', 'Quartil de consumo por m².', 'Window function NTILE(4).', 'PUBLICO'),
('dw.vw_property_ranking', 'consumption_percent_rank', 'DOUBLE PRECISION', 'Percentil relativo de consumo por m².', 'Window function PERCENT_RANK().', 'PUBLICO'),

('dw.vw_monthly_variation', 'property_id', 'INTEGER', 'Instalação.', 'Grão: instalação x mês.', 'INTERNO'),
('dw.vw_monthly_variation', 'reference_month', 'DATE', 'Mês de referência (primeiro dia).', '', 'PUBLICO'),
('dw.vw_monthly_variation', 'variation_pct', 'NUMERIC', 'Variação percentual de consumo vs. mês anterior.', 'Window function LAG().', 'PUBLICO'),

('dw.vw_consumption_distribution', 'property_key', 'INTEGER', 'Instalação da leitura diária.', 'Grão: 1 leitura diária (para o histograma); estatísticas são as mesmas em toda linha.', 'INTERNO'),
('dw.vw_consumption_distribution', 'distribution_bucket', 'INTEGER', 'Faixa (quintil) de consumo diário.', 'Window function NTILE(5).', 'PUBLICO'),
('dw.vw_consumption_distribution', 'median_liters', 'NUMERIC', 'Mediana do consumo diário entre todas as instalações.', 'PERCENTILE_CONT(0.5).', 'PUBLICO'),

('dw.vw_capex_comparison', 'scenario_id', 'INTEGER', 'Cenário de investimento.', 'Grão: 1 cenário.', 'PUBLICO'),
('dw.vw_capex_comparison', 'rank_by_payback', 'BIGINT', 'Posição no ranking por tempo de retorno.', 'Window function RANK().', 'PUBLICO'),

('dw.vw_residential_efficiency_ranking', 'user_id', 'INTEGER', 'Pessoa (residencial).', 'Grão: pessoa x mês.', 'INTERNO'),
('dw.vw_residential_efficiency_ranking', 'rank_efficiency', 'BIGINT', 'Posição no ranking de eficiência do mês (menor consumo = melhor).', 'Window function RANK() PARTITION BY mês.', 'PUBLICO'),
('dw.vw_residential_efficiency_ranking', 'consumption_percent_rank', 'DOUBLE PRECISION', 'Percentil relativo de consumo no mês.', 'Window function PERCENT_RANK().', 'PUBLICO'),

('dw.vw_audit_history_chain', 'log_id', 'INTEGER', 'Identificador da linha de log.', 'Grão: 1 evento de auditoria de tb_region_rate.', 'INTERNO'),
('dw.vw_audit_history_chain', 'region_rate_id', 'INTEGER', 'Tarifa auditada.', '', 'PUBLICO'),
('dw.vw_audit_history_chain', 'level', 'INTEGER', 'Posição do evento na cadeia de mudanças da tarifa (1 = inserção original).', 'CTE recursiva sobre tb_log_region_rate.previous_log_id.', 'PUBLICO');

COMMIT;
