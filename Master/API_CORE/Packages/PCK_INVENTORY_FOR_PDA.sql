CREATE OR REPLACE PACKAGE api_core.PCK_INVENTORY_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_INVENTORY_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers INVENTORY
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
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_INVENTORY_FOR_PDA';

PROCEDURE SetInventory(p_inventory_pda IN api_core.PDA_INVENTORY_TYPE, p_FILE_ID OUT INTEGER );

PROCEDURE process_xmlfile_inventory( p_FILE_ID IN INTEGER );

END PCK_INVENTORY_FOR_PDA;

/