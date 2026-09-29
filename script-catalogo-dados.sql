-- Popula tb_data_catalog: uma linha por coluna de cada tabela funcional do
-- schema (governança de dados). Não cobre as tabelas tb_log_* de auditoria
-- (script-audit.sql) — ver comentário em tables/tb_data_catalog.sql.

BEGIN;

INSERT INTO tb_data_catalog (table_name, column_name, data_type, description, business_rule, access_level) VALUES

-- tb_region
('tb_region', 'id', 'SERIAL', 'Identificador da região.', 'Chave primária.', 'PUBLICO'),
('tb_region', 'name', 'VARCHAR(30)', 'Nome da região — área com tarifa Sabesp real, não mais uma zona da capital.', 'Valores fixos (CHECK): GRANDE_SP, LINS, PRESIDENTE_PRUDENTE, ADAMANTINA_PIRAPOZINHO, BRAGANCA_PAULISTA. Único.', 'PUBLICO'),

-- tb_day_of_week
('tb_day_of_week', 'id', 'SERIAL', 'Identificador do dia da semana.', 'Chave primária.', 'PUBLICO'),
('tb_day_of_week', 'name', 'VARCHAR(20)', 'Nome do dia da semana.', 'Valores fixos (CHECK): SEGUNDA a DOMINGO. Único.', 'PUBLICO'),

-- tb_habit
('tb_habit', 'id', 'SERIAL', 'Identificador do hábito de consumo.', 'Chave primária.', 'PUBLICO'),
('tb_habit', 'name', 'VARCHAR(30)', 'Nome do hábito de consumo de água.', 'Valores fixos (CHECK), ex. BANHO LONGO, LAVAR CARRO. Único.', 'PUBLICO'),
('tb_habit', 'description', 'TEXT', 'Descrição opcional do hábito.', 'Sem restrição de formato.', 'PUBLICO'),

('tb_water_usage_type', 'id', 'SERIAL', 'Identificador do tipo de uso da água.', 'Chave primária.', 'PUBLICO'),
('tb_water_usage_type', 'name', 'VARCHAR(30)', 'Nome do tipo de uso da água na instalação industrial.', 'Valores fixos (CHECK): LIMPEZA, CONSUMO_HUMANO, PROCESSO_PRODUTIVO, IRRIGACAO. Único.', 'PUBLICO'),
('tb_water_usage_type', 'description', 'TEXT', 'Descrição opcional do tipo de uso.', 'Sem restrição de formato.', 'PUBLICO'),

-- tb_address
('tb_address', 'id', 'SERIAL', 'Identificador do endereço.', 'Chave primária.', 'INTERNO'),
('tb_address', 'region_id', 'INTEGER', 'Região à qual o endereço pertence.', 'FK obrigatória para tb_region.', 'INTERNO'),
('tb_address', 'cep', 'CHAR(8)', 'CEP do endereço.', '8 dígitos numéricos (CHECK regex). Único — cada CEP cadastrado só uma vez.', 'RESTRITO'),
('tb_address', 'city', 'VARCHAR(60)', 'Cidade do endereço.', 'Obrigatório.', 'INTERNO'),
('tb_address', 'state', 'VARCHAR(30)', 'Estado do endereço.', 'Obrigatório.', 'INTERNO'),

-- tb_user
('tb_user', 'id', 'SERIAL', 'Identificador do usuário.', 'Chave primária.', 'INTERNO'),
('tb_user', 'name', 'VARCHAR(100)', 'Nome completo do usuário.', 'Obrigatório.', 'RESTRITO'),
('tb_user', 'email', 'VARCHAR(255)', 'E-mail do usuário, usado como login.', 'Obrigatório e único.', 'SENSIVEL'),
('tb_user', 'password', 'VARCHAR(255)', 'Hash da senha do usuário.', 'Obrigatório. Nunca armazenar em texto plano.', 'SENSIVEL'),
('tb_user', 'phone', 'VARCHAR(15)', 'Telefone de contato do usuário.', 'Opcional.', 'SENSIVEL'),
('tb_user', 'birth_date', 'DATE', 'Data de nascimento do usuário.', 'Obrigatória. CHECK garante maioridade (>= 18 anos na data de cadastro).', 'SENSIVEL'),
('tb_user', 'registration_date', 'DATE', 'Data de cadastro do usuário no sistema.', 'Padrão CURRENT_DATE.', 'INTERNO'),
('tb_user', 'is_active', 'BOOLEAN', 'Indica se o usuário está ativo no sistema.', 'Padrão TRUE. Usuário inativo não pode operar (ver fn_user_is_active).', 'RESTRITO'),
('tb_user', 'is_admin', 'BOOLEAN', 'Indica se o usuário é administrador.', 'Padrão FALSE.', 'RESTRITO'),
('tb_user', 'is_manager', 'BOOLEAN', 'Indica se o usuário é gerente, papel usado na versão comercial do produto.', 'Padrão FALSE.', 'RESTRITO'),

-- tb_property_classification
('tb_property_classification', 'id', 'SERIAL', 'Identificador da categoria de imóvel.', 'Chave primária.', 'PUBLICO'),
('tb_property_classification', 'name', 'VARCHAR(50)', 'Nome específico da categoria (8 valores: RESIDENCIAL_NORMAL, RESIDENCIAL_SOCIAL, RESIDENCIAL_FAVELA, RESIDENCIAL_ESPECIAL, COMERCIAL_NORMAL_INDUSTRIAL, COMERCIAL_ESPECIAL, COMERCIAL_ENTIDADE_ASSISTENCIA_SOCIAL, PUBLICA_COM_CONTRATO).', 'Único.', 'PUBLICO'),
('tb_property_classification', 'group_name', 'VARCHAR(20)', 'Grupo amplo da categoria, usado pelo motor de detecção de vazamento (ex. regra de madrugada não vale pra COMERCIAL).', 'Valores fixos (CHECK): RESIDENCIAL, COMERCIAL.', 'PUBLICO'),

('tb_organization', 'id', 'SERIAL', 'Identificador da organização (empresa gestora de imóveis industriais/comerciais).', 'Chave primária.', 'INTERNO'),
('tb_organization', 'corporate_name', 'VARCHAR(150)', 'Razão social da organização.', 'Obrigatório.', 'RESTRITO'),
('tb_organization', 'trade_name', 'VARCHAR(150)', 'Nome fantasia da organização.', 'Obrigatório.', 'INTERNO'),
('tb_organization', 'cnpj', 'CHAR(14)', 'CNPJ da organização.', '14 dígitos numéricos (CHECK regex). Obrigatório e único.', 'RESTRITO'),
('tb_organization', 'business_segment', 'VARCHAR(20)', 'Segmento de atuação da organização.', 'Valores fixos (CHECK): VAREJO, INDUSTRIA, CONDOMINIO, FACILITIES.', 'INTERNO'),
('tb_organization', 'declared_unit_count', 'INTEGER', 'Quantidade de unidades declarada pela organização no cadastro.', 'Opcional. CHECK: se preenchida, deve ser maior que zero. Estimativa declarada, não contagem real de tb_property.', 'INTERNO'),
('tb_organization', 'registration_date', 'DATE', 'Data de cadastro da organização.', 'Padrão CURRENT_DATE.', 'INTERNO'),

-- tb_property
('tb_property', 'id', 'SERIAL', 'Identificador do imóvel.', 'Chave primária.', 'INTERNO'),
('tb_property', 'name', 'VARCHAR(100)', 'Nome/apelido do imóvel.', 'Obrigatório. Único em conjunto com address_id.', 'INTERNO'),
('tb_property', 'type', 'VARCHAR(20)', 'Tipo do imóvel.', 'Valores fixos (CHECK): CASA, PRÉDIO.', 'INTERNO'),
('tb_property', 'classification_id', 'INTEGER', 'Categoria do imóvel, usada na tarifa por categoria e na detecção de vazamento.', 'FK obrigatória para tb_property_classification.', 'INTERNO'),
('tb_property', 'address_id', 'INTEGER', 'Endereço do imóvel.', 'FK obrigatória para tb_address.', 'INTERNO'),
('tb_property', 'organization_id', 'INTEGER', 'Organização gestora do imóvel, quando aplicável.', 'FK opcional para tb_organization. NULL = imóvel residencial de pessoa física; preenchido = unidade industrial/comercial de uma organização.', 'INTERNO'),
('tb_property', 'built_area_m2', 'NUMERIC(10,2)', 'Área construída do imóvel, em m².', 'Opcional. CHECK: se preenchida, deve ser maior que zero. Usada para normalizar consumo (L/m²) no ranking de eficiência entre instalações.', 'INTERNO'),
('tb_property', 'registration_date', 'DATE', 'Data de cadastro do imóvel.', 'Padrão CURRENT_DATE.', 'INTERNO'),

('tb_property_operational_profile', 'property_id', 'INTEGER', 'Imóvel ao qual o perfil operacional pertence.', 'Chave primária e FK obrigatória para tb_property ao mesmo tempo (extensão 1:1). Só imóveis com cadastro industrial completo ganham linha aqui.', 'INTERNO'),
('tb_property_operational_profile', 'main_water_source', 'VARCHAR(20)', 'Fonte principal de água da instalação industrial.', 'Valores fixos (CHECK): CONCESSIONARIA, POCO_ARTESIANO, CISTERNA, REUSO.', 'INTERNO'),

('tb_property_shift', 'id', 'SERIAL', 'Identificador do turno.', 'Chave primária.', 'INTERNO'),
('tb_property_shift', 'property_id', 'INTEGER', 'Imóvel ao qual o turno pertence.', 'FK obrigatória para tb_property.', 'INTERNO'),
('tb_property_shift', 'start_time', 'TIME', 'Horário de início do turno.', 'Obrigatório.', 'INTERNO'),
('tb_property_shift', 'end_time', 'TIME', 'Horário de fim do turno.', 'Obrigatório. CHECK: deve ser posterior ao horário de início.', 'INTERNO'),

('tb_property_water_usage', 'id', 'SERIAL', 'Identificador do vínculo imóvel-uso da água.', 'Chave primária.', 'INTERNO'),
('tb_property_water_usage', 'property_id', 'INTEGER', 'Imóvel vinculado ao tipo de uso.', 'FK obrigatória para tb_property. Único em conjunto com water_usage_type_id.', 'INTERNO'),
('tb_property_water_usage', 'water_usage_type_id', 'INTEGER', 'Tipo de uso da água vinculado ao imóvel.', 'FK obrigatória para tb_water_usage_type.', 'INTERNO'),

('tb_property_operation_day', 'id', 'SERIAL', 'Identificador do vínculo imóvel-dia de operação.', 'Chave primária.', 'INTERNO'),
('tb_property_operation_day', 'property_id', 'INTEGER', 'Imóvel vinculado ao dia de operação.', 'FK obrigatória para tb_property. Único em conjunto com day_of_week_id.', 'INTERNO'),
('tb_property_operation_day', 'day_of_week_id', 'INTEGER', 'Dia da semana em que o imóvel opera.', 'FK obrigatória para tb_day_of_week.', 'INTERNO'),

-- tb_user_property
('tb_user_property', 'id', 'SERIAL', 'Identificador do vínculo usuário-imóvel.', 'Chave primária.', 'INTERNO'),
('tb_user_property', 'user_id', 'INTEGER', 'Usuário vinculado ao imóvel.', 'FK obrigatória para tb_user. Único em conjunto com property_id.', 'INTERNO'),
('tb_user_property', 'property_id', 'INTEGER', 'Imóvel vinculado ao usuário.', 'FK obrigatória para tb_property.', 'INTERNO'),
('tb_user_property', 'association_date', 'DATE', 'Data em que o vínculo foi criado.', 'Padrão CURRENT_DATE.', 'INTERNO'),

('tb_user_organization', 'id', 'SERIAL', 'Identificador do vínculo usuário-organização.', 'Chave primária.', 'INTERNO'),
('tb_user_organization', 'user_id', 'INTEGER', 'Usuário vinculado à organização.', 'FK obrigatória para tb_user. Único em conjunto com organization_id. Sem diferenciação de papel/hierarquia entre usuários vinculados.', 'INTERNO'),
('tb_user_organization', 'organization_id', 'INTEGER', 'Organização vinculada ao usuário.', 'FK obrigatória para tb_organization.', 'INTERNO'),
('tb_user_organization', 'association_date', 'DATE', 'Data em que o vínculo foi criado.', 'Padrão CURRENT_DATE.', 'INTERNO'),

-- tb_device
('tb_device', 'id', 'SERIAL', 'Identificador interno do dispositivo.', 'Chave primária.', 'INTERNO'),
('tb_device', 'device_id', 'VARCHAR(100)', 'Identificador físico do hardware (ESP32/Arduino), o mesmo usado no payload de telemetria.', 'Obrigatório e único.', 'INTERNO'),
('tb_device', 'property_id', 'INTEGER', 'Imóvel onde o dispositivo está instalado.', 'FK obrigatória para tb_property.', 'INTERNO'),
('tb_device', 'is_active', 'BOOLEAN', 'Indica se o dispositivo está ativo.', 'Padrão TRUE. Dispositivo inativo não conta pra fn_user_can_estimate.', 'INTERNO'),
('tb_device', 'installation_date', 'DATE', 'Data de instalação do dispositivo.', 'Padrão CURRENT_DATE.', 'INTERNO'),

-- tb_region_rate
('tb_region_rate', 'id', 'SERIAL', 'Identificador da tarifa.', 'Chave primária.', 'PUBLICO'),
('tb_region_rate', 'region_id', 'INTEGER', 'Região à qual a tarifa se aplica.', 'FK obrigatória para tb_region.', 'PUBLICO'),
('tb_region_rate', 'classification_id', 'INTEGER', 'Categoria de imóvel à qual a tarifa se aplica.', 'FK obrigatória para tb_property_classification.', 'PUBLICO'),
('tb_region_rate', 'm3_value', 'NUMERIC(10,2)', 'Valor da tarifa por m³.', 'CHECK: deve ser maior que zero.', 'PUBLICO'),
('tb_region_rate', 'initial_validity', 'DATE', 'Início da vigência da tarifa.', 'Obrigatória. Única em conjunto com region_id e classification_id (não pode haver duas tarifas com a mesma data de início pra mesma combinação).', 'PUBLICO'),
('tb_region_rate', 'final_validity', 'DATE', 'Fim da vigência da tarifa.', 'NULL enquanto vigente. CHECK: se preenchida, deve ser >= initial_validity. Fechada automaticamente por sp_change_region_rate ao cadastrar uma tarifa nova pra mesma combinação.', 'PUBLICO'),

-- tb_user_habit
('tb_user_habit', 'id', 'SERIAL', 'Identificador do hábito do usuário.', 'Chave primária.', 'RESTRITO'),
('tb_user_habit', 'user_id', 'INTEGER', 'Usuário dono do hábito.', 'FK obrigatória para tb_user. Único em conjunto com habit_id.', 'RESTRITO'),
('tb_user_habit', 'habit_id', 'INTEGER', 'Hábito associado ao usuário.', 'FK obrigatória para tb_habit.', 'RESTRITO'),
('tb_user_habit', 'frequency', 'INTEGER', 'Frequência semanal do hábito.', 'CHECK: deve ser maior que zero.', 'RESTRITO'),

-- tb_user_habit_day
('tb_user_habit_day', 'id', 'SERIAL', 'Identificador do dia do hábito.', 'Chave primária.', 'RESTRITO'),
('tb_user_habit_day', 'user_habit_id', 'INTEGER', 'Hábito do usuário ao qual o dia se refere.', 'FK obrigatória para tb_user_habit. Único em conjunto com day_of_week_id.', 'RESTRITO'),
('tb_user_habit_day', 'day_of_week_id', 'INTEGER', 'Dia da semana em que o hábito ocorre.', 'FK obrigatória para tb_day_of_week.', 'RESTRITO'),

-- tb_last_water_bill
('tb_last_water_bill', 'id', 'SERIAL', 'Identificador da conta de água.', 'Chave primária.', 'INTERNO'),
('tb_last_water_bill', 'user_id', 'INTEGER', 'Usuário dono da conta.', 'FK obrigatória para tb_user. Único em conjunto com month.', 'INTERNO'),
('tb_last_water_bill', 'month', 'DATE', 'Mês de referência da conta.', 'CHECK: deve representar o primeiro dia do mês.', 'INTERNO'),
('tb_last_water_bill', 'total_value', 'NUMERIC(10,2)', 'Valor total pago na conta.', 'CHECK: deve ser maior ou igual a zero. Dado financeiro ligado diretamente a uma pessoa.', 'RESTRITO'),
('tb_last_water_bill', 'm3_value', 'NUMERIC(10,2)', 'Consumo em m³ registrado na conta.', 'CHECK: deve ser maior ou igual a zero.', 'RESTRITO'),

('tb_investment_scenario', 'id', 'SERIAL', 'Identificador do cenário de investimento em eficiência hídrica.', 'Chave primária.', 'PUBLICO'),
('tb_investment_scenario', 'organization_id', 'INTEGER', 'Organização à qual o cenário pertence.', 'FK opcional para tb_organization. NULL = cenário de referência global, disponível para qualquer organização.', 'INTERNO'),
('tb_investment_scenario', 'name', 'VARCHAR(100)', 'Nome do cenário de investimento.', 'Obrigatório.', 'PUBLICO'),
('tb_investment_scenario', 'investment_value', 'NUMERIC(10,2)', 'Valor do investimento inicial estimado.', 'CHECK: deve ser maior ou igual a zero. Valores pesquisados (fonte citada no dataload), não fictícios.', 'PUBLICO'),
('tb_investment_scenario', 'reduction_pct', 'NUMERIC(5,2)', 'Percentual estimado de redução de consumo com o cenário.', 'CHECK: entre 0 e 100.', 'PUBLICO'),
('tb_investment_scenario', 'annual_savings_value', 'NUMERIC(10,2)', 'Economia estimada em um ano com o cenário.', 'CHECK: deve ser maior ou igual a zero.', 'PUBLICO'),
('tb_investment_scenario', 'payback_months', 'NUMERIC(6,1)', 'Tempo estimado de retorno do investimento, em meses.', 'Opcional. CHECK: se preenchido, deve ser maior ou igual a zero.', 'PUBLICO'),
('tb_investment_scenario', 'description', 'TEXT', 'Descrição do cenário de investimento.', 'Sem restrição de formato.', 'PUBLICO'),

-- tb_user_access_log
('tb_user_access_log', 'id', 'SERIAL', 'Identificador do registro de acesso.', 'Chave primária.', 'INTERNO'),
('tb_user_access_log', 'user_id', 'INTEGER', 'Usuário que realizou o acesso.', 'FK obrigatória para tb_user.', 'INTERNO'),
('tb_user_access_log', 'access_channel', 'VARCHAR(20)', 'Canal utilizado no acesso.', 'Opcional. Valores fixos (CHECK): WEB, MOBILE, CHATBOT.', 'INTERNO'),
('tb_user_access_log', 'accessed_at', 'TIMESTAMP', 'Data e hora em que o acesso foi registrado.', 'Padrão CURRENT_TIMESTAMP.', 'INTERNO'),

-- tb_log_rpa
('tb_log_rpa', 'id', 'SERIAL', 'Identificador da execução do RPA.', 'Chave primária.', 'INTERNO'),
('tb_log_rpa', 'started_at', 'TIMESTAMP', 'Início da execução.', 'Padrão CURRENT_TIMESTAMP.', 'INTERNO'),
('tb_log_rpa', 'finished_at', 'TIMESTAMP', 'Fim da execução.', 'NULL enquanto a execução está em andamento.', 'INTERNO'),
('tb_log_rpa', 'status', 'VARCHAR(10)', 'Status da execução.', 'Valores fixos (CHECK): RUNNING, SUCCESS, ERROR. Padrão RUNNING.', 'INTERNO'),
('tb_log_rpa', 'inserted_count', 'INTEGER', 'Quantidade de registros inseridos na execução.', 'CHECK: não pode ser negativo. Padrão 0.', 'INTERNO'),
('tb_log_rpa', 'updated_count', 'INTEGER', 'Quantidade de registros atualizados na execução.', 'CHECK: não pode ser negativo. Padrão 0.', 'INTERNO'),
('tb_log_rpa', 'deleted_count', 'INTEGER', 'Quantidade de registros excluídos na execução.', 'CHECK: não pode ser negativo. Padrão 0.', 'INTERNO'),
('tb_log_rpa', 'validation_error_count', 'INTEGER', 'Quantidade de erros de validação na execução.', 'CHECK: não pode ser negativo. Padrão 0.', 'INTERNO'),
('tb_log_rpa', 'error_message', 'TEXT', 'Mensagem de erro, quando a execução falha.', 'NULL quando não há erro.', 'INTERNO'),

-- tb_backup_restore_log
('tb_backup_restore_log', 'id', 'SERIAL', 'Identificador do registro de teste de backup/restauração.', 'Chave primária.', 'INTERNO'),
('tb_backup_restore_log', 'started_at', 'TIMESTAMP', 'Início do teste de restauração.', 'Padrão CURRENT_TIMESTAMP.', 'INTERNO'),
('tb_backup_restore_log', 'finished_at', 'TIMESTAMP', 'Fim do teste de restauração.', 'NULL enquanto o teste está em andamento.', 'INTERNO'),
('tb_backup_restore_log', 'status', 'VARCHAR(10)', 'Status da verificação daquela tabela.', 'Valores fixos (CHECK): RUNNING, SUCCESS, ERROR. Padrão RUNNING.', 'INTERNO'),
('tb_backup_restore_log', 'table_name', 'VARCHAR(60)', 'Tabela verificada nesse teste de restauração.', 'Obrigatório — uma linha por tabela conferida.', 'INTERNO'),
('tb_backup_restore_log', 'expected_row_count', 'INTEGER', 'Quantidade de linhas esperada, conforme o manifesto gerado no backup.', 'CHECK: não pode ser negativo.', 'INTERNO'),
('tb_backup_restore_log', 'restored_row_count', 'INTEGER', 'Quantidade de linhas realmente restauradas no banco descartável.', 'CHECK: não pode ser negativo. NULL se a tabela nem foi restaurada.', 'INTERNO'),
('tb_backup_restore_log', 'note', 'TEXT', 'Observação livre sobre a execução (ex. origem do teste).', 'Opcional.', 'INTERNO');

COMMIT;
