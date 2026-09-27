-- Esquema STAGE: copia bruta, sem tratamento. Hoje so existe aqui o que
-- viria de uma fonte fora do Postgres (MongoDB) - dado cadastral do proprio
-- Postgres (ex.: tb_last_water_bill) e tratado direto no SILVER, sem passar
-- por aqui, porque ja chega limpo.
CREATE SCHEMA IF NOT EXISTS stage;
