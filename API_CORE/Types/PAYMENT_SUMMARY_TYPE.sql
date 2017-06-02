CREATE OR REPLACE TYPE api_core."PAYMENT_SUMMARY_TYPE"                                          FORCE AS OBJECT
-- ***************************************************************************
--  TYPE        : API_CORE.PAYMENT_SUMMARY_TYPE
--  DESCRIPTION : Description de l'objet type PAYMENT SUMMARY
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.12.20 | Hocine HAMMOU
--          | [10472] Mise en place de la liste des paiements
--          |
-- ***************************************************************************
(
FIRM_PARCEL_ID              VARCHAR2(50) -- REFERENCE COLIS
,PAYMENT_PRESTATION         VARCHAR2(25) -- COD, ROD ou DOO
,PAYMENT_DATE               DATE         -- DATE PAIEMENT EN UTC
,AMOUNT_PAID                NUMBER(15,3) -- MONTANT PAYE MASTER.PARCEL.COD_AMOUNT%TYPEDATE
,MEANS_PAYMENT_ID           VARCHAR2(20) -- MOYEN DE PAIEMENT UTILISE

, CONSTRUCTOR FUNCTION PAYMENT_SUMMARY_TYPE(SELF IN OUT NOCOPY PAYMENT_SUMMARY_TYPE) RETURN SELF AS RESULT
)
INSTANTIABLE
NOT FINAL

/
CREATE OR REPLACE TYPE BODY api_core."PAYMENT_SUMMARY_TYPE" 
-- ***************************************************************************
--  TYPE BODY   : API_CORE.PAYMENT_SUMMARY_TYPE
--  DESCRIPTION : Description de l'objet type PAYMENT SUMMARY
-- ---------------------------------------------------------------------------
--          | DATE       | AUTHOR
--          | DESCRIPTION
-- ---------------------------------------------------------------------------
--  V00.000 | 2016.12.20 | Hocine HAMMOU
--          | [10472] Mise en place de la liste des paiements
--          |
-- ***************************************************************************
IS
  CONSTRUCTOR FUNCTION PAYMENT_SUMMARY_TYPE(SELF IN OUT NOCOPY PAYMENT_SUMMARY_TYPE) RETURN SELF AS RESULT
  IS
  BEGIN
     SELF := PAYMENT_SUMMARY_TYPE
        (
          FIRM_PARCEL_ID     => NULL
         ,PAYMENT_PRESTATION => NULL
         ,PAYMENT_DATE       => NULL
         ,AMOUNT_PAID        => NULL
         ,MEANS_PAYMENT_ID   => NULL
        );
     RETURN;
  END;


END;

/