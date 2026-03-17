*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZENC_DEC_KEY....................................*
DATA:  BEGIN OF STATUS_ZENC_DEC_KEY                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZENC_DEC_KEY                  .
CONTROLS: TCTRL_ZENC_DEC_KEY
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZENC_DEC_KEY                  .
TABLES: ZENC_DEC_KEY                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
