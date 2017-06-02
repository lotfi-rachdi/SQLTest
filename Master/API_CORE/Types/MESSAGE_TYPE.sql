CREATE OR REPLACE TYPE api_core."MESSAGE_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.MESSAGE_TYPE
--  DESCRIPTION : Objet type représentant un message ( issue de l'application Message PDA )
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.12.02 | Hocine HAMMOU
--          | Init
-- ***************************************************************************

(
INTERNATIONAL_SITE_ID  VARCHAR2(35)                     -- MASTER.SITE.SITE_INTERNATIONAL_ID
,MESSAGE_ID            NUMBER(15)                       -- MASTER.SENT_MESSAGE.SENT_MESSAGE_ID
,CREATION_DTM          DATE                             -- MASTER.SENT_MESSAGE.CREATION_DTM%TYPE
,SENDER                VARCHAR2(60)                     -- MASTER.SENT_MESSAGE.SENDER
,SUBJECT               VARCHAR2(120)                    -- MASTER.SENT_MESSAGE.SUBJECT
,MESSAGE_CONTENT       VARCHAR2(3000)                   -- MASTER.SENT_MESSAGE.MESSAGE_CONTENT
,POPUP                 VARCHAR2(50)                     -- CONFIG.POPUP_TYPE.POPUP_TYPE_NAME         - Liste des valeurs dans CONFIG.POPUP_TYPE
,FORM                  VARCHAR2(50)                     -- CONFIG.FORM_TYPE.FORM_TYPE_NAME           - Liste des valeurs dans CONFIG.FORM_TYPE - Ce champ est renseigne si l'attribut POPUP contient la valeur ACTION
,WITHRECEIPT           NUMBER(1)                        -- MASTER.SENT_MESSAGE.WITHRECEIPT           - Les valeurs possibles 0: sans accusé réception , 1: avec accusé réception
,WITHRECEIPT_DTM       TIMESTAMP      --WITH TIME ZONE  -- MASTER.SENT_MESSAGE_SITE_REL.WITHRECEIPT  - Null: si non lu , NON NULL alors renseigné avec la date et heure de lecture du message
,CONSTRUCTOR FUNCTION MESSAGE_TYPE(SELF IN OUT NOCOPY MESSAGE_TYPE) RETURN SELF AS RESULT

)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."MESSAGE_TYPE" 
-- ***************************************************************************
--  BODY TYPE   : API_CORE.MESSAGE_TYPE
--  DESCRIPTION : Méthodes de l'objet type représentant un message
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2015.12.02 | Hocine HAMMOU
--          | Init
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION MESSAGE_TYPE(SELF IN OUT NOCOPY MESSAGE_TYPE) RETURN SELF AS RESULT
  IS
  BEGIN
     SELF := MESSAGE_TYPE
        (
          INTERNATIONAL_SITE_ID => NULL
         ,MESSAGE_ID            => NULL
         ,CREATION_DTM          => NULL
         ,SENDER                => NULL
         ,SUBJECT               => NULL
         ,MESSAGE_CONTENT       => NULL
         ,POPUP                 => NULL
         ,FORM                  => NULL
         ,WITHRECEIPT           => NULL
         ,WITHRECEIPT_DTM       => NULL
        );
     RETURN;
  END;



END;

/