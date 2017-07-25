*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZBNKA_OPR
*   generation date: 20.08.2013 at 15:54:50 by user ABAP2_ELIOT
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZBNKA_OPR          .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
