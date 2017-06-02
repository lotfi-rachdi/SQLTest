CREATE OR REPLACE PACKAGE api_core.PCK_MESSAGE_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_MESSAGE_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers MESSAGES
--                envoyés par le PDA via les WEB API
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.22 | Hocine HAMMOU
--          | Init
--          | Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
IS
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_MESSAGE_FOR_PDA';

PROCEDURE SetSiteMessageRead(p_message_pda IN api_core.PDA_MESSAGE_TYPE, p_FILE_ID OUT INTEGER );

PROCEDURE process_xmlfile_message( p_FILE_ID IN INTEGER );

END PCK_MESSAGE_FOR_PDA;

/