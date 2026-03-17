*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZAPI_LOGIN......................................*
DATA:  BEGIN OF STATUS_ZAPI_LOGIN                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZAPI_LOGIN                    .
CONTROLS: TCTRL_ZAPI_LOGIN
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZAPI_LOGIN                    .
TABLES: ZAPI_LOGIN                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
