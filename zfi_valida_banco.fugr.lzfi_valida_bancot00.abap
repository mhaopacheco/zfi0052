*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 12.09.2013 at 08:26:13 by user ABAP1_MQA
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZFI_VALIDA_BANCO................................*
DATA:  BEGIN OF STATUS_ZFI_VALIDA_BANCO              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZFI_VALIDA_BANCO              .
CONTROLS: TCTRL_ZFI_VALIDA_BANCO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZFI_VALIDA_BANCO              .
TABLES: ZFI_VALIDA_BANCO               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
