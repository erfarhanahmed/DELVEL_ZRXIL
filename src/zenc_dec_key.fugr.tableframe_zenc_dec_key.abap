*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZENC_DEC_KEY
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZENC_DEC_KEY       .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
