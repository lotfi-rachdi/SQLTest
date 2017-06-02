CREATE OR REPLACE PACKAGE BODY api_core.PCK_STATEMODE
-- ***************************************************************************
--  PACKAGE     : API_CORE.PCK_STATEMODE
--  DESCRIPTION : Web API de traitement des statemode
--                À 2015.08.04 c'est seulement pour enlever les indispo "manque de PDA"
--                si un site a activé son login
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.08.01 | Maria CASALS
--          | version initiale
--          |
-- ***************************************************************************
IS
c_packagename constant varchar2(30) := $$PLSQL_UNIT ;


-- ---------------------------------------------------------------------------
--  UNIT         : EndNOPDAIndispo
--  DESCRIPTION  : Pour la liste de SITE_iD reçus, s'il y a des indispos
--                 de type "pas de PDA associé", il met la date de fin à ces indispos
--  IN           : p_site_tab, table TAB_SITE_TYPE avec la liste de sites
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2015.08.04 | Maria CASALS
--          | version initiale
--  V01.001 | 2015.09.09 | Amadou YOUNSAH
--          | Renommage du type API_CORE.SITE_TAB_TYPE en API_CORE.TAB_SITE_TYPE
--  V01.002 | 2016.06.20 | Hocine HAMMOU
--          |            | Projet [10302] : Gestion du fuseau horaire pour les dates DATE_FROM et DATE_TO de la table MASTER.INDISPO
-- ---------------------------------------------------------------------------
PROCEDURE EndNOPDAIndispo(p_site_tab IN TAB_SITE_TYPE ) IS
  l_unit master_proc.PROC_LOG.PROC_NAME%TYPE := c_packagename||'.'||'EndNOPDAIndispo';
  l_start_date  master_proc.PROC_LOG.START_TIME%TYPE := systimestamp;
  l_requiredparams VARCHAR2(4000);

  -- requête optimisée pour trouver déjà les peux de sites avec indispos
  -- puis dans le traitement un par un nous allons mettre à jour l'indisponibilité
  CURSOR c_indispos (pc_instant in DATE) IS
      WITH src_sites AS
      (SELECT s.SITE_ID
       FROM TABLE(CAST( p_site_tab AS TAB_SITE_TYPE)) l  -- entry parameter is TAB_SITE_TYPE, so table of SITE_TYPE
       INNER JOIN MASTER.SITE s ON (UPPER(TRIM(s.SITE_INTERNATIONAL_ID)) = UPPER(TRIM(l.INTERNATIONAL_SITE_ID))
                                   )
      )
      , indispo_types AS
      (SELECT TYPE_ID FROM config.INDISPO_TYPE WHERE type_name = PCK_API_CONSTANTS.INDISPO_TYPE_MISSING_PDA_ASSOC
      )
      SELECT i.* -- nous voulons vraiment MASTER.INDISPO%ROWTYPE
      FROM   MASTER.INDISPO i
      INNER JOIN src_sites s ON (i.SITE_ID = s.SITE_ID)
      INNER JOIN indispo_types t ON (i.TYPE_ID = t.TYPE_ID)
      WHERE pc_instant >= (( FROM_TZ(CAST(i.DATE_FROM AS TIMESTAMP ) , 'EUROPE/PARIS' ) ) AT TIME ZONE 'UTC')                -- 20.06.2016  -- i.DATE_FROM
        AND pc_instant <  NVL((( FROM_TZ(CAST(i.DATE_TO AS TIMESTAMP ) , 'EUROPE/PARIS' ) ) AT TIME ZONE 'UTC'), SYSDATE +1) -- 20.06.2016  -- NVL(i.DATE_TO, SYSDATE +1)
      ;
   l_indispo c_indispos%ROWTYPE;
   l_statemode_result NUMBER;
BEGIN
   OPEN c_indispos (pc_instant => SYSTIMESTAMP);
   LOOP
      FETCH c_indispos INTO l_indispo;
      EXIT WHEN c_indispos%notfound;

      --pour chaque indispo, MAJ des colonnes
      l_indispo.DATE_TO         := systimestamp;
      l_indispo.LAST_UPDATE_DTM := systimestamp;
      l_indispo.COMMENTS        := CASE WHEN l_indispo.COMMENTS IS NOT NULL THEN l_indispo.COMMENTS|| ' - ' ELSE NULL END || 'Ended by WEB API';
      l_indispo.LAST_UPDATE_BY  := 'WEB API' ;

      -- FIN DE L'INDISPONIBILITE
      master_proc.PCK_STATE_MODE.UpdateIndispo(p_indispo => l_indispo, p_result => l_statemode_result );

   END LOOP;
   CLOSE c_indispos;

   MASTER_PROC.PCK_LOG.InsertLog_OK( p_procname => l_unit, p_start_time => l_start_date, p_result_detail => '[API_CORE] PROCESS : END UNAVAILABILITY OF NO PDA' );

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date, p_result_detail =>'[API_CORE] '||Dbms_Utility.format_error_stack || ' ' || Dbms_Utility.format_error_backtrace);
      RAISE;
END EndNOPDAIndispo;



END PCK_STATEMODE;

/