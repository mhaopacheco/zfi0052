*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZF110_LOCK
*   generation date: 12.09.2013 at 14:27:54 by user ABAP1_MQA
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZF110_LOCK         .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
