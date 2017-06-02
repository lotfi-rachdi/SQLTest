CREATE OR REPLACE PACKAGE api_core.PCK_MONITORING
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_MONITORING
--  DESCRIPTION : Package de fonctionnalité dédié au MONITORING
--
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.09.22 | Hocine HAMMOU
--          | version initiale
--          |
-- ***************************************************************************
IS

c_retcode_Success CONSTANT NUMBER(1) := 0;
c_retcode_Warning CONSTANT NUMBER(1) := 1;
c_retcode_Error CONSTANT NUMBER(1) := 2;


--------------------------------------------------------------------------------
-- FONCTION : VERIFIE SI LES OBJETS DU SCHEMA API_CORE SONT VALIDES RETOURNE :
--            0 : Success
--            1 : Success avec warnings
--            2 : Error
--------------------------------------------------------------------------------
FUNCTION API_CORE_OK RETURN NUMBER;

END PCK_MONITORING;



/