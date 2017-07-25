*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 12.09.2013 at 14:27:54 by user ABAP1_MQA
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZF110_LOCK......................................*
DATA:  BEGIN OF STATUS_ZF110_LOCK                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZF110_LOCK                    .
CONTROLS: TCTRL_ZF110_LOCK
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZF110_LOCK                    .
TABLES: ZF110_LOCK                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
