*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZRXIL_API.......................................*
DATA:  BEGIN OF STATUS_ZRXIL_API                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZRXIL_API                     .
CONTROLS: TCTRL_ZRXIL_API
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZRXIL_API                     .
TABLES: ZRXIL_API                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
