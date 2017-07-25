*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 20.08.2013 at 15:54:50 by user ABAP2_ELIOT
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZBNKA_OPR.......................................*
DATA:  BEGIN OF STATUS_ZBNKA_OPR                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZBNKA_OPR                     .
CONTROLS: TCTRL_ZBNKA_OPR
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZBNKA_OPR                     .
TABLES: ZBNKA_OPR                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
