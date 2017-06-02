CREATE OR REPLACE PACKAGE api_core.PCK_LOG
-- ***************************************************************************
--  PACKAGE     : PCK_LOG
--  DESCRIPTION : Package pour gérer la log envoyé par les WEB API
--
-- ---------------------------------------------------------------------------
--  CUSTOMER : PICKUP
--  PROJECT  :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2016.07.05 | Hocine HAMMOU
--          | Init
--          |
-- ***************************************************************************
IS
c_packagename  CONSTANT VARCHAR2(30) := $$PLSQL_UNIT ; -- 'PCK_LOG';

PROCEDURE SetLog( p_log IN api_core.LOG_TYPE, p_FILE_ID OUT INTEGER);

PROCEDURE process_file_log( p_FILE_ID IN INTEGER );

END PCK_LOG;

/