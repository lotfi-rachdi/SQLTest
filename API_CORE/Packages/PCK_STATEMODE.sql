CREATE OR REPLACE PACKAGE api_core.PCK_STATEMODE
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_STATEMODE
--  DESCRIPTION : Web API de traitement des statemode
--                À 2015.08.04 c'est seulement pour enlever les indispo "manque de PDA"
--                si un site a activé son login
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.08.01 | Maria CASALS
--          | version initiale
--  V01.001 | 2015.09.09 | Amadou YOUNSAH
--          | Renommage du type API_CORE.SITE_TAB_TYPE en API_CORE.TAB_SITE_TYPE          |
-- ***************************************************************************
IS

PROCEDURE EndNOPDAIndispo(p_site_tab IN TAB_SITE_TYPE );

END PCK_STATEMODE;

/