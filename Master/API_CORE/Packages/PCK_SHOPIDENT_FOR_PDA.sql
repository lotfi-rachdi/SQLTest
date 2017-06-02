CREATE OR REPLACE PACKAGE api_core.PCK_SHOPIDENT_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_SHOPIDENT_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers SHOPIDENT
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
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_SHOPIDENT_FOR_PDA';

PROCEDURE SetShopident(p_shopident_pda IN api_core.PDA_SHOPIDENT_TYPE, p_FILE_ID OUT INTEGER );

PROCEDURE process_xmlfile_shopident( p_FILE_ID IN INTEGER );

END PCK_SHOPIDENT_FOR_PDA;

/