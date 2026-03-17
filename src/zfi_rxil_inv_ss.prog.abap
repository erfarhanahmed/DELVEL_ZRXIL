*&---------------------------------------------------------------------*
*& Include          ZFI_RXIL_INV_SS
*&---------------------------------------------------------------------*
SELECTION-SCREEN : BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS :
  s_bukrs  FOR   bkpf-bukrs OBLIGATORY NO-EXTENSION NO INTERVALS DEFAULT '1000',               " Company Code
  s_belnr  FOR   bkpf-belnr ,                                                                  " Docuemnt No.
  s_budat  FOR   bkpf-budat OBLIGATORY DEFAULT sy-datum to sy-datum,                           " FI Posting Date
  s_gjahr  FOR   bseg-gjahr OBLIGATORY," DEFAULT sy-datum+0(4) ,                               " Fiscal Year
  s_sdate  FOR   bkpf-budat OBLIGATORY,                                                        " Date for Status API run
  s_odate  FOR   bkpf-budat OBLIGATORY,                                                        " Date for Obligatory API run
  s_sedat  FOR   bkpf-budat ,                                                                  " Sending Date (TReDS)
  s_lifnr  FOR   bseg-lifnr,                                                                   " Vendor code
  s_statu  FOR   zfi_rxil_inv-inv_status NO-EXTENSION NO INTERVALS.                            " STATUS
  PARAMETERS: p_rxil TYPE zreg AS LISTBOX VISIBLE LENGTH 10 OBLIGATORY DEFAULT 'YES'.          " Registered with RXIL
*  PARAMETERS: p_SAP TYPE zmstatus AS LISTBOX VISIBLE LENGTH 10 OBLIGATORY  DEFAULT 'YES'.
*  PARAMETERS: p_cp TYPE zcp OBLIGATORY DEFAULT '90'.


SELECTION-SCREEN : END OF BLOCK b1.

SELECTION-SCREEN : BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  PARAMETERS :
    p_vipn   RADIOBUTTON GROUP r2 DEFAULT 'X' USER-COMMAND se1,   " Preparing for Bid Creation
    p_sbid   RADIOBUTTON GROUP r2,                                " Send for Bidding
    p_stat   RADIOBUTTON GROUP r2,                                " Status
    p_oblg   RADIOBUTTON GROUP r2,                                " Obligation API
    p_leg1   RADIOBUTTON GROUP r2,                                " LEG1
    p_leg2   RADIOBUTTON GROUP r2,                                " LEG2
    p_rmv    NO-DISPLAY, "RADIOBUTTON GROUP r2 ,                  " Remove Invoice
    p_report RADIOBUTTON GROUP r2,                                " Report
    p_sumrep RADIOBUTTON GROUP r2,                                " Summary Report
    p_rslink RADIOBUTTON GROUP r2,                                " RXIL supplier link in sap
    p_linkr  RADIOBUTTON GROUP r2.                                " RXIL supplier report

SELECTION-SCREEN : END OF BLOCK b2.
