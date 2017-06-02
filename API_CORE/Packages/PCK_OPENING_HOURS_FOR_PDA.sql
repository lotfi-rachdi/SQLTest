CREATE OR REPLACE PACKAGE api_core.PCK_OPENING_HOURS_FOR_PDA
-- ***************************************************************************
--  PACKAGE     : PCK_OPENING_HOURS_FOR_PDA
--  DESCRIPTION : Package gérant les fichiers OPENING HOURS
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
--          | Init Projet [10326] Migration PDA vers WebAPI
--          |
-- ***************************************************************************
is
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_OPENING_HOURS_FOR_PDA';

PROCEDURE SetSiteOpeningHours( p_opening_hours_pda IN api_core.PDA_OPENING_HOURS_TYPE, p_FILE_ID OUT INTEGER);

PROCEDURE process_xmlfile_openinghours( p_FILE_ID IN INTEGER );

END PCK_OPENING_HOURS_FOR_PDA;

/