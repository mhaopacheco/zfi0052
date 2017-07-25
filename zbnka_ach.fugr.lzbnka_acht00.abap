*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 12.09.2013 at 08:24:26 by user ABAP1_MQA
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZBNKA_ACH.......................................*
DATA:  BEGIN OF STATUS_ZBNKA_ACH                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZBNKA_ACH                     .
CONTROLS: TCTRL_ZBNKA_ACH
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZBNKA_ACH                     .
TABLES: ZBNKA_ACH                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
