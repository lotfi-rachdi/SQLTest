CREATE OR REPLACE PACKAGE BODY api_core.PCK_MONITORING
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
c_packagename CONSTANT VARCHAR2(30)         := $$PLSQL_UNIT ;
c_SCHEMA_API_CORE CONSTANT VARCHAR2(30)     := 'API_CORE';
c_OBJECT_STATUS_VALID CONSTANT VARCHAR2(10) := 'VALID';

-- ---------------------------------------------------------------------------
--  UNIT         : API_CORE_OK
--  DESCRIPTION  :
--  IN           :
--  OUT          :
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.09.22 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION API_CORE_OK
RETURN NUMBER
IS
  l_unit        MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'API_CORE_OK';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_resultat    NUMBER(1);

  l_OWNER       VARCHAR2(20);
  l_OBJECT_TYPE VARCHAR2(30);
  l_OBJECT_NAME VARCHAR2(30);
  l_STATUS      VARCHAR2(25);

BEGIN

   BEGIN
      SELECT SUBSTR(o.OWNER,1,20), SUBSTR(o.OBJECT_TYPE,1,30), SUBSTR(o.OBJECT_NAME,1,30), SUBSTR(o.STATUS,1,25)
      INTO l_OWNER, l_OBJECT_TYPE, l_OBJECT_NAME, l_STATUS
      FROM ALL_objects o
      WHERE o.OWNER = c_SCHEMA_API_CORE
      AND o.STATUS != c_OBJECT_STATUS_VALID
      ORDER BY o.OWNER,o.OBJECT_TYPE;
      l_resultat := c_retcode_Error; -- PRESENCE D'UN OBJET NON VALIDE
      RETURN l_resultat;
   EXCEPTION
      WHEN TOO_MANY_ROWS THEN
         l_resultat := c_retcode_Error; -- PRESENCE DE PLUSIEURS OBJECTS INVALIDES
         RETURN l_resultat;
      WHEN NO_DATA_FOUND THEN
         l_resultat := c_retcode_Success; -- TOUT EST OK
         RETURN l_resultat;
      WHEN OTHERS THEN
         MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
         RAISE;
   END;
EXCEPTION
   WHEN OTHERS THEN
      l_resultat := c_retcode_Error; --PRESENCE D'OBJETS NON VALIDES
      RETURN l_resultat;
END API_CORE_OK;

END PCK_MONITORING;



/