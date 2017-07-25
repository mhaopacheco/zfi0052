*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 12.09.2013 at 14:25:41 by user ABAP1_MQA
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZBNKA_TRN.......................................*
DATA:  BEGIN OF STATUS_ZBNKA_TRN                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZBNKA_TRN                     .
CONTROLS: TCTRL_ZBNKA_TRN
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZBNKA_TRN                     .
TABLES: ZBNKA_TRN                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
