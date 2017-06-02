CREATE OR REPLACE PACKAGE api_core.PCK_UPGRADE_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_UPGRADE_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers UPGRADE
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
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_UPGRADE_FOR_PDA';

PROCEDURE SetUpgrade(p_upgrade_pda IN api_core.PDA_UPGRADE_TYPE, p_FILE_ID OUT INTEGER );

PROCEDURE process_xmlfile_upgrade( p_FILE_ID IN INTEGER );

END PCK_UPGRADE_FOR_PDA;


/