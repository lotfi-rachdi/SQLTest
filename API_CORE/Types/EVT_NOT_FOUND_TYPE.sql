CREATE OR REPLACE TYPE api_core."EVT_NOT_FOUND_TYPE"                                          FORCE UNDER api_core.EVT_TYPE
-- ***************************************************************************
--  TYPE        : API_CORE.EVT_NOT_FOUND_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement NOT FOUND reçu
--                par WEB SERVICES.
--                API_CORE.EVT_NOT_FOUND_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.01.10 | Hocine HAMMOU
--          | Création
--          | Projet [10472]
-- *******************************************************************************************************
( BARCODE             VARCHAR2(50)
, INVENTORY_STATE     VARCHAR2(50)
, INVENTORY_SESSION   DATE
, INVENTORY_ORIGIN    VARCHAR2(50) -- VALEURS POSSIBLES : TASK_MENU, DESKTOP ou MESSAGE
, INVENTORY_USE_CASE  VARCHAR2(50) -- VALEURS POSSIBLES : SHP_TO_DLV, DLV_TO_PRP, SHP_ANO_TO_DLV, DPF_TO_IRA, PRP_TO_IRA, DPF_TO_DPF, PRP_TO_PRP, DLV_TO_DLV, COL_TO_IRA, PKU_TO_PKU, NA_TO_SHP ou NOT_IN_PUDO


, CONSTRUCTOR FUNCTION EVT_NOT_FOUND_TYPE(SELF IN OUT NOCOPY EVT_NOT_FOUND_TYPE) RETURN SELF AS RESULT
, MEMBER FUNCTION TargetEventType (self in EVT_NOT_FOUND_TYPE) RETURN VARCHAR2
, MEMBER FUNCTION MissingMandatoryAttributes (p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."EVT_NOT_FOUND_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.EVT_NOT_FOUND_TYPE
--  DESCRIPTION : Description des attibuts de l'évènement NOT FOUND reçu
--                par WEB SERVICES.
--                API_CORE.EVT_NOT_FOUND_TYPE est un sous-type de API_CORE.EVT_TYPE
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V01.000 | 2017.01.10 | Hocine HAMMOU
--          | Création
--          | Projet [10472]
--          |
-- ***************************************************************************
IS
CONSTRUCTOR FUNCTION EVT_NOT_FOUND_TYPE(SELF IN OUT NOCOPY EVT_NOT_FOUND_TYPE) RETURN SELF AS RESULT
IS
BEGIN
   SELF := EVT_NOT_FOUND_TYPE
      (
        FIRM_PARCEL_ID          => NULL
      , BO_PARCEL_ID            => NULL
      , FIRM_ID                 => NULL
      , LOCAL_DTM               => NULL
      , INTERNATIONAL_SITE_ID   => NULL
      , BARCODE                 => NULL
      , INVENTORY_STATE         => NULL
      , INVENTORY_SESSION       => NULL
      , INVENTORY_ORIGIN        => NULL
      , INVENTORY_USE_CASE      => NULL
      );
   RETURN;
END;

 -- -----------------------------------------------------------------------------
 -- Fonction  : TargetEventType
 --    Renvoie le type d'évènement (exemple : DELIVERY ou PICKUP ou REFUSE ou INVENTORY...)
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION TargetEventType (self in EVT_NOT_FOUND_TYPE) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'TargetEventType';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result varchar2(100);
BEGIN

   RETURN PCK_API_CONSTANTS.c_evt_type_NOT_FOUND;

EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

 -- -----------------------------------------------------------------------------
 -- Fonction MissingMandatoryAttributes :
 --    Renvoie la liste d'attributes en erreur parce qu'obligatoires et non informés
 --    (donc si tout ok ça va renvoyer une liste vide) pour un NOT_FOUND
 -- -----------------------------------------------------------------------------
MEMBER FUNCTION MissingMandatoryAttributes ( p_relevant_properties IN OUT VARCHAR2) RETURN VARCHAR2
IS l_unit MASTER_PROC.PROC_LOG.PROC_NAME%TYPE := $$PLSQL_UNIT||'.'||'MissingMandatoryAttributes';
   l_start_date  MASTER_PROC.PROC_LOG.START_TIME%TYPE := systimestamp;
   l_result VARCHAR2(4000);
BEGIN

   l_result := api_core.EVT_TYPE.MissingMandatoryEvtAttributes(self);

   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_BARCODE );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_INVENTORY_STATE );
   p_relevant_properties := PCK_API_TOOLS.LIST(P_LIST => p_relevant_properties, p_item => PCK_API_CONSTANTS.c_PROP_INVENTORY_SESSION );

   RETURN l_result;
EXCEPTION
   WHEN OTHERS THEN
      MASTER_PROC.PCK_LOG.InsertLog_KO( p_procname => l_unit, p_start_time => l_start_date );
      RAISE;
END;

END;

/