CREATE OR REPLACE PACKAGE api_core.PCK_INVENTORY
-- ***************************************************************************
--  PACKAGE     : PCK_INVENTORY
--  DESCRIPTION : Package gérant les fichiers INVENTORY
--                envoyés par la WEBAPP/Mobile via les WEB API
--                --> Invenataires sacoches
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.11.28 | Hocine HAMMOU
--          | [10472] Mise en place de l'inventaire matériel ( sacoches...)
-- ***************************************************************************
IS
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ;

PROCEDURE SetInventory(p_inventory IN api_core.INVENTORY_TYPE, p_FILE_ID OUT INTEGER );

PROCEDURE process_xmlfile_inventory( p_FILE_ID IN INTEGER );

END PCK_INVENTORY;

/