*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZBNKA_TRN
*   generation date: 12.09.2013 at 14:25:41 by user ABAP1_MQA
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZBNKA_TRN          .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
