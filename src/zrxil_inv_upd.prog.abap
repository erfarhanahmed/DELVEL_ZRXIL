*&---------------------------------------------------------------------*
*& Report ZRXIL_INV_UPD
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zrxil_inv_upd.

TABLES : bkpf ,zfi_rxil_inv.

DATA : lv_gjahr TYPE gjahr.
DATA : wa_inv TYPE zfi_rxil_inv.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS :
  s_bukrs  FOR   bkpf-bukrs OBLIGATORY NO-EXTENSION NO INTERVALS DEFAULT '1000' ,            " Company Code
  s_belnr  FOR   bkpf-belnr OBLIGATORY NO INTERVALS NO-EXTENSION  DEFAULT '1',               " FI Documnent Number
  s_gjahr  FOR   bkpf-gjahr OBLIGATORY NO-EXTENSION NO INTERVALS DEFAULT sy-datum+0(4).      " Fiscal Year
SELECTION-SCREEN : END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS :
    p_leg1  RADIOBUTTON GROUP r2 DEFAULT 'X' USER-COMMAND rad,   " LEG1
    p_inter RADIOBUTTON GROUP r2 ,                               " Interest Documnet
    p_leg2  RADIOBUTTON GROUP r2,                                " LEG2
    p_ginid RADIOBUTTON GROUP r2.                                " GINID, INID
SELECTION-SCREEN : END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS :
    p_doc  TYPE bkpf-belnr MODIF ID doc,
    p_year TYPE bkpf-gjahr MODIF ID doc,
    ginid  TYPE zfi_rxil_inv-inid MODIF ID idn,
    inid   TYPE zfi_rxil_inv-inid MODIF ID idn.
SELECTION-SCREEN : END OF BLOCK b3.

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN .
    IF  p_leg1 = 'X' OR p_inter = 'X' OR p_leg2 = 'X'.
      IF screen-group1 = 'IDN'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF p_ginid  = 'X' .
      IF screen-group1 = 'DOC'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

INITIALIZATION.

START-OF-SELECTION.

  SELECT SINGLE * FROM zfi_rxil_inv
                  INTO wa_inv
                  WHERE belnr IN s_belnr
                  AND   gjahr IN s_gjahr.
  IF sy-subrc <> 0.
    MESSAGE 'Document No-Fiscal Year combination not found.' TYPE 'E'.
  ENDIF.

  IF p_leg1 = 'X' OR p_inter = 'X' OR p_leg2 = 'X'.
    IF p_doc IS INITIAL.
      MESSAGE 'Please enter Document Number.' TYPE 'E'.
    ENDIF.

    IF p_year IS INITIAL.
      MESSAGE 'Please enter Fiscal Year.' TYPE 'E'.
    ENDIF.
  ENDIF.

  IF p_ginid = 'X'.
    IF ginid IS INITIAL.
      MESSAGE 'Please enter Group INID.' TYPE 'E'.
    ENDIF.

    IF inid IS INITIAL.
      MESSAGE 'Please enter INID.' TYPE 'E'.
    ENDIF.
  ENDIF.

  IF p_leg1 = 'X'.

    IF wa_inv-zbelnr_l1 IS INITIAL.
      UPDATE zfi_rxil_inv SET zbelnr_l1 = p_doc
                              gjahr_l1 = p_year
                        WHERE bukrs IN s_bukrs
                        AND   belnr IN s_belnr
                        AND   gjahr IN s_gjahr.

      MESSAGE 'L1 Document updated.' TYPE 'S'.
    ELSE.
      MESSAGE 'Document already exist for Invoice no.' TYPE 'I'.
    ENDIF.

  ELSEIF p_inter = 'X'.

    IF wa_inv-zbelnr_int IS INITIAL.
      UPDATE zfi_rxil_inv SET zbelnr_int = p_doc
                                  gjahr_int = p_year
                            WHERE bukrs IN s_bukrs
                            AND   belnr IN s_belnr
                            AND   gjahr IN s_gjahr.

      MESSAGE 'Interest Document updated.' TYPE 'S'.
    ELSE.
      MESSAGE 'Document already exist for Invoice no.' TYPE 'I'.
    ENDIF.

  ELSEIF p_leg2 = 'X'.

    IF wa_inv-zbelnr_l2 IS INITIAL .
      UPDATE zfi_rxil_inv SET zbelnr_l2 = p_doc
                                  gjahr_l2 = p_year
                            WHERE bukrs IN s_bukrs
                            AND   belnr IN s_belnr
                            AND   gjahr IN s_gjahr.

      MESSAGE 'L2 Document updated.' TYPE 'S'.
    ELSE.
      MESSAGE 'Document already exist for Invoice no.' TYPE 'I'.
    ENDIF.

**********Group INID/ INID update ****************

  ELSEIF p_ginid = 'X'.
    IF wa_inv-ginid IS INITIAL OR wa_inv-inid IS INITIAL.
      UPDATE zfi_rxil_inv SET ginid = ginid
                                    inid = inid
                              WHERE bukrs IN s_bukrs
                              AND   belnr IN s_belnr
                              AND   gjahr IN s_gjahr.

      MESSAGE 'GINID/INID updated.' TYPE 'S'.
    ELSE.
      MESSAGE 'GINID/ INID alread exist for Invoice no.' TYPE 'I'.
    ENDIF.

********************************************
  ENDIF.
