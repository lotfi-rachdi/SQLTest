CREATE OR REPLACE PACKAGE api_core.PCK_PERIOD_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_PERIOD_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers PERIOD
--                envoyés par le PDA via les WEB API
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.21 | Hocine HAMMOU
--          | Init
--          | Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************
IS

c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_PERIOD_FOR_PDA';

PROCEDURE SET_PERIOD( p_period_pda IN api_core.PDA_PERIOD_TYPE, p_FILE_ID OUT INTEGER);

PROCEDURE process_xmlfile_period ( p_FILE_ID IN INTEGER );

END PCK_PERIOD_FOR_PDA;

/