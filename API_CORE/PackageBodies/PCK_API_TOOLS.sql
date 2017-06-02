CREATE OR REPLACE PACKAGE BODY api_core.PCK_API_TOOLS
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_API_TOOLS
--  DESCRIPTION : Package à très bas niveau avec des fonctions simples
--                Il ne peut appeller que PCK_API_CONSTANTS
--                Il ne peut faire référence aux TYPES parce que justement
--                les types vont s'en servir
--
--                En principe à ne pas être accédé en dehors du schema API_CORE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.17 | Maria CASALS
--          | version initiale
--  V01.100 | 2015.09.18 | Hocine HAMMOU
--            Ajout de la fonction F_ELAPSED_MILISECONDS
-- ***************************************************************************
IS
c_packagename constant varchar2(30) := $$PLSQL_UNIT ;

-- ---------------------------------------------------------------------------
--  UNIT         : LIST
--  DESCRIPTION  : Fonction qui permet de créer une liste de valeurs avec
--                 choix du séparateur
--  IN           : p_list   : liste d'élements en format chaine de caractères
--               : p_item   : nouveau élement à rajouter
--               : p_sep    : charactère séparateur, par défaut virgule
--  OUT          : l_result : retourne une liste de valeurs
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.08 | Hocine HAMMOU
--          | version initiale (ailleurs)
--          |
--  V01.010 | 2015.07.17 | Maria CASALS
--          | mouvement vers ce package
-- ---------------------------------------------------------------------------
FUNCTION LIST (P_LIST IN VARCHAR, p_item IN VARCHAR2, P_SEP IN VARCHAR2 DEFAULT ',')  RETURN VARCHAR IS
  l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'LIST';
  l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_result VARCHAR2(4000);
BEGIN
   if p_list is null then l_result := p_item; else l_result:= p_list ||p_sep||p_item; end if;
   return l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END LIST;


-- ---------------------------------------------------------------------------
--  UNIT         : ITEM_IN_LIST
--  DESCRIPTION  : Fonction qui détermine si un élement est dans une liste
--                 choix du séparateur
--  IN           : p_list   : liste d'élements en format chaine de caractères
--               : p_item   : élement à chercher
--               : p_sep    : charactère séparateur, par défaut virgule
--  OUT          : l_result : dit si oui ou non l'élément fait partie de la liste
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.17 | Maria CASALS
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION ITEM_IN_LIST (P_LIST IN VARCHAR, p_item IN VARCHAR2, P_SEP IN VARCHAR2 DEFAULT ',')  RETURN BOOLEAN IS
   l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'ITEM_IN_LIST';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result BOOLEAN;
   l_item_first  VARCHAR2(500);
   l_item_middle VARCHAR2(500);
   l_item_last   VARCHAR2(500);
BEGIN
   l_item_first  := p_item||p_sep;
   l_item_middle := p_sep||p_item||p_sep;
   l_item_last   := p_sep||p_item;

   if p_list = p_item -- only this item in the list
   or instr (p_list, l_item_first)  = 1 -- first element in the first place, followed by separator              -- LIKE would consider underscore as special pattern-matching character -- p_list like p_item||p_sep||'%'
   or instr (p_list, l_item_middle) > 0 -- middle element surrounded by separators                              -- LIKE would consider underscore as special pattern-matching character -- p_list like '%'||p_sep||p_item||p_sep||'%'
   or instr (p_list, l_item_last)   = length(p_list) - length(l_item_last) + 1 -- last element just at the end  -- LIKE would consider underscore as special pattern-matching character -- p_list like '%'||p_sep||p_item
   then l_result := TRUE;
   else l_result := FALSE;
   END IF;

   return l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END ITEM_IN_LIST;


-- ---------------------------------------------------------------------------
--  UNIT         : F_ELAPSED_MILISECONDS
--  DESCRIPTION  : Fonction qui calucl la différence em milliseconde entre deux TIMESTAMP
--                 choix du séparateur
--  IN           : p_timeSTAMP_before  : TIMESTAMP
--               : p_timeSTAMP_after   : TIMESTAMP
--               : p_sep    : charactère séparateur, par défaut virgule
--  OUT          : returns elapsed miliseconds between two TimeStamps
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.09.18 | Hocine HAMMOU
--          | version initiale
-- ---------------------------------------------------------------------------
FUNCTION f_elapsed_miliseconds
( p_timeSTAMP_before IN TIMESTAMP
, p_timeSTAMP_after  IN TIMESTAMP
) RETURN FLOAT
IS
   l_res FLOAT;
BEGIN
   l_res :=
       (  (extract(hour   from p_timeSTAMP_after)-extract(hour   from p_timeSTAMP_before))*3600  -- 1 hour = 3600 seconds
        + (extract(minute from p_timeSTAMP_after)-extract(minute from p_timeSTAMP_before))*60    -- 1 minute = 60 seconds
        + (extract(second from p_timeSTAMP_after)-extract(second from p_timeSTAMP_before))       -- seconds, with decimal positions
       )*1000
      ;
   RETURN l_res;
END f_elapsed_miliseconds;


-- ---------------------------------------------------------------------------
--  UNIT         : convert_timeZONE
--  DESCRIPTION  : Restitution d'une Date avec TimeZone
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.07.28 | Maria CASALS
--          | version initiale
--  IN      | p_TIMESTWITHZONE : Date sans TimeZone
--          | p_tz : TimeZone
--  OUT     | Date avec TimeZone
-- ---------------------------------------------------------------------------
FUNCTION convert_timeZONE ( p_TIMESTWITHZONE in TIMESTAMP WITH TIME ZONE, p_tz IN VARCHAR2) RETURN DATE
AS -- pour contourner le bug, comme http://www.dbforums.com/showthread.php?1628036-timezone-variable-in-PL-SQL
   l_retval DATE;
BEGIN
   l_retval := p_TIMESTWITHZONE AT TIME ZONE p_tz ;
   RETURN l_retval;
END convert_timeZONE;



END PCK_API_TOOLS;

/