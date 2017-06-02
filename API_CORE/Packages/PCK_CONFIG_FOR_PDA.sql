CREATE OR REPLACE PACKAGE api_core.PCK_CONFIG_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_CONFIG_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers CONFIG
--                envoyés par le PDA via les WEB API
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.25 | Hocine HAMMOU
--          | Init
--          | Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
IS
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_CONFIG_FOR_PDA';

PROCEDURE SetConfig(p_config_pda IN api_core.PDA_CONFIG_TYPE, p_FILE_ID OUT INTEGER );

PROCEDURE process_xmlfile_config( p_FILE_ID IN INTEGER );

END PCK_CONFIG_FOR_PDA;

/