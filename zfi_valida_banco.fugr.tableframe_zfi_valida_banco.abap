*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZFI_VALIDA_BANCO
*   generation date: 12.09.2013 at 08:26:13 by user ABAP1_MQA
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZFI_VALIDA_BANCO   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
