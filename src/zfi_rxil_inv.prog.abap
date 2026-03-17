*&---------------------------------------------------------------------*
*& Report ZFI_RXIL_INV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zfi_rxil_inv.

INCLUDE zfi_rxil_inv_top.

INCLUDE zfi_rxil_inv_ss.

INCLUDE zfi_rxil_inv_form.

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    IF screen-name = 'S_BUKRS-LOW' OR screen-name = '%_S_BUKRS_%_APP_%-TEXT'.
      screen-input  = '0'.
      MODIFY SCREEN.
    ENDIF.

    IF p_vipn = 'X'.

      IF screen-name = 'S_STATU-LOW' OR screen-name = '%_S_STATU_%_APP_%-TEXT' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
         screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT' OR
         screen-name = 'S_SDATE-LOW' OR screen-name = 'S_SDATE-HIGH' OR
         screen-name = '%_S_SDATE_%_APP_%-TEXT' OR screen-name  ='%_S_SDATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_ODATE-LOW' OR screen-name = 'S_ODATE-HIGH' OR
         screen-name = '%_S_ODATE_%_APP_%-TEXT' OR screen-name  ='%_S_ODATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_SEDAT-LOW' OR screen-name = 'S_SEDAT-HIGH' OR
         screen-name = '%_S_SEDAT_%_APP_%-TEXT' OR screen-name  ='%_S_SEDAT_%_APP_%-VALU_PUSH'." OR
*         screen-name = 'P_NEDAT' OR screen-name = '%_P_NEDAT_%_APP_%-TEXT'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.


    ELSEIF p_sbid = 'X'." or p_sbidb = 'X'."p_vipn = 'X'.

      IF screen-name = 'S_STATU-LOW' OR screen-name = '%_S_STATU_%_APP_%-TEXT' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BUDAT-LOW' OR screen-name = 'S_BUDAT-HIGH' OR
         screen-name = '%_S_BUDAT_%_APP_%-TEXT' OR screen-name  ='%_S_BUDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BELNR-LOW' OR screen-name = 'S_BELNR-HIGH' OR
         screen-name = '%_S_BELNR_%_APP_%-TEXT' OR screen-name  ='%_S_BELNR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_GJAHR-LOW' OR screen-name = 'S_GJAHR-HIGH' OR
         screen-name = '%_S_GJAHR_%_APP_%-TEXT' OR screen-name = '%_S_GJAHR_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
         screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT' OR
         screen-name = 'S_SDATE-LOW' OR screen-name = 'S_SDATE-HIGH' OR
         screen-name = '%_S_SDATE_%_APP_%-TEXT' OR screen-name  ='%_S_SDATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_ODATE-LOW' OR screen-name = 'S_ODATE-HIGH' OR
         screen-name = '%_S_ODATE_%_APP_%-TEXT' OR screen-name  ='%_S_ODATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_SEDAT-LOW' OR screen-name = 'S_SEDAT-HIGH' OR
         screen-name = '%_S_SEDAT_%_APP_%-TEXT' OR screen-name  ='%_S_SEDAT_%_APP_%-VALU_PUSH' OR
        screen-name = 'P_NEDAT' OR screen-name = '%_P_NEDAT_%_APP_%-TEXT'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.

    ELSEIF p_report = 'X' OR p_sumrep = 'X'.     " Report

      IF screen-name = 'S_STATU' OR screen-name = '%_S_STATU_%_APP_%-TEXT' OR
         screen-name = 'S_BUKRS-LOW' OR screen-name = '%_S_BUKRS_%_APP_%-TEXT' OR
         screen-name = 'S_SEDAT-LOW' OR screen-name = 'S_SEDAT-HIGH' OR
         screen-name = '%_S_SEDAT_%_APP_%-TEXT' OR screen-name  ='%_S_SEDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BUDAT-LOW' OR screen-name = 'S_BUDAT-HIGH' OR
         screen-name = '%_S_BUDAT_%_APP_%-TEXT' OR screen-name  ='%_S_BUDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_GJAHR-LOW' OR screen-name = 'S_GJAHR-HIGH' OR
         screen-name = '%_S_GJAHR_%_APP_%-TEXT' OR screen-name = '%_S_GJAHR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_LIFNR-LOW' OR screen-name = 'S_LIFNR-HIGH' OR
         screen-name = '%_S_LIFNR_%_APP_%-TEXT' OR screen-name  ='%_S_LIFNR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BLART-LOW' OR screen-name = 'S_BLART-HIGH' OR
         screen-name = '%_S_BLART_%_APP_%-TEXT' OR screen-name = '%_S_BLART_%_APP_%-VALU_PUSH'.
        screen-active = '1'.
        MODIFY SCREEN.
      ENDIF.

      IF
**        screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BELNR-LOW' OR screen-name = 'S_BELNR-HIGH' OR
         screen-name = '%_S_BELNR_%_APP_%-TEXT' OR screen-name  ='%_S_BELNR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_SDATE-LOW' OR screen-name = 'S_SDATE-HIGH' OR
         screen-name = '%_S_SDATE_%_APP_%-TEXT' OR screen-name  ='%_S_SDATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_ODATE-LOW' OR screen-name = 'S_ODATE-HIGH' OR
         screen-name = '%_S_ODATE_%_APP_%-TEXT' OR screen-name  ='%_S_ODATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
         screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT' OR
         screen-name = 'P_CP' OR screen-name = '%_P_CP_%_APP_%-TEXT' OR
         screen-name = 'P_NEDAT' OR screen-name = '%_P_NEDAT_%_APP_%-TEXT'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.

    ELSEIF p_leg1 = 'X' OR p_leg2 = 'X'.

      IF screen-name = 'S_SEDAT-LOW' OR screen-name = 'S_SEDAT-HIGH' OR
         screen-name = '%_S_SEDAT_%_APP_%-TEXT' OR screen-name  ='%_S_SEDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BUDAT-LOW' OR screen-name = 'S_BUDAT-HIGH' OR
         screen-name = '%_S_BUDAT_%_APP_%-TEXT' OR screen-name  ='%_S_BUDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BELNR-LOW' OR screen-name = 'S_BELNR-HIGH' OR
         screen-name = '%_S_BELNR_%_APP_%-TEXT' OR screen-name  ='%_S_BELNR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_GJAHR-LOW' OR screen-name = 'S_GJAHR-HIGH' OR
         screen-name = '%_S_GJAHR_%_APP_%-TEXT' OR screen-name = '%_S_GJAHR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BLART-LOW' OR screen-name = 'S_BLART-HIGH' OR
         screen-name = '%_S_BLART_%_APP_%-TEXT' OR screen-name = '%_S_BLART_%_APP_%-VALU_PUSH' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_NEDAT' OR screen-name = '%_P_NEDAT_%_APP_%-TEXT' OR
         screen-name = 'S_STATU' OR screen-name = '%_S_STATU_%_APP_%-TEXT' OR screen-name = 'S_STATU-LOW' OR
         screen-name = 'S_LIFNR-LOW' OR screen-name = 'S_LIFNR-HIGH' OR
         screen-name = '%_S_LIFNR_%_APP_%-TEXT' OR screen-name  ='%_S_LIFNR_%_APP_%-VALU_PUSH' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_SDATE-LOW' OR screen-name = 'S_SDATE-HIGH' OR
         screen-name = '%_S_SDATE_%_APP_%-TEXT' OR screen-name  ='%_S_SDATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_ODATE-LOW' OR screen-name = 'S_ODATE-HIGH' OR
         screen-name = '%_S_ODATE_%_APP_%-TEXT' OR screen-name  ='%_S_ODATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
         screen-name = 'P_CP' OR screen-name = '%_P_CP_%_APP_%-TEXT' OR
         screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.

    ELSEIF p_stat = 'X'.

      IF screen-name = 'S_SEDAT-LOW' OR screen-name = 'S_SEDAT-HIGH' OR
         screen-name = '%_S_SEDAT_%_APP_%-TEXT' OR screen-name  ='%_S_SEDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BELNR-LOW' OR screen-name = 'S_BELNR-HIGH' OR
         screen-name = '%_S_BELNR_%_APP_%-TEXT' OR screen-name  ='%_S_BELNR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BUDAT-LOW' OR screen-name = 'S_BUDAT-HIGH' OR
         screen-name = '%_S_BUDAT_%_APP_%-TEXT' OR screen-name  ='%_S_BUDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_GJAHR-LOW' OR screen-name = 'S_GJAHR-HIGH' OR
         screen-name = '%_S_GJAHR_%_APP_%-TEXT' OR screen-name = '%_S_GJAHR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BLART-LOW' OR screen-name = 'S_BLART-HIGH' OR
         screen-name = '%_S_BLART_%_APP_%-TEXT' OR screen-name = '%_S_BLART_%_APP_%-VALU_PUSH' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_NEDAT' OR screen-name = '%_P_NEDAT_%_APP_%-TEXT' OR
         screen-name = 'S_STATU' OR screen-name = '%_S_STATU_%_APP_%-TEXT' OR screen-name = 'S_STATU-LOW' OR
         screen-name = 'S_ODATE-LOW' OR screen-name = 'S_ODATE-HIGH' OR
         screen-name = '%_S_ODATE_%_APP_%-TEXT' OR screen-name  ='%_S_ODATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_LIFNR-LOW' OR screen-name = 'S_LIFNR-HIGH' OR
         screen-name = '%_S_LIFNR_%_APP_%-TEXT' OR screen-name  ='%_S_LIFNR_%_APP_%-VALU_PUSH' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
         screen-name = 'P_CP' OR screen-name = '%_P_CP_%_APP_%-TEXT' OR
         screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.

    ELSEIF p_oblg = 'X'.

      IF screen-name = 'S_SEDAT-LOW' OR screen-name = 'S_SEDAT-HIGH' OR
         screen-name = '%_S_SEDAT_%_APP_%-TEXT' OR screen-name  ='%_S_SEDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BUDAT-LOW' OR screen-name = 'S_BUDAT-HIGH' OR
         screen-name = '%_S_BUDAT_%_APP_%-TEXT' OR screen-name  ='%_S_BUDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BELNR-LOW' OR screen-name = 'S_BELNR-HIGH' OR
         screen-name = '%_S_BELNR_%_APP_%-TEXT' OR screen-name  ='%_S_BELNR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_GJAHR-LOW' OR screen-name = 'S_GJAHR-HIGH' OR
         screen-name = '%_S_GJAHR_%_APP_%-TEXT' OR screen-name = '%_S_GJAHR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BLART-LOW' OR screen-name = 'S_BLART-HIGH' OR
         screen-name = '%_S_BLART_%_APP_%-TEXT' OR screen-name = '%_S_BLART_%_APP_%-VALU_PUSH' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
**         screen-name = 'P_NEDAT' OR screen-name = '%_P_NEDAT_%_APP_%-TEXT' OR
         screen-name = 'S_STATU' OR screen-name = '%_S_STATU_%_APP_%-TEXT' OR screen-name = 'S_STATU-LOW' OR
         screen-name = 'S_SDATE-LOW' OR screen-name = 'S_SDATE-HIGH' OR
         screen-name = '%_S_SDATE_%_APP_%-TEXT' OR screen-name  ='%_S_SDATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_LIFNR-LOW' OR screen-name = 'S_LIFNR-HIGH' OR
         screen-name = '%_S_LIFNR_%_APP_%-TEXT' OR screen-name  ='%_S_LIFNR_%_APP_%-VALU_PUSH' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
         screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT' OR
         screen-name = 'P_CP' OR screen-name = '%_P_CP_%_APP_%-TEXT'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.

    ELSEIF p_rslink = 'X' OR p_linkr = 'X'.

      IF p_linkr = 'X'.
        IF screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
           screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT' OR
           screen-name = 'P_CP' OR screen-name = '%_P_CP_%_APP_%-TEXT' OR
           screen-name = 'S_LIFNR-LOW' OR screen-name = 'S_LIFNR-HIGH' OR
           screen-name = '%_S_LIFNR_%_APP_%-TEXT' OR screen-name  ='%_S_LIFNR_%_APP_%-VALU_PUSH'.
          screen-active = '1'.
          MODIFY SCREEN.
        ENDIF.

      ELSEIF p_rslink = 'X'.
        IF screen-name = 'P_RXIL' OR screen-name = '%_P_RXIL_%_APP_%-TEXT' OR
           screen-name = 'P_SAP' OR screen-name = '%_P_SAP_%_APP_%-TEXT' OR
           screen-name = 'P_CP' OR screen-name = '%_P_CP_%_APP_%-TEXT' OR
           screen-name = 'S_LIFNR-LOW' OR screen-name = 'S_LIFNR-HIGH' OR
           screen-name = '%_S_LIFNR_%_APP_%-TEXT' OR screen-name  ='%_S_LIFNR_%_APP_%-VALU_PUSH' OR
           screen-name = 'S_BELNR-LOW' OR screen-name = 'S_BELNR-HIGH' OR
           screen-name = '%_S_BELNR_%_APP_%-TEXT' OR screen-name  ='%_S_BELNR_%_APP_%-VALU_PUSH'.
          screen-active = '0'.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.

      IF screen-name = 'S_SEDAT-LOW' OR screen-name = 'S_SEDAT-HIGH' OR
         screen-name = '%_S_SEDAT_%_APP_%-TEXT' OR screen-name  ='%_S_SEDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BUDAT-LOW' OR screen-name = 'S_BUDAT-HIGH' OR
         screen-name = '%_S_BUDAT_%_APP_%-TEXT' OR screen-name  ='%_S_BUDAT_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BELNR-LOW' OR screen-name = 'S_BELNR-HIGH' OR
         screen-name = '%_S_BELNR_%_APP_%-TEXT' OR screen-name  ='%_S_BELNR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_GJAHR-LOW' OR screen-name = 'S_GJAHR-HIGH' OR
         screen-name = '%_S_GJAHR_%_APP_%-TEXT' OR screen-name = '%_S_GJAHR_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_BLART-LOW' OR screen-name = 'S_BLART-HIGH' OR
         screen-name = '%_S_BLART_%_APP_%-TEXT' OR screen-name = '%_S_BLART_%_APP_%-VALU_PUSH' OR
**         screen-name = '%_S_INID_%_APP_%-TEXT' OR screen-name = 'S_INID-LOW' OR
**         screen-name = 'S_INID-HIGH' OR screen-name = '%_S_INID_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_SDATE-LOW' OR screen-name = 'S_SDATE-HIGH' OR
         screen-name = '%_S_SDATE_%_APP_%-TEXT' OR screen-name  ='%_S_SDATE_%_APP_%-VALU_PUSH' OR
         screen-name = 'S_ODATE-LOW' OR screen-name = 'S_ODATE-HIGH' OR
         screen-name = '%_S_ODATE_%_APP_%-TEXT' OR screen-name  ='%_S_ODATE_%_APP_%-VALU_PUSH' OR
**         screen-name = 'P_NEDAT' OR screen-name = '%_P_NEDAT_%_APP_%-TEXT' OR
         screen-name = 'P_CP' OR screen-name = '%_P_CP_%_APP_%-TEXT' OR
         screen-name = 'S_STATU' OR screen-name = '%_S_STATU_%_APP_%-TEXT' OR screen-name = 'S_STATU-LOW'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.

    ENDIF .
  ENDLOOP.

INITIALIZATION.


  DATA : lv_gjahr1 TYPE gjahr.

  CALL FUNCTION 'GET_CURRENT_YEAR'
    EXPORTING
      bukrs = '1000'
      date  = sy-datum
    IMPORTING
*     CURRM =
      curry = lv_gjahr1
*     PREVM =
*     PREVY =
    .

  s_gjahr-sign = 'I'.
  s_gjahr-option = 'BT'.
  s_gjahr-low = lv_gjahr1.
  s_gjahr-high  = lv_gjahr1.
  APPEND s_gjahr.

  s_sdate-sign = 'I'.
  s_sdate-option = 'BT'.
  s_sdate-low = sy-datum - 180 .
  s_sdate-high  = sy-datum.
  APPEND s_sdate.

  s_odate-sign = 'I'.
  s_odate-option = 'BT'.
  s_odate-low = sy-datum - 5.
  s_odate-high  = s_odate-low + 180.
  APPEND s_odate.

START-OF-SELECTION.

  PERFORM sel_query.

**  IF p_vipn = 'X'.
**    PERFORM display_data.
**  ENDIF.
