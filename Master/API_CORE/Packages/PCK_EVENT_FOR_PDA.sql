CREATE OR REPLACE PACKAGE api_core.PCK_EVENT_FOR_PDA IS
-- ***************************************************************************
--  PACKAGE     : PCK_EVENT_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers T_EVENT et T_EVENT_PROPERTIES
--                envoyés par le PDA via les WEB API
---- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.04.18 | Hocine HAMMOU
--          | Init
--          | Projet [10326] Migration PDA vers WebAPI
-- ***************************************************************************

c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_EVENT_FOR_PDA';

PROCEDURE INS_EVT_FOR_PDA( p_evt_pda IN PDA_EVT_TYPE, p_FILE_ID OUT INTEGER)
;

PROCEDURE process_xmlfile_event( p_FILE_ID IN INTEGER )
;

END PCK_EVENT_FOR_PDA;

/