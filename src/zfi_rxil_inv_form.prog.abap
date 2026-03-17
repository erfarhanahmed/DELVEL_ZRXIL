*&---------------------------------------------------------------------*
*& Include          ZFI_RXIL_INV_FORM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form SEL_QUERY
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM sel_query .

  IF p_vipn  = 'X'.                          " Prepare for Bidding

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
               ID 'ACTVT' FIELD 'A9'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

* REGUP Cluster table containing paid item details.
    SELECT * FROM regup INTO TABLE @DATA(it_regup)
                              WHERE  bukrs IN @s_bukrs
                                 AND gjahr IN @s_gjahr
                                 AND budat IN @s_budat.

** Credit Period
    SELECT SINGLE low FROM tvarvc INTO @DATA(lv_cp)
                            WHERE name = 'ZCREDIT_PERIOD'
                            AND   type = 'P'.

** Invoice range table
    SELECT low FROM tvarvc INTO TABLE @DATA(it_inv_type)
                          WHERE name = 'RXIL_INV_TYPE'
                          AND   type = 'S'.

    TYPES lr_inv_type TYPE RANGE OF blart.
    DATA : lr_inv TYPE lr_inv_type.

    lr_inv = VALUE #( FOR wa_inv_type IN it_inv_type
                              ( sign   = 'I'
                                option = 'EQ'
                                low    = wa_inv_type-low ) ).

**  PO type range table to Exclude
    SELECT low FROM tvarvc INTO TABLE @DATA(it_po_type)
                   WHERE name = 'RXIL_PO_TYPE'
                   AND   type = 'S'.

    TYPES lr_po_type TYPE RANGE OF bsart.
    DATA : lr_po TYPE lr_po_type.

    lr_po = VALUE #( FOR wa_po_type IN it_po_type
                              ( sign   = 'I'
                                option = 'EQ'
                                low    = wa_po_type-low ) ).

    SELECT  bukrs, lifnr, belnr, gjahr, buzei, budat, xblnr, zuonr, hkont, shkzg, dmbtr, waers, blart,
            zfbdt, zbd1t, zbd2t, zbd3t, rebzg, rebzt, bldat, zterm, umskz, augdt, ebeln, bupla, wrbtr
            FROM bsik
            INTO TABLE @DATA(lt_bsik)
            WHERE bukrs IN @s_bukrs
              AND belnr IN @s_belnr
              AND gjahr IN @s_gjahr
              AND lifnr IN @s_lifnr
              AND budat IN @s_budat                " Posting  Date
              AND blart IN @lr_inv                 " Posting  Date
              AND ( umskz = '&' OR umskz = 'A' OR umskz = 'B' OR umskz = ' ' )
              AND ( zlspr = '' OR zlspr = 'R').

    LOOP AT it_regup INTO DATA(wa_regup).
* delete document that was processed from any payment program
      READ TABLE lt_bsik WITH KEY bukrs = wa_regup-bukrs
                                  belnr = wa_regup-belnr
                                  budat = wa_regup-budat TRANSPORTING NO FIELDS.
*
      IF sy-subrc = 0.

        DELETE lt_bsik WHERE bukrs = wa_regup-bukrs
                         AND belnr = wa_regup-belnr
                         AND budat = wa_regup-budat.
      ENDIF.

      CLEAR wa_regup.
    ENDLOOP.

    DATA(lt_bsik_h) = lt_bsik.
    DATA(lt_bsik_s) = lt_bsik.

    DELETE lt_bsik_h WHERE shkzg = 'S'.
    DELETE lt_bsik_s WHERE shkzg = 'H'.

    SELECT * FROM zfi_rxil_inv
             INTO TABLE it_rxil
             WHERE bukrs IN s_bukrs
             AND belnr IN s_belnr
             AND gjahr IN s_gjahr
             AND seller IN s_lifnr
             AND budat IN s_budat.

    IF lt_bsik_h IS NOT INITIAL.
      SELECT belnr, bukrs, gjahr , ebeln, awkey, kostl, zterm, lifnr, h_bldat, h_budat, h_blart, bvtyp, prctr, bupla, secco
             FROM bseg
             INTO TABLE @DATA(lt_bseg_e)
             FOR ALL ENTRIES IN @lt_bsik_h
             WHERE  belnr = @lt_bsik_h-belnr
                AND bukrs = @lt_bsik_h-bukrs
                AND gjahr = @lt_bsik_h-gjahr
                AND ebeln  <> ''.

*      DELETE lt_bseg_e WHERE ebeln IN lr_po.

      SELECT belnr, bukrs, gjahr , ebeln, awkey, kostl, zterm, lifnr, h_bldat, h_budat, h_blart, bvtyp, prctr, bupla, secco
          FROM bseg
          INTO TABLE @DATA(lt_bseg)
          FOR ALL ENTRIES IN @lt_bsik_h
          WHERE  belnr = @lt_bsik_h-belnr
             AND bukrs = @lt_bsik_h-bukrs
             AND gjahr = @lt_bsik_h-gjahr
             AND ebeln = ' '.

**      SELECT partner, taxnum
**             FROM dfkkbptaxnum
**             INTO TABLE @DATA(lt_gstn)
**             FOR ALL ENTRIES IN @lt_bsik_h
**             WHERE partner = @lt_bsik_h-lifnr
**             AND   taxtype = 'IN3'.

      SELECT lifnr, name1, j_1ipanno, stcd3
             FROM lfa1
             INTO TABLE @DATA(lt_lfa1)
             FOR ALL ENTRIES IN @lt_bsik_h
             WHERE lifnr = @lt_bsik_h-lifnr.

      SELECT sap_seller, rxil_seller, name1, s_gst, pan_no, mtext
             FROM zsupp_mapping
             INTO TABLE @DATA(lt_mapping)
             FOR ALL ENTRIES IN @lt_bsik_h
             WHERE sap_seller = @lt_bsik_h-lifnr
*             AND   msme_yn = 'YES'
             AND   reg_yn  = 'YES'.

      IF lt_bseg IS NOT INITIAL.
        SELECT belnr, bukrs, gjahr, xblnr, budat, cputm, xreversed, waers
               FROM bkpf INTO TABLE @DATA(lt_bkpf)
               FOR ALL ENTRIES IN @lt_bseg
               WHERE  belnr = @lt_bseg-belnr
                  AND bukrs = @lt_bseg-bukrs
                  AND gjahr = @lt_bseg-gjahr.

**        SELECT spras, zterm, ztagg, text1
**               FROM t052u
**               INTO TABLE @DATA(it_t052u)
**               FOR ALL ENTRIES IN @lt_bseg
**               WHERE spras = 'E'
**                 AND zterm = @lt_bseg-zterm
**                 AND spras = @sy-langu.

      ENDIF.
    ENDIF.

    LOOP AT lt_bsik_h INTO DATA(ls_bsik_h).
** Check the record if sent to Treds portal then delete those record from ALV display
      READ TABLE it_rxil WITH KEY belnr = ls_bsik_h-belnr
                                  gjahr = ls_bsik_h-gjahr
                                  msg_type = 'S' TRANSPORTING NO FIELDS .

      IF sy-subrc <> 0 .

        READ TABLE lt_lfa1 INTO DATA(ls_lfa1) WITH KEY lifnr = ls_bsik_h-lifnr.
        IF sy-subrc = 0.
          wa_final-s_name = ls_lfa1-name1.
          wa_final-pan_no = ls_lfa1-j_1ipanno.             " Supplier(Vendor) PAN.
          wa_final-s_gst  = ls_lfa1-stcd3.                 " Supplier(Vendor) GSTN.

          READ TABLE lt_mapping INTO DATA(ls_mapping) WITH KEY sap_seller = ls_bsik_h-lifnr
                                                               s_gst      = ls_lfa1-stcd3.
*                                                               pan_no     = ls_lfa1-j_1ipanno.
          IF sy-subrc = 0.
            wa_final-rxil_seller = ls_mapping-rxil_seller.  " RXIL seller code pass to API
            wa_final-mtext       = ls_mapping-mtext.        " SAP MSME Status (Minor, Small, Madium)

            wa_final-bukrs       = ls_bsik_h-bukrs.
            wa_final-belnr       = ls_bsik_h-belnr.
            wa_final-gjahr       = ls_bsik_h-gjahr.
            wa_final-blart       = ls_bsik_h-blart.
            wa_final-xblnr       = ls_bsik_h-xblnr.
            wa_final-bldat       = ls_bsik_h-bldat.
            wa_final-budat       = ls_bsik_h-budat.
            wa_final-zfbdt       = ls_bsik_h-zfbdt.
            wa_final-tot_amount  = ls_bsik_h-wrbtr.
            wa_final-waers       = ls_bsik_h-waers.
            wa_final-seller      = ls_bsik_h-lifnr.

**   Function Module for Net Due Date
            MOVE-CORRESPONDING ls_bsik_h TO wa_faede.

            wa_faede-koart = 'K'.   " for vendor

            CALL FUNCTION 'DETERMINE_DUE_DATE'
              EXPORTING
                i_faede                    = wa_faede
              IMPORTING
                e_faede                    = wa_faede
              EXCEPTIONS
                account_type_not_supported = 1
                OTHERS                     = 2.

            IF sy-subrc = 0.
              wa_final-netdt = wa_faede-netdt.        " Net due date
              wa_final-ztagg = wa_faede-zbd1t.        " days added for net due date calculation in Baseline Date
            ENDIF.

            READ TABLE lt_bsik_s INTO DATA(ls_bsik_s) WITH KEY xblnr = ls_bsik_h-xblnr
                                                               bukrs = ls_bsik_h-bukrs
                                                               gjahr = ls_bsik_h-gjahr.

            IF sy-subrc = 0.
              wa_final-adj_belnr  = ls_bsik_s-belnr.
              wa_final-adj_blart  = ls_bsik_s-blart.
              wa_final-adj_amount = ls_bsik_s-wrbtr.
*              wa_final-tot_amount = wa_final-tot_amount - wa_final-adj_amount.

            ENDIF.
** for Doc tType KZ
            READ TABLE lt_bseg_e INTO DATA(ls_bseg_e) WITH KEY belnr = ls_bsik_h-belnr
                                                           bukrs = ls_bsik_h-bukrs
                                                           gjahr = ls_bsik_h-gjahr
                                                           .
            IF sy-subrc = 0.
              wa_final-mm_inv = ls_bseg_e-awkey+0(10).
              wa_final-ebeln  = ls_bseg_e-ebeln.
              wa_final-prctr  = ls_bseg_e-prctr.
              wa_final-bupla  = ls_bseg_e-bupla.
              wa_final-secco  = ls_bseg_e-secco.
**          READ TABLE it_t052u INTO DATA(wa_t052u) WITH KEY "spras = 'E'
**                                                           zterm = ls_bseg-zterm.
**          IF sy-subrc = 0.
**            wa_final-ztagg = wa_t052u-ztagg.      " Payment term days
**          ENDIF.

              SELECT SINGLE ebeln, bedat, bsart FROM ekko WHERE ebeln = @ls_bseg_e-ebeln INTO @DATA(ls_ekko).
              IF sy-subrc = 0 .
                wa_final-bedat = ls_ekko-bedat.
                wa_final-bsart = ls_ekko-bsart.
              ENDIF.
            ENDIF.
** for Doc Type AB
            READ TABLE lt_bseg INTO DATA(ls_bseg) WITH KEY belnr = ls_bsik_h-belnr
                                                           bukrs = ls_bsik_h-bukrs
                                                           gjahr = ls_bsik_h-gjahr.

            IF sy-subrc = 0.
              IF wa_final-mm_inv IS INITIAL.
                wa_final-mm_inv = ls_bseg-awkey+0(10).
              ENDIF.
              IF wa_final-prctr IS INITIAL.
                wa_final-prctr  = ls_bseg-prctr.
              ENDIF.
              IF wa_final-bupla IS INITIAL.
                wa_final-bupla  = ls_bseg-bupla.
              ENDIF.
              IF wa_final-secco IS INITIAL.
                wa_final-secco  = ls_bseg-secco.
              ENDIF.
            ENDIF.

**** Good Acceptance Date

            SELECT SINGLE ebeln, belnr, gjahr, lfbnr, lfgja FROM ekbe
                                                            INTO @DATA(wa_data)
                                                            WHERE ebeln = @wa_final-ebeln         " PO number
                                                            AND   belnr = @wa_final-mm_inv        " Invoice number
                                                            AND   gjahr = @wa_final-gjahr.        " Invoive year
            IF sy-subrc = 0.
              SELECT SINGLE budat INTO @DATA(lv_gad) FROM ekbe WHERE ebeln = @wa_final-ebeln
                                                          AND belnr = @wa_data-lfbnr              " GRN number
                                                          AND gjahr = @wa_data-lfgja              " GRN fiscal year
                                                          AND bewtp = 'E'.                        " PO History Category

            ENDIF.

*            IF wa_data-grn_posting_date IS NOT INITIAL.
            IF lv_gad IS NOT INITIAL.
              wa_final-goods_acc_date = lv_gad.
            ELSE.
              wa_final-goods_acc_date = wa_final-bldat.
            ENDIF.

            wa_final-buyer         = 'DE0060180'.              " RXIL code
            wa_final-b_gst         = '27AACCD2898L1Z4'.        " GSTN
            wa_final-credit_period = lv_cp.                    " Credit Period
            wa_final-inv_status    = 'READY'.                  " Invoice Status
            wa_final-dfgad         = sy-datum - wa_final-goods_acc_date.
            wa_final-fin_amount    = wa_final-tot_amount - wa_final-adj_amount.

            IF wa_final-fin_amount <> 0.
              APPEND wa_final TO it_final.
            ENDIF.

            CLEAR : wa_final, lv_gad, wa_data.
*            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.   "uncomment this line only when actual scenario found.

    ENDLOOP.

    DELETE it_final WHERE dfgad GT 43.

    DELETE it_final WHERE fin_amount LE 0.

** Delete PO type from PO range table manage from STVARV.
*    DELETE it_final WHERE bsart IN lr_po.

    PERFORM fieldcat.

    PERFORM build_sort.

    PERFORM display_p.

  ELSEIF p_sbid  = 'X'.                          " Send for Bidding

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
    ID 'ACTVT' FIELD '16'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    SELECT * FROM zfi_rxil_inv
             INTO CORRESPONDING FIELDS OF TABLE it_inv
             WHERE inv_status = 'READY'
             AND seller IN s_lifnr
             AND msg_type NE 'E'.

    LOOP AT it_inv INTO wa_inv.
      MOVE-CORRESPONDING wa_inv TO wa_final.
      wa_final-dfgad  = sy-datum - wa_final-goods_acc_date.
      wa_final-fin_amount  = wa_final-tot_amount - wa_final-adj_amount.

****chcck payment Block before sending to RXIL Platform

      SELECT SINGLE zlspr INTO @DATA(lv_zlspr)
                          FROM bseg
                          WHERE bukrs = @wa_inv-bukrs
                          AND   belnr = @wa_inv-belnr
                          AND   gjahr = @wa_inv-gjahr.

      IF lv_zlspr = 'B'.
        wa_final-msg_type = 'E'.
        wa_final-message = 'Payment Block already there.'.
      ENDIF.

      APPEND wa_final TO it_final.
    ENDLOOP.

    PERFORM fieldcat_s.

    PERFORM display_s.

  ELSEIF p_stat = 'X'.                           " Status

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
    ID 'ACTVT' FIELD '0B'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    PERFORM enc_key.

*** status api trigger
    PERFORM login_api.

    IF gv_http_status_code = '200'.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_tokens
        CHANGING
          data = wa_decry
      ).

      DATA : lv_ddata TYPE string.

      lv_ddata = wa_decry-response.

      PERFORM decrypton_data USING lv_ddata
                             CHANGING lv_text.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_text
        CHANGING
          data = ls_login   " LOGIN API RESPONSE
      ).

      lv_loginkey = ls_login-loginkey.
      gv_ek = 'X'.
      PERFORM encrypt_data USING    lv_loginkey
                           CHANGING lv_enc_data.
      CLEAR : gv_ek.
    ENDIF.

    SELECT SINGLE url FROM zrxil_api INTO lv_url WHERE type = 'STATUS_E' AND sysid = sy-sysid.

    CALL FUNCTION 'CONVERSION_EXIT_SDATE_OUTPUT'
      EXPORTING
        input  = s_sdate-low
      IMPORTING
        output = zf_date.

    CONCATENATE zf_date+0(2) '-' zf_date+3(3) '-' zf_date+7(4) INTO zf_date.

    CALL FUNCTION 'CONVERSION_EXIT_SDATE_OUTPUT'
      EXPORTING
        input  = s_sdate-high
      IMPORTING
        output = zt_date.

    CONCATENATE zt_date+0(2) '-' zt_date+3(3) '-' zt_date+7(4) INTO zt_date.

    CONCATENATE '{"fromDate": "'zf_date'",'
    '"toDate": "'zt_date'"}' INTO lv_inst .

    PERFORM api CHANGING lv_url.   " Status API

*    error should be there if send success or fail.
    IF gv_http_status_code = '200'.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_tokens
        CHANGING
*         data = it_status
          data = wa_decry
      ).

      lv_ddata = wa_decry-response.

      PERFORM decrypton_data USING lv_ddata
                             CHANGING lv_text.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_text
        CHANGING
          data = it_status   " status API RESPONSE
      ).
    ENDIF.

****   upadte status and other data in main table against INID number.
    LOOP AT it_status INTO wa_status .
      IF wa_status-status = 'FACUNT'.
        wa_status-statusremarks = 'Factoring unit is in auction.'.
      ELSEIF wa_status-status = 'CHKRET'.
        wa_status-statusremarks = 'Invoice return for validation from checker (Same party who upload Invoice).'.
      ELSEIF wa_status-status = 'WTHDRN'.
        wa_status-statusremarks = 'Withdrawn (Instrument has been removed by buyer or seller).'.
      ELSEIF wa_status-status = 'FACT'.
        wa_status-statusremarks = 'Bid has been accepted for factoring unit and its disbursement (Leg1 settlement) is scheduled on next working day.'.
      ELSEIF wa_status-status = 'L1SET'.
        wa_status-statusremarks = 'Seller already received payment from financier.'.
      ELSEIF wa_status-status = 'L1FAIL'.
        wa_status-statusremarks = 'Due to some payment issues Seller did not get the payment from financier. (ex. Insufficient fund in financier account, seller account is closed, etc.).'.
      ELSEIF wa_status-status = 'EXP'.
        wa_status-statusremarks = 'Expired (Factoring unit/Instrument has been expired after statutory due date eod).'.
      ELSEIF wa_status-status = 'L2SET'.
        wa_status-statusremarks = 'Financier received the amount from the buyer.'.
      ELSEIF wa_status-status = 'L2FAIL'.
        wa_status-statusremarks = 'Due to some issues financier not got the payment from Buyer (like insufficient fund in buyer account).'.
      ENDIF.

      IF wa_status-status = 'L1SET'.
        UPDATE zfi_rxil_inv SET inv_status = wa_status-status
                                        message    = wa_status-statusremarks
                                        msg_type   = 'S'
                                        change_date = sy-datum
                                        net_amount = wa_status-netamount
                                        fuid       = wa_status-fuid
                                  WHERE ginid      = wa_status-id
                                  AND   zbelnr_l1  = ''.
        MESSAGE 'Status upadted successfully' TYPE 'S'.

      ELSEIF wa_status-status = 'L2SET'.
        UPDATE zfi_rxil_inv SET inv_status = wa_status-status
                                        message    = wa_status-statusremarks
                                        msg_type   = 'S'
                                         change_date = sy-datum
                                         net_amount = wa_status-netamount
                                        fuid       = wa_status-fuid
                                  WHERE ginid      = wa_status-id
                                  AND   zbelnr_l2  = ''.
        MESSAGE 'Status upadted successfully' TYPE 'S'.

      ELSE.
        UPDATE zfi_rxil_inv SET inv_status = wa_status-status
                                        message    = wa_status-statusremarks
                                        msg_type   = 'S'
                                        change_date = sy-datum
                                        net_amount = wa_status-netamount
                                        fuid       = wa_status-fuid
                                  WHERE ginid      = wa_status-id.
        MESSAGE 'Status upadted successfully' TYPE 'S'.

      ENDIF.

    ENDLOOP.

  ELSEIF p_oblg = 'X'.

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
    ID 'ACTVT' FIELD '0B'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    PERFORM enc_key.

    PERFORM login_api.

    IF gv_http_status_code   = '200'.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_tokens
        CHANGING
          data = wa_decry
      ).

      lv_ddata = wa_decry-response.

      PERFORM decrypton_data USING lv_ddata
                             CHANGING lv_text.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_text
        CHANGING
          data = ls_login   " LOGIN API RESPONSE
      ).

      lv_loginkey = ls_login-loginkey.
      gv_ek = 'X'.
      PERFORM encrypt_data USING    lv_loginkey
                           CHANGING lv_enc_data.
      CLEAR : gv_ek.
    ENDIF.

    SELECT SINGLE url FROM zrxil_api INTO lv_url WHERE type = 'OBLIG_E' AND sysid = sy-sysid.

    CALL FUNCTION 'CONVERSION_EXIT_SDATE_OUTPUT'
      EXPORTING
        input  = s_odate-low
      IMPORTING
        output = zf_date.

    CONCATENATE zf_date+0(2) '-' zf_date+3(3) '-' zf_date+7(4) INTO zf_date.

    CALL FUNCTION 'CONVERSION_EXIT_SDATE_OUTPUT'
      EXPORTING
        input  = s_odate-high
      IMPORTING
        output = zt_date.

    CONCATENATE zt_date+0(2) '-' zt_date+3(3) '-' zt_date+7(4) INTO zt_date.

    CONCATENATE '{"date": "'zf_date'",'
   '"filterToDate": "'zt_date'"}' INTO lv_inst.

    PERFORM api CHANGING lv_url.   " Status API

*    error should be there if send success or fail.
    IF gv_http_status_code = '200'.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_tokens
        CHANGING
*         data = it_oblig
          data = wa_decry
      ).

      lv_ddata = wa_decry-response.

      PERFORM decrypton_data USING lv_ddata
                             CHANGING lv_text.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_text
        CHANGING
          data = it_oblig   " Obligation API RESPONSE
      ).
    ENDIF.

** update Interest charge, Platform fees, L1 date and L2 date into main table
    LOOP AT it_oblig INTO wa_oblig .
      IF wa_oblig-type = 'L1'.
        TRANSLATE wa_oblig-date TO UPPER CASE.
        REPLACE ALL OCCURRENCES OF '-' IN wa_oblig-date WITH '.'.
        CALL FUNCTION 'CONVERSION_EXIT_SDATE_INPUT'
          EXPORTING
            input  = wa_oblig-date
          IMPORTING
            output = zdate.

        UPDATE zfi_rxil_inv SET l1_date     = zdate
                                int_amount  = wa_oblig-interestcharges
                                plt_charge  = wa_oblig-platfromcharges
                          WHERE ginid       = wa_oblig-inid
                          AND   fuid        = wa_oblig-fuid.

        MESSAGE 'Obligation record upadted successfully' TYPE 'S'.

      ELSEIF wa_oblig-type = 'L2'.
        TRANSLATE wa_oblig-date TO UPPER CASE.
        REPLACE ALL OCCURRENCES OF '-' IN wa_oblig-date WITH '.'.
        CALL FUNCTION 'CONVERSION_EXIT_SDATE_INPUT'
          EXPORTING
            input  = wa_oblig-date
          IMPORTING
            output = zdate.

        UPDATE zfi_rxil_inv SET l2_date = zdate
                        WHERE ginid     = wa_oblig-inid
                        AND   fuid      = wa_oblig-fuid.

        MESSAGE 'Obligation record upadted successfully' TYPE 'S'.

      ENDIF.
    ENDLOOP.

  ELSEIF p_leg1 = 'X'.  " Leg1 Document Posting

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
    ID 'ACTVT' FIELD '10'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    SELECT * FROM zfi_rxil_inv INTO TABLE it_rxil WHERE ( inv_status = 'L1SET' AND zbelnr_l1 = ''
                                                  OR    inv_status = 'L1SET' AND zbelnr_int = '' ) .

    IF sy-subrc = 0.
      SORT it_rxil BY bukrs ginid inid.
      it_rxil_t[] = it_rxil[].
      DELETE ADJACENT DUPLICATES FROM it_rxil_t COMPARING bukrs ginid.

      LOOP AT it_rxil_t INTO wa_rxil_t.
        IF wa_rxil_t-zbelnr_l1 IS INITIAL.
          LOOP AT it_rxil INTO wa_rxil WHERE bukrs = wa_rxil_t-bukrs
                                       AND   ginid = wa_rxil_t-ginid.

            st = ''.                " payment block
            PERFORM pay_block_upd USING st
                                        wa_rxil-bukrs
                                        wa_rxil-belnr
                                        wa_rxil-gjahr.   " Payment block update to Blank
            IF wa_rxil-adj_belnr IS NOT INITIAL.
              st = ''.
              PERFORM pay_block_upd USING st
                                          wa_rxil-bukrs
                                          wa_rxil-adj_belnr
                                          wa_rxil-gjahr.   " Payment block update to Blank
            ENDIF.
          ENDLOOP.
          PERFORM doc_post_l1.
        ENDIF.

        IF  wa_rxil_t-zbelnr_int IS INITIAL.
          PERFORM doc_post_int.    " interest+platform amount entry
        ENDIF.

      ENDLOOP.
    ELSE.
      MESSAGE 'No Documnet found.' TYPE 'I' DISPLAY LIKE 'E'.
    ENDIF.

  ELSEIF p_leg2 = 'X'.   " Leg2 Document Posting

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
    ID 'ACTVT' FIELD '10'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    SELECT * FROM zfi_rxil_inv INTO TABLE it_rxil WHERE inv_status = 'L2SET' AND zbelnr_l2 = ''.

    IF sy-subrc = 0.
      SORT it_rxil BY bukrs ginid inid.
      it_rxil_t[] = it_rxil[].
      DELETE ADJACENT DUPLICATES FROM it_rxil_t COMPARING bukrs ginid.

      LOOP AT it_rxil_t INTO wa_rxil_t.
        PERFORM doc_post_l2.
      ENDLOOP.
    ELSE.
      MESSAGE 'No Documnet found.' TYPE 'I' DISPLAY LIKE 'E'.
    ENDIF.

  ELSEIF p_report = 'X' OR p_sumrep = 'X'.

    SELECT * FROM zfi_rxil_inv INTO TABLE it_rxil WHERE bukrs IN s_bukrs
                                                  AND   gjahr IN s_gjahr
                                                  AND   seller IN s_lifnr
                                                  AND   budat IN s_budat
                                                  AND   sedat IN s_sedat
                                                  AND   inv_status IN s_statu.
    IF p_sumrep = 'X'.
      SORT it_rxil BY ginid fuid.
      DELETE ADJACENT DUPLICATES FROM it_rxil COMPARING ginid fuid.
    ENDIF.

    PERFORM field_catalog_r.

    PERFORM display_r.

  ELSEIF p_rslink = 'X'.  " RXIL seller linking

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
    ID 'ACTVT' FIELD 'A9'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    PERFORM enc_key.

    PERFORM login_api.

    IF gv_http_status_code   = '200'.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_tokens
        CHANGING
          data = wa_decry
      ).

      lv_ddata = wa_decry-response.

      PERFORM decrypton_data USING lv_ddata
                          CHANGING lv_text.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_text
        CHANGING
          data = ls_login   " LOGIN API RESPONSE
      ).
      lv_loginkey = ls_login-loginkey.
      gv_ek = 'X'.
      PERFORM encrypt_data USING    lv_loginkey
                           CHANGING lv_enc_data.
      CLEAR : gv_ek.
      SELECT SINGLE url FROM zrxil_api INTO lv_url WHERE type = 'LINKING_E' AND sysid = sy-sysid.

      lv_inst = '{}'.

      PERFORM api CHANGING lv_url.   " RXIL Supplier linking API

*    error should be there if send success or fail.
      IF gv_http_status_code = '200'.

        /ui2/cl_json=>deserialize(
          EXPORTING
            json         = lv_tokens
            pretty_name  = /ui2/cl_json=>pretty_mode-camel_case
            assoc_arrays = abap_true
          CHANGING
*           data         = it_linking
            data         = wa_decry
        ).

        lv_ddata = wa_decry-response.

        PERFORM decrypton_data USING lv_ddata
                               CHANGING lv_text.

        /ui2/cl_json=>deserialize(
          EXPORTING
            json = lv_text
          CHANGING
            data = it_linking   " supplier linking check API RESPONSE
        ).
      ENDIF.

      DATA : lv_lifnr TYPE lifnr,
             lv_mindk TYPE mindk.

      LOOP AT it_linking INTO wa_linking.
**        wa_supp_map-rxil_seller = wa_linking-companycode.
**        wa_supp_map-name1       = wa_linking-companyname.
**        wa_supp_map-pan_no      = wa_linking-pan.

        LOOP AT wa_linking-gstn INTO DATA(lv_gstn).
          wa_supp_map-rxil_seller = wa_linking-companycode.
          wa_supp_map-name1       = wa_linking-companyname.
          wa_supp_map-pan_no      = wa_linking-pan.
          wa_supp_map-s_gst       = lv_gstn.
          wa_supp_map-reg_yn      = 'YES'.

*** SAP vendor check based on GSTN and PAN number from API.
          SELECT lifnr,
                 stcd3 INTO TABLE @DATA(it_lfa1)
                       FROM lfa1
                       WHERE stcd3 = @lv_gstn.

          IF sy-subrc = 0.
            LOOP AT it_lfa1 INTO DATA(wa_lfa1).
              wa_supp_map-sap_seller = wa_lfa1-lifnr.

              APPEND wa_supp_map TO it_supp_map.
            ENDLOOP.
            REFRESH : it_lfa1.
            CLEAR : lv_gstn, lv_mindk, wa_supp_map.
          ENDIF.

        ENDLOOP.
        CLEAR : wa_linking.
      ENDLOOP.

****  code to find remaining vendor in table that was not present in this API run so it should
****  be updated as 'register to RXIL' value 'NO' after API run.

      DATA : it_supplier TYPE TABLE OF zsupp_mapping,
             wa_supplier TYPE zsupp_mapping.

      SELECT * FROM zsupp_mapping INTO TABLE it_supplier.

      LOOP AT it_supplier INTO wa_supplier.
        READ TABLE it_supp_map WITH KEY s_gst = wa_supplier-s_gst
                                        pan_no = wa_supplier-pan_no TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          DELETE it_supplier.
        ELSE.                  " update RXIL relationship as 'NO' that supplier was not in API response but in table
          UPDATE zsupp_mapping SET reg_yn = 'NO' WHERE sap_seller = wa_supplier-sap_seller
                                                 AND   rxil_seller = wa_supplier-rxil_seller.
        ENDIF.
      ENDLOOP.
** update the linking table from API response
      MODIFY zsupp_mapping FROM TABLE it_supp_map.

      MESSAGE 'SAP and RXIL seller mapping upadted successfully' TYPE 'S'.

    ENDIF.

  ELSEIF p_linkr = 'X'.   " SAP & RXIL Supplier Linking Report

    AUTHORITY-CHECK OBJECT 'ZRXIL_INV'
    ID 'ACTVT' FIELD 'A9'.
    IF sy-subrc NE '0'.
      MESSAGE 'You are not authorized for this activity' TYPE 'S'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    REFRESH : it_supp_map.
    SELECT * FROM zsupp_mapping INTO TABLE it_supp_map WHERE "msme_yn = p_sap
                                                          reg_yn  = p_rxil
                                                       AND   sap_seller IN s_lifnr.

    PERFORM fieldcat_linkr.
    PERFORM display_linkr.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*

FORM pfs_stat USING rt_extab TYPE slis_t_extab.   " Send to tReDS
  SET PF-STATUS 'ZSTT'.
ENDFORM.

FORM pfb_stat USING rt_extab TYPE slis_t_extab.   " Prepare for Bidding
  SET PF-STATUS 'ZPFB'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FIELDCAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fieldcat .

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'CHECK'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Sel'.
  fieldcat-checkbox  = 'X'.
  fieldcat-edit      = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUKRS'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Comp Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BELNR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Accounting Doc. No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-hotspot  = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'GJAHR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Fiscal Year'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BLART'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Doc. Type'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'XBLNR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Ref. Doc. No.'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'MM_INV'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Invoice Doc. No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-hotspot   = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BLDAT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Invoice Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUDAT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Posting Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'GOODS_ACC_DATE'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Goods Acceptance Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'DFGAD'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Days from Goods Acce Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'NETDT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Net Due Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'CREDIT_PERIOD'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Credit Period'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUYER'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'RXIL Buyer Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'B_GST'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Buyer GSTN'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'RXIL_SELLER'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'RXIL Seller Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'SELLER'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'SAP Seller Code'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-key       = 'X'. " Group by Vendor
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'S_GST'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Seller GSTN'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'S_NAME'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Seller Name'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'EBELN'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'PO No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BEDAT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'PO Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'PRCTR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Profit Center'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUPLA'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Business Place'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'SECCO'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Section Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'TOT_AMOUNT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Total Amount'.
  fieldcat-just      = 'C'.
  fieldcat-do_sum    = 'X'.   " Enable total & subtotal
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'WAERS'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Currency'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'ADJ_AMOUNT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Adj Amount'.
  fieldcat-just      = 'C'.
  fieldcat-do_sum    = 'X'.   " Enable total & subtotal
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'FIN_AMOUNT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Final Amount'.
  fieldcat-just      = 'C'.
  fieldcat-do_sum    = 'X'.   " Enable total & subtotal
  APPEND fieldcat TO alv_fieldcat.


  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'ADJ_BELNR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Adj Doc. No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-hotspot   = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'ADJ_BLART'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Adj Doc. Type'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .

  DATA:lw_layout TYPE slis_layout_alv .

  lw_layout-info_fieldname    = 'COLOR'.
  lw_layout-colwidth_optimize = 'X'.
  lw_layout-zebra             = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
*     I_BYPASSING_BUFFER       = ' '
*     I_BUFFER_ACTIVE          = ' '
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'PFP_STAT'
      i_callback_user_command  = 'USER_COMMAND_P'
*     i_callback_top_of_page   = 'HEADING'
      is_layout                = lw_layout
      it_fieldcat              = alv_fieldcat
*     I_DEFAULT                = 'X'
*     i_save                   = 'A'
    TABLES
      t_outtab                 = it_final
    EXCEPTIONS
      program_error            = 1
**      OTHERS                   = 2.
    .
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM user_command USING r_ucomm     TYPE sy-ucomm   " user command for send for bidding radio button
                        rs_selfield TYPE slis_selfield.

  DATA : gd_repid LIKE sy-repid,
         ref_grid TYPE REF TO cl_gui_alv_grid.

  DATA : lv_wrbtr   TYPE string,
         lv_tot     TYPE string,
         lv_adj     TYPE string,
         lv_podate  TYPE char15,
         lv_date    TYPE char15,
         lv_invdate TYPE char15.

  DATA : lv_msg_type TYPE char255.

  IF ref_grid IS INITIAL.
    CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
      IMPORTING
        e_grid = ref_grid.
  ENDIF.

  IF NOT ref_grid IS INITIAL.
    CALL METHOD ref_grid->check_changed_data.
  ENDIF.

  CASE r_ucomm.

    WHEN '&ZSTT'.  " selected invoice data send to Treds

      PERFORM enc_key.   " Encryption keys from table.

      LOOP AT it_final INTO wa_final WHERE check = 'X' AND msg_type <> 'E'.

*        PERFORM data_save.

        CALL FUNCTION 'CONVERSION_EXIT_SDATE_OUTPUT'
          EXPORTING
            input  = wa_final-bldat
          IMPORTING
            output = lv_invdate.

        CALL FUNCTION 'CONVERSION_EXIT_SDATE_OUTPUT'
          EXPORTING
            input  = wa_final-goods_acc_date "sy-datum
          IMPORTING
            output = lv_date.

        IF wa_final-bedat IS INITIAL.
          wa_final-bedat = wa_final-bldat. "budat.
        ENDIF.

        CALL FUNCTION 'CONVERSION_EXIT_SDATE_OUTPUT'
          EXPORTING
            input  = wa_final-bedat
          IMPORTING
            output = lv_podate.

        CONCATENATE lv_invdate+0(2) '-' lv_invdate+3(3) '-' lv_invdate+7(4) INTO lv_invdate.
        CONCATENATE lv_date+0(2) '-' lv_date+3(3) '-' lv_date+7(4) INTO lv_date.
        CONCATENATE lv_podate+0(2) '-' lv_podate+3(3) '-' lv_podate+7(4) INTO lv_podate.

        lv_tot = wa_final-tot_amount.
        lv_adj = wa_final-adj_amount.
        CONDENSE : lv_tot, lv_adj.

        IF wa_final-ebeln IS INITIAL .
          wa_final-ebeln = wa_final-belnr.
        ENDIF.

        DATA : lv_cp  TYPE char3,
               lv_crn TYPE string.

        CLEAR : lv_crn.
        CONCATENATE wa_final-belnr wa_final-gjahr wa_final-adj_belnr INTO lv_crn SEPARATED BY '-'.

        lv_cp = wa_final-credit_period.

        CONDENSE : lv_cp.

        CONCATENATE        '{'
                   '"supplier":'        ' "'wa_final-rxil_seller'", '
                   '"supLocation":'     ' "'wa_final-s_gst'", '
                   '"purchaser":'       ' "'wa_final-buyer'", '
                   '"purLocation":'     ' "'wa_final-b_gst'", '
                   '"poDate":'          ' "'lv_podate'", '
                   '"poNumber":'        ' "'wa_final-ebeln'", '
                   '"counterRefNum":'   ' "'lv_crn'", '
                   '"goodsAcceptDate":' ' "'lv_date'", '
                   '"instNumber":'      ' "'wa_final-xblnr'", '
                   '"instDate":'        ' "'lv_invdate'", '
                   '"amount":'          ' 'lv_tot', '
                   '"adjAmount":'       ' 'lv_adj', '
                   '"creditPeriod":'    ' 'lv_cp', '            "
                   '"status":'          ' "SUB"} '
                   INTO lv_json.

        CONCATENATE lv_json lv_inst INTO lv_inst SEPARATED BY ','.
        CLEAR : lv_json.

      ENDLOOP.

**      MODIFY zfi_rxil_inv FROM TABLE it_rxil.
**      COMMIT WORK.

      CONCATENATE '[' lv_inst ']' INTO lv_inst.

      REPLACE ALL OCCURRENCES OF ',]' IN lv_inst WITH ']' .

      IF lv_loginkey IS INITIAL.

        PERFORM login_api .

        IF gv_http_status_code   = '200'.

          /ui2/cl_json=>deserialize(
            EXPORTING
              json = lv_tokens
            CHANGING
*             data = ls_login
              data = wa_decry
          ).

          DATA : lv_ddata TYPE string.

          lv_ddata = wa_decry-response.

          PERFORM decrypton_data USING lv_ddata
                                 CHANGING lv_text.

          /ui2/cl_json=>deserialize(
            EXPORTING
              json = lv_text
            CHANGING
              data = ls_login   " LOGIN API RESPONSE
          ).

          lv_loginkey = ls_login-loginkey.
          gv_ek = 'X'.
          PERFORM encrypt_data USING    lv_loginkey
                               CHANGING lv_enc_data.
          CLEAR gv_ek.
        ENDIF.

      ENDIF.

      IF lv_loginkey IS NOT INITIAL.

        SELECT SINGLE url FROM zrxil_api INTO lv_url WHERE type = 'SEND_E' AND sysid = sy-sysid.

        PERFORM api CHANGING lv_url.   " invoice send ..

        /ui2/cl_json=>deserialize(
            EXPORTING
              json = lv_tokens
            CHANGING
*               data = ls_data
              data = wa_decry
          ).

        lv_ddata = wa_decry-response.

        PERFORM decrypton_data USING lv_ddata
                               CHANGING lv_text.

        /ui2/cl_json=>deserialize(
          EXPORTING
            json = lv_text
          CHANGING
            data = wa_hbpdata   "
        ).

        LOOP AT wa_hbpdata-data INTO DATA(ls_record).
          IF ls_record-status = 'SUB'." OR ls_record-status = 'FACUNT'.
            IF ls_record-groupinid IS INITIAL.
              ls_record-groupinid = ls_record-id.
            ENDIF.

            DATA : lv_belnr TYPE belnr_d.
            DATA : lv_adj_belnr TYPE belnr_d.
            DATA : lv_gjahr TYPE gjahr.
            DATA : lv_cc TYPE bukrs.
            DATA : lv_length TYPE i.

            CLEAR : lv_belnr, lv_adj_belnr, lv_gjahr, lv_cc, lv_length.

            lv_belnr     = ls_record-counterrefnum+0(10).
            lv_gjahr     =  ls_record-counterrefnum+11(4).
            lv_cc = s_bukrs-low.
            st = 'B'.

            PERFORM pay_block_upd USING st
                                        lv_cc
                                        lv_belnr
                                        lv_gjahr.   " Payment block update to B

            lv_length = strlen( ls_record-counterrefnum ).

            IF lv_length GT '16'.    "ls_record-counterrefnum+16(10) IS NOT INITIAL.
              lv_adj_belnr = ls_record-counterrefnum+16(10).
              PERFORM pay_block_upd USING st
                                          lv_cc
                                          lv_adj_belnr
                                          lv_gjahr.   " Payment block update to B
            ENDIF.

**            LOOP AT it_rxil INTO wa_rxil.
**              st = 'B'.                " payment block
**              PERFORM pay_block_upd USING wa_rxil-bukrs
**                                          wa_rxil-belnr
**                                          wa_rxil-gjahr.   " Payment block update to B
****            PERFORM bdc_fb09 .
***            wa_rxil-zlspr = st.
**            ENDLOOP.

            UPDATE zfi_rxil_inv SET ginid       = ls_record-groupinid
                                    inid        = ls_record-id
                                    inv_status  = ls_record-status
                                    change_date = sy-datum
                                    sedat       = sy-datum
                                    msg_type   = 'S'
                                    message     = ' '
                              WHERE belnr       = ls_record-counterrefnum+0(10)
                              AND   gjahr       = ls_record-counterrefnum+11(4).
*                              AND   xblnr       = ls_record-instnumber. Commented on 26/02/2026

          ENDIF.
          IF ls_record-code = '400'.
            LOOP AT ls_record-messages INTO DATA(lv_message).
              UPDATE zfi_rxil_inv SET message     = lv_message "ls_data-messages
                                      msg_type   = 'E'
                                      inv_status  = 'FAILURE'
                                      change_date = sy-datum
                                      sedat       = sy-datum
                                WHERE belnr       = ls_record-counterrefnum+0(10)
                                AND   gjahr       = ls_record-counterrefnum+11(4).
*                                AND   xblnr       = ls_record-instnumber. Commented on 26/02/2026
            ENDLOOP.
          ENDIF.
        ENDLOOP.

****    error should be there if send success or fail.
**        IF gv_http_status_code = '200'.
**
**          LOOP AT it_rxil INTO wa_rxil.
**            st = 'B'.                " payment block
**            PERFORM pay_block_upd USING wa_rxil-bukrs
**                                        wa_rxil-belnr
**                                        wa_rxil-gjahr.   " Payment block update to B
****            PERFORM bdc_fb09 .
***            wa_rxil-zlspr = st.
**          ENDLOOP.
**
**          /ui2/cl_json=>deserialize(
**            EXPORTING
**              json = lv_tokens
**            CHANGING
**              data = wa_decry
**          ).
**
**          lv_ddata = wa_decry-response.
**
**          PERFORM decrypton_data USING lv_ddata
**                                 CHANGING lv_text.
**
**          /ui2/cl_json=>deserialize(
**            EXPORTING
**              json = lv_text
**            CHANGING
**              data = wa_hbpdata   "
**          ).
**
**          LOOP AT wa_hbpdata-data INTO DATA(ls_record).
**
**            IF ls_record-groupinid IS INITIAL.
**              ls_record-groupinid = ls_record-id.
**            ENDIF.
**
**            UPDATE zfi_rxil_inv SET ginid       = ls_record-groupinid
**                                    inid        = ls_record-id
**                                    inv_status  = ls_record-status
**                                    change_date = sy-datum
**                                    sedat       = sy-datum
**                                    message     = ' '
**                                    msg_type    = 'S'
**                              WHERE belnr       = ls_record-counterrefnum
**                              AND   xblnr       = ls_record-instnumber.
**
**          ENDLOOP.
**
**          LEAVE TO LIST-PROCESSING.
**          CALL TRANSACTION 'ZRXIL_INV'.
**
**        ELSE.
**          DATA lv_msg TYPE string.
**          /ui2/cl_json=>deserialize(
**            EXPORTING
**              json = lv_tokens
**            CHANGING
**              data = wa_decry
**          ).
**
**          lv_ddata = wa_decry-response.
**
**          PERFORM decrypton_data USING lv_ddata
**                                 CHANGING lv_text.
**
**          /ui2/cl_json=>deserialize(
**            EXPORTING
**              json = lv_text
**            CHANGING
**              data = ls_response
**          ).
**
**          " Output the deserialized values
**          LOOP AT ls_response-data INTO DATA(ls_data).
**
**            LOOP AT ls_data-messages INTO DATA(lv_message).
**              UPDATE zfi_rxil_inv SET message     = lv_message "ls_data-messages
**                                      inv_status  = 'FAILURE'
**                                      change_date = sy-datum
**                                      sedat       = sy-datum
**                                      msg_type    = 'E'
**                                WHERE belnr       = ls_data-counterrefnum
**                                AND   xblnr       = ls_data-instnumber.
**
**            ENDLOOP.
**          ENDLOOP.
**        ENDIF.
        CLEAR :  ls_data.
      ENDIF.
**      LEAVE TO LIST-PROCESSING.
**      CALL TRANSACTION 'ZRXIL_INV'.

      LEAVE TO SCREEN 0.

    WHEN '&ZSAL'.

      PERFORM sel_all.   " select all

    WHEN '&ZDAL'.

      PERFORM dsel_all.   " dselect all

    WHEN '&REFR'.

      PERFORM refresh.   " Delete records that was in READY status.

  ENDCASE.

  rs_selfield-refresh = 'X'.

  CHECK NOT rs_selfield-value IS INITIAL.
  READ TABLE it_final INTO wa_final INDEX rs_selfield-tabindex.
  CHECK sy-subrc EQ 0.

  CASE rs_selfield-fieldname.

    WHEN 'BELNR'.
      SET PARAMETER ID 'BLN' FIELD wa_final-belnr.
      SET PARAMETER ID 'BUK' FIELD wa_final-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_final-gjahr.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

    WHEN 'MM_INV'.
      SET PARAMETER ID 'RBN' FIELD wa_final-mm_inv.
      SET PARAMETER ID 'GJR' FIELD wa_final-gjahr.
      CALL TRANSACTION 'MIR4' AND SKIP FIRST SCREEN.

    WHEN 'ADJ_BELNR'.
      SET PARAMETER ID 'BLN' FIELD wa_final-adj_belnr.
      SET PARAMETER ID 'BUK' FIELD wa_final-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_final-gjahr.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM user_command_p USING r_ucomm     TYPE sy-ucomm      " user command for preparing for bid radio button
                          rs_selfield TYPE slis_selfield.

  DATA : gd_repid LIKE sy-repid,
         ref_grid TYPE REF TO cl_gui_alv_grid.

  DATA : lv_wrbtr   TYPE string,
         lv_tot     TYPE string,
         lv_adj     TYPE string,
         lv_podate  TYPE char15,
         lv_invdate TYPE char15,
         lv_success TYPE n,
         lv_error   TYPE n.

  IF ref_grid IS INITIAL.
    CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
      IMPORTING
        e_grid = ref_grid.
  ENDIF.

  IF NOT ref_grid IS INITIAL.
    CALL METHOD ref_grid->check_changed_data.
  ENDIF.

  CASE r_ucomm.

    WHEN '&ZPFB'.  " PREPARE FOR BIDDING

      LOOP AT it_final INTO wa_final WHERE check = 'X'.
        wa_rxil-bukrs         = wa_final-bukrs.
        wa_rxil-belnr         = wa_final-belnr.
        wa_rxil-blart         = wa_final-blart.
        wa_rxil-adj_blart     = wa_final-adj_blart.
        wa_rxil-adj_belnr     = wa_final-adj_belnr.
        wa_rxil-gjahr         = wa_final-gjahr.
        wa_rxil-budat         = wa_final-budat.     " Posting Date
        wa_rxil-bldat         = wa_final-bldat.     " Document Date
        wa_rxil-goods_acc_date = wa_final-goods_acc_date.
        wa_rxil-xblnr         = wa_final-xblnr.
        wa_rxil-mm_inv        = wa_final-mm_inv.
        wa_rxil-buyer         = wa_final-buyer.
        wa_rxil-b_gst         = wa_final-b_gst.
        wa_rxil-seller        = wa_final-seller.
        wa_rxil-rxil_seller   = wa_final-rxil_seller.
        wa_rxil-s_name        = wa_final-s_name.
        wa_rxil-s_gst         = wa_final-s_gst.
        wa_rxil-budat         = wa_final-budat.
        wa_rxil-ebeln         = wa_final-ebeln.
        wa_rxil-bedat         = wa_final-bedat.
        wa_rxil-prctr         = wa_final-prctr.
        wa_rxil-bupla         = wa_final-bupla.
        wa_rxil-secco         = wa_final-secco.
        wa_rxil-credit_period = wa_final-credit_period.
        wa_rxil-netdt         = wa_final-netdt.      " net due data
        wa_rxil-tot_amount    = wa_final-tot_amount.
        wa_rxil-adj_amount    = wa_final-adj_amount.
        wa_rxil-waers         = wa_final-waers.
        wa_rxil-inv_status    = wa_final-inv_status.

        MODIFY zfi_rxil_inv FROM wa_rxil.
        CLEAR : wa_rxil.
      ENDLOOP.

**      LEAVE TO TRANSACTION 'ZRXIL_INV' .
**      LEAVE TO LIST-PROCESSING.

      LEAVE TO SCREEN 0.

    WHEN '&ZSAL'.

      PERFORM sel_all.   " select all

    WHEN '&ZDAL'.

      PERFORM dsel_all.   " dselect all

    WHEN '&CALC'.

      PERFORM total_amount.

  ENDCASE.

  rs_selfield-refresh = 'X'.

  CHECK NOT rs_selfield-value IS INITIAL.
  READ TABLE it_final INTO wa_final INDEX rs_selfield-tabindex.
  CHECK sy-subrc EQ 0.

  CASE rs_selfield-fieldname.

    WHEN 'BELNR'.
      SET PARAMETER ID 'BLN' FIELD wa_final-belnr.
      SET PARAMETER ID 'BUK' FIELD wa_final-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_final-gjahr.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

    WHEN 'MM_INV'.
      SET PARAMETER ID 'RBN' FIELD wa_final-mm_inv.
      SET PARAMETER ID 'GJR' FIELD wa_final-gjahr.
      CALL TRANSACTION 'MIR4' AND SKIP FIRST SCREEN.

    WHEN 'ADJ_BELNR'.
      SET PARAMETER ID 'BLN' FIELD wa_final-adj_belnr.
      SET PARAMETER ID 'BUK' FIELD wa_final-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_final-gjahr.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form LOGIN_API
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM login_api.

  SELECT SINGLE url FROM zrxil_api INTO lv_url WHERE type = 'LOGIN_E' AND sysid = sy-sysid.

  CALL METHOD cl_http_client=>create_by_url
    EXPORTING
      url                = lv_url
    IMPORTING
      client             = o_http_client
    EXCEPTIONS
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      OTHERS             = 4.

  IF sy-subrc <> 0.
    MESSAGE 'API Not Connected' TYPE 'W'.
*Implement suitable error handling here
  ELSE.

    CALL METHOD o_http_client->request->set_method
      EXPORTING
        method = gc_post.

    o_http_client->request->set_header_field(
      EXPORTING
        name  = gc_content_type                " Name of the header field
        value = gc_app_json                    " HTTP header field value
    ).

    o_http_client->request->set_header_field(
      EXPORTING
        name  = gc_client_id                    " Name of the header field
        value = gv_client_id                    " HTTP header field value
    ).

    o_http_client->request->set_header_field(
      EXPORTING
        name  = gc_client_token_key            " Name of the header field
        value = gv_token_key                   " HTTP header field value
    ).

** prepare api body
    DATA: lv_json TYPE string,
          lv_data TYPE string.

    SELECT SINGLE zdomain, login, password FROM zapi_login INTO @DATA(wa_login).

    CONCATENATE '{"domain":  "'wa_login-zdomain'",'
                '"login":    "'wa_login-login'",'
                '"password": "'wa_login-password'"}' INTO lv_data.

    PERFORM encrypt_data USING lv_data
                    CHANGING lv_enc_data.

*    lv_json = lv_data.
    lv_json = lv_enc_data.

    CALL METHOD o_http_client->request->set_cdata
      EXPORTING
        data = lv_json                          " Character data
*       offset     = 0                          " Offset into character data
*       length     = -1                         " Length of character data
      .

** send logoin api
    CALL METHOD o_http_client->send
      EXCEPTIONS
        http_communication_failure = 1                  " Communication Error
        http_invalid_state         = 2                  " Invalid state
        http_processing_failed     = 3                  " Error when processing method
        http_invalid_timeout       = 4                  " Invalid Time Entry
        OTHERS                     = 5.

    IF sy-subrc <> 0.

      CASE sy-subrc.
        WHEN '1'.
          MESSAGE 'send method : Communication Error' TYPE 'S'.
        WHEN '2'.
          MESSAGE 'send method : Invalid state' TYPE 'S'.
        WHEN '3'.
          MESSAGE 'send method : Error when processing method' TYPE 'S'.
        WHEN '4'.
          MESSAGE 'send method : Invalid Time Entry' TYPE 'S'.
        WHEN OTHERS.
          MESSAGE 'send method : Invalid Entry' TYPE 'S'.
      ENDCASE.

    ELSE.
**    receive response from Treds
      CALL METHOD o_http_client->receive
        EXCEPTIONS
          http_communication_failure = 1                " Communication Error
          http_invalid_state         = 2                " Invalid state
          http_processing_failed     = 3                " Error when processing method
          OTHERS                     = 4.

      IF sy-subrc <> 0.
        CASE sy-subrc.

          WHEN '1'.
            MESSAGE 'receive method : Communication Error' TYPE 'S'.
          WHEN '2'.
            MESSAGE 'receive method: Invalid state' TYPE 'S'.
          WHEN '3'.
            MESSAGE 'receive method: Error when processing method' TYPE 'S'.
          WHEN OTHERS.
            MESSAGE 'receive method: Invalid Entry' TYPE 'S'.
        ENDCASE.

      ELSE.
**    if receive successfully check status..
        CALL METHOD o_http_client->response->get_status
          IMPORTING
            code   = gv_http_status_code                " HTTP Status Code
            reason = gv_http_status_text.               " HTTP status description

        CALL METHOD o_http_client->response->get_cdata
          RECEIVING
            data = lv_tokens.   " Character data

      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form INST_API
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM api CHANGING p_lv_url.

  CLEAR : lv_tokens.

  DATA: lv_json TYPE string.

  CALL METHOD cl_http_client=>create_by_url
    EXPORTING
*     url                = lv_send_url1
      url                = p_lv_url
    IMPORTING
      client             = o_http_client
    EXCEPTIONS
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      OTHERS             = 4.

  IF sy-subrc <> 0.
    MESSAGE 'API Not Connected' TYPE 'W'.
*Implement suitable error handling here
  ELSE.

    CALL METHOD o_http_client->request->set_method
      EXPORTING
        method = gc_post.

    o_http_client->request->set_header_field(
      EXPORTING
        name  = gc_content_type            " Name of the header field
        value = gc_app_json                " HTTP header field value
    ).

    o_http_client->request->set_header_field(
      EXPORTING
        name  = gc_loginkey                " Name of the header field
        value = gv_text1                   " encrypted login key
    ).

    o_http_client->request->set_header_field(
      EXPORTING
        name  = gc_client_id                 " Name of the header field
        value = gv_client_id                 " HTTP header field value
    ).

    o_http_client->request->set_header_field(
      EXPORTING
        name  = gc_client_token_key                " Name of the header field
        value = gv_token_key                       " HTTP header field value
    ).

*    lv_data = lv_inst.
    CLEAR :lv_enc_data.
    PERFORM encrypt_data USING lv_inst
                  CHANGING lv_enc_data.

** prepare api body
*    lv_json = lv_inst.
    lv_json = lv_enc_data.

    CALL METHOD o_http_client->request->set_cdata
      EXPORTING
        data = lv_json                        " Character data
*       offset     = 0                        " Offset into character data
*       length     = -1                       " Length of character data
      .

** send logoin api
    CALL METHOD o_http_client->send
      EXCEPTIONS
        http_communication_failure = 1                  " Communication Error
        http_invalid_state         = 2                  " Invalid state
        http_processing_failed     = 3                  " Error when processing method
        http_invalid_timeout       = 4                  " Invalid Time Entry
        OTHERS                     = 5.

    IF sy-subrc <> 0.

      CASE sy-subrc.
        WHEN '1'.
          MESSAGE 'send method : Communication Error' TYPE 'S'.
        WHEN '2'.
          MESSAGE 'send method : Invalid state' TYPE 'S'.
        WHEN '3'.
          MESSAGE 'send method : Error when processing method' TYPE 'S'.
        WHEN '4'.
          MESSAGE 'send method : Invalid Time Entry' TYPE 'S'.
        WHEN OTHERS.
          MESSAGE 'send method : Invalid Entry' TYPE 'S'.
      ENDCASE.

    ELSE.
**    receive response from tntrade
      CALL METHOD o_http_client->receive
        EXCEPTIONS
          http_communication_failure = 1                " Communication Error
          http_invalid_state         = 2                " Invalid state
          http_processing_failed     = 3                " Error when processing method
          OTHERS                     = 4.

      IF sy-subrc <> 0.
        CASE sy-subrc.

          WHEN '1'.
            MESSAGE 'receive method : Communication Error' TYPE 'S'.
          WHEN '2'.
            MESSAGE 'receive method: Invalid state' TYPE 'S'.
          WHEN '3'.
            MESSAGE 'receive method: Error when processing method' TYPE 'S'.
          WHEN OTHERS.
            MESSAGE 'receive method: Invalid Entry' TYPE 'S'.
        ENDCASE.

      ELSE.
**    if receive successfully check status..
        CALL METHOD o_http_client->response->get_status
          IMPORTING
            code   = gv_http_status_code                " HTTP Status Code
            reason = gv_http_status_text.               " HTTP status description

        CALL METHOD o_http_client->response->get_cdata
          RECEIVING
            data = lv_tokens.   " Character data

      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FIELD_CATALOG_R
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM field_catalog_r .

  IF p_report = 'X'.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BUKRS'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Company Code'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BELNR'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Accounting Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'GJAHR'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Fiscal Year'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BLART'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Doc. Type'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'XBLNR'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Ref. Doc. No.'.
*  fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'MM_INV'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Invoice Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BLDAT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Invoice Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'GOODS_ACC_DATE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Goods Acceptance Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'NETDT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Net Due Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'SEDAT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Pushing Date(TReDS)'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BUYER'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'RXIL Buyer Code'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'B_GST'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Buyer GSTN'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'RXIL_SELLER'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'RXIL Seller Code'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'SELLER'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'SAP Seller Code'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'S_GST'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Seller GSTN'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'S_NAME'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Seller Name'.
*  fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'EBELN'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'PO No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BEDAT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'PO Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'PRCTR'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Profit Center'.
    fieldcat-no_zero   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BUPLA'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Business Place'.
    fieldcat-no_zero   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'SECCO'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Section Code'.
    fieldcat-no_zero   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'INID'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'INID No.'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'GINID'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Group INID No.'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'FUID'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'FUID No.'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'L1_DATE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L1 Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ZBELNR_L1'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L1 Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ZBELNR_INT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Interest+Platform Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'L2_DATE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L2 Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ZBELNR_L2'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L2 Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'TOT_AMOUNT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Total Amount'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ADJ_AMOUNT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Adj Amount'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'NET_AMOUNT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Net Amount'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'INT_AMOUNT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Interest Amount'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'PLT_CHARGE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Platform Charges'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'WAERS'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Currency'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ADJ_BLART'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Adj Doc. Type'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ADJ_BELNR'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Adj Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'INV_STATUS'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Status'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'MESSAGE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Message'.
    APPEND fieldcat TO alv_fieldcat.

  ELSEIF p_sumrep = 'X'.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'BUKRS'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Company Code'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'GJAHR'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Fiscal Year'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'SEDAT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Pushing Date(TReDS)'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'SELLER'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'SAP Seller Code'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'S_NAME'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Seller Name'.
*  fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'GINID'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Group INID No.'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'FUID'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'FUID No.'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'L1_DATE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L1 Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ZBELNR_L1'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L1 Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ZBELNR_INT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Interest+Platform Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'L2_DATE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L2 Date'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'ZBELNR_L2'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'L2 Doc. No.'.
    fieldcat-just      = 'C'.
    fieldcat-no_zero   = 'X'.
    fieldcat-hotspot   = 'X'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'NET_AMOUNT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Net Amount'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'INT_AMOUNT'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Interest Amount'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'PLT_CHARGE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Platform Charges'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'WAERS'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Currency'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'INV_STATUS'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Status'.
    fieldcat-just      = 'C'.
    APPEND fieldcat TO alv_fieldcat.

    CLEAR : fieldcat.
    cnt = cnt + 1.
    fieldcat-col_pos   = cnt.
    fieldcat-fieldname = 'MESSAGE'.
    fieldcat-tabname   = 'IT_RXIL'.
    fieldcat-seltext_l = 'Message'.
    APPEND fieldcat TO alv_fieldcat.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_R
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_r .

  DATA:lw_layout TYPE slis_layout_alv .

  lw_layout-info_fieldname    = 'COLOR'.
  lw_layout-colwidth_optimize = 'X'.
  lw_layout-zebra             = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK       = ' '
*     I_BYPASSING_BUFFER      = ' '
*     I_BUFFER_ACTIVE         = ' '
      i_callback_program      = sy-repid
      is_layout               = lw_layout
      it_fieldcat             = alv_fieldcat
      i_callback_user_command = 'USER_COMMAND_R'
*     I_DEFAULT               = 'X'
      i_save                  = 'A'
    TABLES
      t_outtab                = it_rxil
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FIELDCAT_LINKR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fieldcat_linkr .

  CLEAR : wa_fcat_l.
  cnt = cnt + 1.
  wa_fcat_l-col_pos   = cnt.
  wa_fcat_l-fieldname = 'SAP_SELLER'.
  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
  wa_fcat_l-seltext_l = 'SAP Supplier'.
  APPEND wa_fcat_l TO it_fcat_l.

  CLEAR : wa_fcat_l.
  cnt = cnt + 1.
  wa_fcat_l-col_pos   = cnt.
  wa_fcat_l-fieldname = 'RXIL_SELLER'.
  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
  wa_fcat_l-seltext_l = 'RXIL Supplier'.
  APPEND wa_fcat_l TO it_fcat_l.

  CLEAR : wa_fcat_l.
  cnt = cnt + 1.
  wa_fcat_l-col_pos   = cnt.
  wa_fcat_l-fieldname = 'NAME1'.
  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
  wa_fcat_l-seltext_l = 'Supplier Name'.
  APPEND wa_fcat_l TO it_fcat_l.

  CLEAR : wa_fcat_l.
  cnt = cnt + 1.
  wa_fcat_l-col_pos   = cnt.
  wa_fcat_l-fieldname = 'S_GST'.
  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
  wa_fcat_l-seltext_l = 'GST Number'.
  APPEND wa_fcat_l TO it_fcat_l.

  CLEAR : wa_fcat_l.
  cnt = cnt + 1.
  wa_fcat_l-col_pos   = cnt.
  wa_fcat_l-fieldname = 'PAN_NO'.
  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
  wa_fcat_l-seltext_l = 'PAN Number'.
  APPEND wa_fcat_l TO it_fcat_l.

**  CLEAR : wa_fcat_l.
**  cnt = cnt + 1.
**  wa_fcat_l-col_pos   = cnt.
**  wa_fcat_l-fieldname = 'MSME_YN'.
**  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
**  wa_fcat_l-seltext_l = 'SAP MSME Status'.
**  wa_fcat_l-just      = 'C'.
**  APPEND wa_fcat_l TO it_fcat_l.
**
**  CLEAR : wa_fcat_l.
**  cnt = cnt + 1.
**  wa_fcat_l-col_pos   = cnt.
**  wa_fcat_l-fieldname = 'MTEXT'.
**  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
**  wa_fcat_l-seltext_l = 'Description'.
**  wa_fcat_l-just      = 'C'.
**  APPEND wa_fcat_l TO it_fcat_l.

  CLEAR : wa_fcat_l.
  cnt = cnt + 1.
  wa_fcat_l-col_pos   = cnt.
  wa_fcat_l-fieldname = 'REG_YN'.
  wa_fcat_l-tabname   = 'IT_SUPP_MAP'.
  wa_fcat_l-seltext_l = 'Registered with RXIL'.
  wa_fcat_l-just      = 'C'.
  APPEND wa_fcat_l TO it_fcat_l.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_LINKR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_linkr .

  DATA:lw_layout TYPE slis_layout_alv .

  lw_layout-info_fieldname    = 'COLOR'.
  lw_layout-colwidth_optimize = 'X'.
  lw_layout-zebra             = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK  = ' '
*     I_BYPASSING_BUFFER = ' '
*     I_BUFFER_ACTIVE    = ' '
      i_callback_program = sy-repid
      is_layout          = lw_layout
      it_fieldcat        = it_fcat_l
*     I_DEFAULT          = 'X'
      i_save             = 'A'
    TABLES
      t_outtab           = it_supp_map
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form BDC_FB09
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM bdc_fb09 .

  TYPE-POOLS: truxs, slis.

  PERFORM bdc_dynpro      USING 'SAPMF05L' '0102'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RF05L-XKKRE'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '/00'.
  PERFORM bdc_field       USING 'RF05L-BELNR'
                                wa_final-belnr.
  PERFORM bdc_field       USING 'RF05L-BUKRS'
                                wa_final-bukrs.
  PERFORM bdc_field       USING 'RF05L-GJAHR'
                                wa_final-gjahr.
  PERFORM bdc_field       USING 'RF05L-BUZEI'
                                '1'.
  PERFORM bdc_field       USING 'RF05L-XKKRE'
                                'X'.
  PERFORM bdc_dynpro      USING 'SAPMF05L' '0302'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEG-ZLSPR'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '/00'.
  PERFORM bdc_field       USING 'BSEG-ZLSPR'
                                  st.
  PERFORM bdc_dynpro      USING 'SAPMF05L' '0302'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEG-ZTERM'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=AE'.

  CALL TRANSACTION 'FB09' WITH AUTHORITY-CHECK USING bdcdata
                       MODE  'A' "'N' "CTUMODE
                       UPDATE 'S'     "CUPDATE
                       MESSAGES INTO messtab.

  REFRESH bdcdata.

  LOOP AT messtab.
    CALL FUNCTION 'MESSAGE_TEXT_BUILD'
      EXPORTING
        msgid               = messtab-msgid
        msgnr               = messtab-msgnr
        msgv1               = messtab-msgv1
        msgv2               = messtab-msgv2
        msgv3               = messtab-msgv3
        msgv4               = messtab-msgv4
      IMPORTING
        message_text_output = fmsg-text.
    APPEND fmsg.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form BDC_DYNPRO
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form BDC_FIELD
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DOC_POST_L1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM doc_post_l1 .

  DATA: l_tabix TYPE sy-tabix,
        l_fuid  TYPE string.

  l_tabix = sy-tabix.

  CLEAR: it_ftpost[], it_ftclear[].
  gv_count = 1.
*  gv_auglv = c_auglv_c.
  gv_auglv = c_auglv_o.

  PERFORM fill_header_l1.

  LOOP AT it_rxil INTO wa_rxil WHERE bukrs = wa_rxil_t-bukrs
                                 AND ginid = wa_rxil_t-ginid.
*  fill clearing documnet data
    PERFORM fill_itemc_l1.
  ENDLOOP.


*  Fill Vendor data
  PERFORM fill_itemp_l1.

*  Post Document
  PERFORM post_data USING l_tabix
                          gv_auglv.

  CLEAR: it_ftpost[], it_ftclear[].

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DOC_POST_L2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM doc_post_l2 .

  DATA: l_tabix TYPE sy-tabix,
        l_fuid  TYPE string.

  l_tabix = sy-tabix.

  CLEAR: it_ftpost[], it_ftclear[].
  gv_count = 1.
*  gv_auglv = c_auglv_c.
  gv_auglv = c_auglv_o.

  PERFORM fill_header_l2.

*  fill clearing documnet data
  PERFORM fill_itemc_l2.

*  Fill Vendor data
  PERFORM fill_itemp_l2.

*  Post Document
  PERFORM post_data USING l_tabix
                          gv_auglv.

  CLEAR: it_ftpost[], it_ftclear[].

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_HEADER_L1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_header_l1 .

  DATA: lv_budat   TYPE budat,
        lv_bldat   TYPE bldat,
        lv_text    TYPE string,
        l_doc_date TYPE bkpf-bldat.

  WRITE: wa_rxil_t-l1_date TO lv_budat DDMMYY.

**  Document Date
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BLDAT'.           " Documnet Date
  <wa_ftpost>-fval  = lv_budat.

** Doc. Type
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BLART'.
  <wa_ftpost>-fval  = c_doc_ty_kz.           "KZ

** Company Code
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BUKRS'.
  <wa_ftpost>-fval  = wa_rxil_t-bukrs.

** Posting Date
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BUDAT'.            " Posting Date
  <wa_ftpost>-fval  = lv_budat.

** Currency
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-WAERS'.
  <wa_ftpost>-fval  = wa_rxil_t-waers.

** Document Header Text
*  CLEAR : lv_text.
*  CONCATENATE wa_rxil_t-fuid '_' wa_rxil_t-mm_inv INTO lv_text.
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BKTXT'.         " Document Header Text
  <wa_ftpost>-fval  = wa_rxil_t-fuid."lv_text.

** Reference Text
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-XBLNR'.         " Document Header Text
  <wa_ftpost>-fval  = wa_rxil_t-fuid.       "wa_rxil_t-belnr.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_ITEMC_L1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_itemc_l1 .

  APPEND INITIAL LINE TO it_ftclear ASSIGNING  <wa_ftclear>.
  <wa_ftclear>-agkoa = c_k.
  <wa_ftclear>-agkon = wa_rxil-seller. "wa_rxil-rxil_seller.
  <wa_ftclear>-agbuk = wa_rxil-bukrs.
  <wa_ftclear>-xnops = 'X'.
  <wa_ftclear>-selfd = 'BELNR'.
  <wa_ftclear>-selvon = wa_rxil-belnr.
  <wa_ftclear>-selbis = wa_rxil-belnr.

  IF wa_rxil-adj_belnr IS NOT INITIAL.
    APPEND INITIAL LINE TO it_ftclear ASSIGNING  <wa_ftclear>.
    <wa_ftclear>-agkoa = c_k.
    <wa_ftclear>-agkon = wa_rxil-seller. "wa_rxil-rxil_seller.
    <wa_ftclear>-agbuk = wa_rxil-bukrs.
    <wa_ftclear>-xnops = 'X'.
    <wa_ftclear>-selfd = 'BELNR'.
    <wa_ftclear>-selvon = wa_rxil-adj_belnr.
    <wa_ftclear>-selbis = wa_rxil-adj_belnr.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_ITEMP_L1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_itemp_l1 .

  DATA: lv_hkont    TYPE saknr,
        lv_wrbtr    TYPE string,
        lv_text     TYPE string,
        lv_doc_date TYPE sy-datum,
        lv_zfbdt    TYPE sy-datum,
        lv_valut    TYPE sy-datum.

  SELECT SINGLE low FROM tvarvc INTO @DATA(lv_RXIL_VENDOR)
                            WHERE name = 'RXIL_VENDOR'
                            AND   type = 'P'.

  gv_count = gv_count + 1.

  WRITE: wa_rxil_t-l1_date TO lv_valut DDMMYY.    " value date field
  WRITE: wa_rxil_t-l2_date TO lv_zfbdt DDMMYY.    " Baseline date field

** Posting Key
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'RF05A-NEWBS'.
  <wa_ftpost>-fval  = c35_key.

** Account
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'RF05A-NEWKO'.
**  lv_hkont = gv_vncode.
**  CONDENSE lv_hkont.
  <wa_ftpost>-fval  = lv_RXIL_VENDOR .          " '0000102120'."RXIL vendor '0000250038'. " RXIL GL account

** Special G/L Indicator
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'RF05A-NEWUM'.
  <wa_ftpost>-fval  = c_ind.

** Amount
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-WRBTR'.
  lv_wrbtr = wa_rxil_t-net_amount.
  CONDENSE : lv_wrbtr.
  <wa_ftpost>-fval  = lv_wrbtr.

**** Value date
**  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
**  <wa_ftpost>-stype = c_p.
**  <wa_ftpost>-count = gv_count.
**  <wa_ftpost>-fnam  = 'BSEG-VALUT'.
**  <wa_ftpost>-fval  = lv_valut.

** Baseline Date for Due Date Calculation
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-ZFBDT'.
  <wa_ftpost>-fval  = lv_zfbdt.

** Assignment
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-ZUONR'.
  <wa_ftpost>-fval  = wa_rxil_t-fuid.

* Profit Center
**  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
**  <wa_ftpost>-stype = c_p.
**  <wa_ftpost>-count = gv_count.
***  <wa_ftpost>-fnam  = 'COBL-PRCTR'.
**  <wa_ftpost>-fnam  = 'BSEG-PRCTR'.
***  <wa_ftpost>-fnam  = 'BSEG-XREF1'.
**  <wa_ftpost>-fval  = wa_rxil_t-prctr.

* Business Place
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-BUPLA'.
  <wa_ftpost>-fval  = wa_rxil_t-bupla.

*** Section Code
**  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
**  <wa_ftpost>-stype = c_p.
**  <wa_ftpost>-count = gv_count.
**  <wa_ftpost>-fnam  = 'BSEG-SECCO'.
**  <wa_ftpost>-fval  = wa_rxil_t-secco.

** Item text
  CLEAR : lv_text.
*  CONCATENATE 'RXIL_' wa_rxil_t-seller '_' wa_rxil_t-fuid '_' wa_rxil_t-belnr INTO lv_text.
  CONCATENATE 'RXIL_' wa_rxil_t-seller '_' wa_rxil_t-fuid INTO lv_text.
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-SGTXT'.
  <wa_ftpost>-fval  = lv_text.

  CLEAR: lv_wrbtr, lv_hkont, lv_zfbdt, lv_text .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form POST_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> L_TABIX
*&      --> GV_AUGLV
*&---------------------------------------------------------------------*
FORM post_data  USING    p_tabix
                         p_auglv.

* processing with call transaction
  CALL FUNCTION 'POSTING_INTERFACE_START'
    EXPORTING
      i_client           = sy-mandt
      i_function         = 'C'
      i_mode             = 'N'
      i_update           = 'S'
      i_user             = sy-uname
    EXCEPTIONS
      client_incorrect   = 1
      function_invalid   = 2
      group_name_missing = 3
      mode_invalid       = 4
      update_invalid     = 5
      OTHERS             = 6.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  REFRESH: it_blntab.
  CLEAR:  wrk_msgid, wrk_msgno, wrk_msgty, wrk_msgv1, wrk_msgv2, wrk_msgv3, wrk_msgv4, wrk_subrc.

*  ** call FM for posting acct. document
  CALL FUNCTION 'POSTING_INTERFACE_CLEARING'
    EXPORTING
      i_auglv                    = p_auglv
      i_tcode                    = c_tcode
      i_sgfunct                  = c_sgfunct
*     I_NO_AUTH                  = ' '
*     I_XSIMU                    = ' '
    IMPORTING
      e_msgid                    = wrk_msgid
      e_msgno                    = wrk_msgno
      e_msgty                    = wrk_msgty
      e_msgv1                    = wrk_msgv1
      e_msgv2                    = wrk_msgv2
      e_msgv3                    = wrk_msgv3
      e_msgv4                    = wrk_msgv4
      e_subrc                    = wrk_subrc
    TABLES
      t_blntab                   = it_blntab
      t_ftclear                  = it_ftclear
      t_ftpost                   = it_ftpost
      t_fttax                    = it_fttax
    EXCEPTIONS
      clearing_procedure_invalid = 1
      clearing_procedure_missing = 2
      table_t041a_empty          = 3
      transaction_code_invalid   = 4
      amount_format_error        = 5
      too_many_line_items        = 6
      company_code_invalid       = 7
      screen_not_found           = 8
      no_authorization           = 9
      OTHERS                     = 10.
  IF sy-subrc EQ 0.

    IF wrk_subrc IS INITIAL.

      CALL FUNCTION 'POSTING_INTERFACE_END'.

      READ TABLE it_blntab ASSIGNING <wa_blntab> INDEX 1.
      IF sy-subrc EQ 0.
        IF p_leg1 = 'X' .                             " Leg1 document upadte in main table
          UPDATE zfi_rxil_inv SET zbelnr_l1 = <wa_blntab>-belnr
                                  gjahr_l1  = <wa_blntab>-gjahr
                                  message   = 'L1 Posted'
                                  msg_type  = 'S'
                            WHERE bukrs = wa_rxil_t-bukrs
                            AND   ginid = wa_rxil_t-ginid
                            AND   fuid  = wa_rxil_t-fuid.
        ELSEIF p_leg2 = 'X'.                          " Leg2 document upadate in main table
          UPDATE zfi_rxil_inv SET zbelnr_l2 = <wa_blntab>-belnr
                                  gjahr_l2  = <wa_blntab>-gjahr
                                  message   = 'L2 Posted'
                                  msg_type  = 'S'
                            WHERE bukrs = wa_rxil_t-bukrs
                            AND   ginid = wa_rxil_t-ginid
                            AND   fuid  = wa_rxil_t-fuid.
        ENDIF.
      ENDIF.

    ELSE.  " error message if L1 or L2 posting fail.

      DATA : e_text TYPE string,
             e_msg  TYPE string.

      CALL FUNCTION 'MESSAGE_TEXT_BUILD'
        EXPORTING
          msgid               = wrk_msgid
          msgnr               = wrk_msgno
          msgv1               = wrk_msgv1
          msgv2               = wrk_msgv2
          msgv3               = wrk_msgv3
          msgv4               = wrk_msgv4
        IMPORTING
          message_text_output = e_text.

      IF p_leg1 = 'X' .

        CONCATENATE 'L1 Posting fail with error-' e_text INTO e_msg.
        UPDATE zfi_rxil_inv SET message  = e_msg
                                msg_type = 'E'
                          WHERE bukrs = wa_rxil_t-bukrs
                          AND   ginid = wa_rxil_t-ginid
                          AND   fuid  = wa_rxil_t-fuid.
      ELSEIF p_leg2 = 'X'.

        CONCATENATE 'L2 Posting fail with error-' e_text INTO e_msg.
        UPDATE zfi_rxil_inv SET message  = e_msg
                                msg_type = 'E'
                          WHERE bukrs = wa_rxil_t-bukrs
                          AND   ginid = wa_rxil_t-ginid
                          AND   fuid  = wa_rxil_t-fuid.
      ENDIF.
*      MODIFY it_rxil FROM wa_rxil.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_HEADER_L2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_header_l2 .

  DATA: lv_budat   TYPE budat,
        lv_bldat   TYPE bldat,
        lv_text    TYPE string,
        l_doc_date TYPE bkpf-bldat.

  WRITE: wa_rxil_t-l2_date TO lv_budat DDMMYY.

**  Document Date
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BLDAT'.           " Documnet Date
  <wa_ftpost>-fval  = lv_budat.

** Doc. Type
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BLART'.
  <wa_ftpost>-fval  = c_doc_ty_kz.              "c_doc_ty_sa.

** Company Code
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BUKRS'.
  <wa_ftpost>-fval  = wa_rxil_t-bukrs.

** Posting Date
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BUDAT'.            " Posting Date
  <wa_ftpost>-fval  = lv_budat.

** Currency
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-WAERS'.
  <wa_ftpost>-fval  = wa_rxil_t-waers.

** Invoice Number seller
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-XBLNR'.                   " Reference
  <wa_ftpost>-fval  =  wa_rxil_t-xblnr.

** Document Header Text
  CONCATENATE wa_rxil_t-fuid '_' wa_rxil_t-mm_inv INTO lv_text.
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_k.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BKPF-BKTXT'.         " Document Header Test
  <wa_ftpost>-fval  = lv_text.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_ITEMC_L2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_itemc_l2 .

  SELECT SINGLE low FROM tvarvc INTO @DATA(lv_RXIL_VENDOR)
                            WHERE name = 'RXIL_VENDOR'
                            AND   type = 'P'.


  APPEND INITIAL LINE TO it_ftclear ASSIGNING  <wa_ftclear>.
  <wa_ftclear>-agkoa = c_k.
*  <wa_ftclear>-agkoa = c_s.
*  <wa_ftclear>-agkon = '0000250038'.             "GL account " RXIL
  <wa_ftclear>-agkon = lv_RXIL_VENDOR. "'0000102120'.             " RXIL Vendor
  <wa_ftclear>-agbuk = wa_rxil-bukrs.
  <wa_ftclear>-xnops = 'X'.
  <wa_ftclear>-selfd = 'BELNR'.
  <wa_ftclear>-selvon = wa_rxil_t-zbelnr_l1.
  <wa_ftclear>-selbis = wa_rxil_t-zbelnr_l1.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FILL_ITEMP_L2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_itemp_l2 .

  DATA: lv_hkont    TYPE saknr,
        lv_wrbtr    TYPE string,
        lv_text     TYPE string,
        lv_doc_date TYPE sy-datum,
        lv_valut    TYPE sy-datum.
*        lv_zfbdt    type sy-datum.

  SELECT SINGLE low FROM tvarvc INTO @DATA(lv_BANK_GL)
                            WHERE name = 'BANK_GL_ACCOUNT'
                            AND   type = 'P'.

  gv_count = gv_count + 1.

  WRITE: wa_rxil_t-l1_date TO lv_valut DDMMYY.    " value date field

** Posting Key
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'RF05A-NEWBS'.
  <wa_ftpost>-fval  = c50_key."c31_key.

** Account
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'RF05A-NEWKO'.
**  lv_hkont = gv_vncode.
**  CONDENSE lv_hkont.
  <wa_ftpost>-fval  = lv_BANK_GL ."'0000420602'.                    " Bnk GL need to be updated

** Posting Key
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'RF05A-NEWUM'.
  <wa_ftpost>-fval  = c_ind.     "' '.

** Amount
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-WRBTR'.
  lv_wrbtr = wa_rxil_t-net_amount.
  CONDENSE : lv_wrbtr.
  <wa_ftpost>-fval  = lv_wrbtr.

**** Baseline Date for Due Date Calculation
**  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
**  <wa_ftpost>-stype = c_p.
**  <wa_ftpost>-count = gv_count.
**  <wa_ftpost>-fnam  = 'BSEG-ZFBDT'.
**  <wa_ftpost>-fval  = lv_zfbdt.

** Assignment
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-ZUONR'.
  <wa_ftpost>-fval  = wa_rxil_t-fuid.

** Item text
  CONCATENATE 'RXIL_' wa_rxil_t-seller '_' wa_rxil_t-fuid '_' wa_rxil_t-belnr INTO lv_text.
  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
  <wa_ftpost>-stype = c_p.
  <wa_ftpost>-count = gv_count.
  <wa_ftpost>-fnam  = 'BSEG-SGTXT'.
  <wa_ftpost>-fval  = lv_text.

** Profit Center
**  APPEND INITIAL LINE TO it_ftpost ASSIGNING <wa_ftpost>.
**  <wa_ftpost>-stype = c_p.
**  <wa_ftpost>-count = gv_count.
***  <wa_ftpost>-fnam  = 'BSEG-XREF1'.
***  <wa_ftpost>-fnam  = 'BSEG-PRCTR'.
**  <wa_ftpost>-fnam  = 'COBL-PRCTR'.
**  <wa_ftpost>-fval  = wa_rxil_t-prctr.

  CLEAR: lv_wrbtr, lv_hkont.", lv_zfbdt .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ENCRYPT_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_DATA
*&      <-- LV_ENC_DATA
*&---------------------------------------------------------------------*
FORM encrypt_data  USING    lv_data TYPE string
                   CHANGING lv_enc_data TYPE string.

  lv_iv = gv_key+16(16).

**"Convert to xstring
  DATA(v_data) = cl_bcs_convert=>string_to_xstring(
    iv_string = lv_data    " Input data
  ).

  " Encrypt data
  CALL METHOD cl_sec_sxml_writer=>encrypt_iv
    EXPORTING
      plaintext  = v_data
      key        = gv_key
      iv         = lv_iv
      algorithm  = cl_sec_sxml_writer=>co_aes256_algorithm_pem
    IMPORTING
      ciphertext = DATA(lv_ciphertext).
*** CATCH cx_sec_sxml_encrypt_error .
***ENDTRY.

  CALL METHOD cl_srt_wsp_api_helper=>encode_base64
    EXPORTING
      pi_orig_value_xstr = lv_ciphertext
    RECEIVING
      pr_encoded_value   = DATA(lv_text1).     " string

** move value onle in case of encryption login key
  IF gv_ek = 'X'.
    gv_text1 = lv_text1.
  ENDIF.


** genertare random number
  CALL FUNCTION 'GENERAL_GET_RANDOM_PWD'
    EXPORTING
      number_chars = '10'
    IMPORTING
      random_pwd   = lv_r.

  CONCATENATE sy-datum sy-uzeit lv_r INTO lv_ref_no SEPARATED BY '_'.
  CLEAR : lv_enc_data.
  CONCATENATE '{"REQUEST_REFERENCE_NUMBER":  "'lv_ref_no'",'
                '"REQUEST": "'lv_text1'"}' INTO lv_enc_data.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DECRYPTON_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_DDATA
*&      <-- LV_TEXT
*&---------------------------------------------------------------------*
FORM decrypton_data  USING    lv_ddata TYPE string
                     CHANGING lv_text  TYPE string.

  CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      input  = lv_ddata
    IMPORTING
      output = lv_ciphertext
    EXCEPTIONS
      failed = 1
      OTHERS = 2.

  " Decrypt data
  cl_sec_sxml_writer=>decrypt(
    EXPORTING
      ciphertext = lv_ciphertext
      key        = gv_key
      algorithm  = cl_sec_sxml_writer=>co_aes256_algorithm_pem
    IMPORTING
      plaintext  = DATA(lv_plaintext)
  ).

  CALL METHOD cl_bcs_convert=>xstring_to_string
    EXPORTING
      iv_xstr   = lv_plaintext
      iv_cp     = 1100
    RECEIVING
      rv_string = lv_text.   " string

ENDFORM.
*&---------------------------------------------------------------------*
*& Form PAY_BLOCK_UPD
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pay_block_upd USING lv_st    TYPE char1
                         lv_bukrs TYPE bukrs
                         lv_belnr TYPE belnr_d
                         lv_gjahr TYPE gjahr.

  CONSTANTS : lc_k     TYPE koart      VALUE 'K',              " Vendor Account Type
              lc_gname TYPE eqegraname VALUE 'BKPF',           " Elementary Lock of Lock Entry (Table Name)
              lc_zlspr TYPE char05     VALUE 'ZLSPR',          " Field name for Payment block at line item
              lc_buzei TYPE buzei      VALUE '001'.

  DATA : ls_accchg TYPE accchg.                   " Changing FI Document Work Area

  DATA : lt_accchg TYPE STANDARD TABLE OF accchg.         " Changing FI Document

*     Filling the fields to be changed
  ls_accchg-fdname = lc_zlspr.
  ls_accchg-newval = st.                " New value RXIL Payment block - TO BE CHANGED
  APPEND ls_accchg TO lt_accchg.

** UPDATE FI DOCUMENT
  IF lt_accchg IS NOT INITIAL.

*     Call the FM to update the FI document
    CALL FUNCTION 'FI_DOCUMENT_CHANGE'
      EXPORTING
        i_bukrs              = lv_bukrs  "wa_final-bukrs
        i_belnr              = lv_belnr  "wa_final-belnr
        i_gjahr              = lv_gjahr  "wa_final-gjahr
        i_buzei              = lc_buzei
      TABLES
        t_accchg             = lt_accchg
      EXCEPTIONS
        no_reference         = 1
        no_document          = 2
        many_documents       = 3
        wrong_input          = 4
        overwrite_creditcard = 5
        OTHERS               = 6.

    IF sy-subrc = 0.
*       Commit the changes
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ENC_KEY
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM enc_key .

  SELECT * INTO TABLE it_enc_key FROM zenc_dec_key.

  CLEAR : wa_enc_key.
  READ TABLE it_enc_key INTO wa_enc_key WITH KEY key_type = 'CLNTID'.
  gv_client_id = wa_enc_key-key_value.

  CLEAR : wa_enc_key.
  READ TABLE it_enc_key INTO wa_enc_key WITH KEY key_type = 'CLNTTOKEN'.
  gv_token_key = wa_enc_key-key_value.

  CLEAR : wa_enc_key.
  READ TABLE it_enc_key INTO wa_enc_key WITH KEY key_type = 'EDKEY'.
  gv_key = wa_enc_key-key_value.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM user_command_r USING r_ucomm     TYPE sy-ucomm
                          rs_selfield TYPE slis_selfield.

  DATA : gd_repid LIKE sy-repid,
         ref_grid TYPE REF TO cl_gui_alv_grid.

  DATA : lv_wrbtr   TYPE string,
         lv_podate  TYPE char15,
         lv_invdate TYPE char15.

  CHECK NOT rs_selfield-value IS INITIAL.
  READ TABLE it_rxil INTO wa_rxil INDEX rs_selfield-tabindex.
  CHECK sy-subrc EQ 0.

  CASE rs_selfield-fieldname.

    WHEN 'BELNR'.
      SET PARAMETER ID 'BLN' FIELD wa_rxil-belnr.
      SET PARAMETER ID 'BUK' FIELD wa_rxil-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_rxil-gjahr.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

    WHEN 'MM_INV'.
      SET PARAMETER ID 'RBN' FIELD wa_rxil-mm_inv.
      SET PARAMETER ID 'GJR' FIELD wa_rxil-gjahr.
      CALL TRANSACTION 'MIR4' AND SKIP FIRST SCREEN.

    WHEN 'ZBELNR_L1'.
      SET PARAMETER ID 'BLN' FIELD wa_rxil-zbelnr_l1.
      SET PARAMETER ID 'BUK' FIELD wa_rxil-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_rxil-gjahr_l1.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

    WHEN 'ZBELNR_INT'.
      SET PARAMETER ID 'BLN' FIELD wa_rxil-zbelnr_int.
      SET PARAMETER ID 'BUK' FIELD wa_rxil-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_rxil-gjahr_int.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

    WHEN 'ZBELNR_L2'.
      SET PARAMETER ID 'BLN' FIELD wa_rxil-zbelnr_l2.
      SET PARAMETER ID 'BUK' FIELD wa_rxil-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_rxil-gjahr_l2.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

    WHEN 'ADJ_BELNR'.
      SET PARAMETER ID 'BLN' FIELD wa_rxil-adj_belnr.
      SET PARAMETER ID 'BUK' FIELD wa_rxil-bukrs.
      SET PARAMETER ID 'GJR' FIELD wa_rxil-gjahr.
      CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.

  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form SEL_ALL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM sel_all .

  LOOP AT it_final INTO wa_final.
    wa_final-check = 'X'.
    MODIFY it_final FROM  wa_final.
    CLEAR wa_final.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DSEL_ALL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM dsel_all .

  LOOP AT it_final INTO wa_final.
    wa_final-check = ' '.
    MODIFY it_final FROM  wa_final.
    CLEAR wa_final.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_S
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_s .

  DATA:lw_layout TYPE slis_layout_alv .

  lw_layout-info_fieldname    = 'COLOR'.
  lw_layout-colwidth_optimize = 'X'.
  lw_layout-zebra             = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
*     I_BYPASSING_BUFFER       = ' '
*     I_BUFFER_ACTIVE          = ' '
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'PFS_STAT'
      i_callback_user_command  = 'USER_COMMAND'
*     i_callback_top_of_page   = 'HEADING'
      is_layout                = lw_layout
      it_fieldcat              = alv_fieldcat
*     I_DEFAULT                = 'X'
*     i_save                   = 'A'
    TABLES
      t_outtab                 = it_FINAL
    EXCEPTIONS
      program_error            = 1
**      OTHERS                   = 2.
    .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form data_save
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM data_save .

  wa_rxil-bukrs         = wa_final-bukrs.
  wa_rxil-belnr         = wa_final-belnr.
  wa_rxil-blart         = wa_final-blart.
  wa_rxil-adj_blart     = wa_final-adj_blart.
  wa_rxil-adj_belnr     = wa_final-adj_belnr.
  wa_rxil-gjahr         = wa_final-gjahr.
  wa_rxil-xblnr         = wa_final-xblnr.
  wa_rxil-mm_inv        = wa_final-mm_inv.
  wa_rxil-buyer         = wa_final-buyer.
  wa_rxil-b_gst         = wa_final-b_gst.
  wa_rxil-seller        = wa_final-seller.
  wa_rxil-rxil_seller   = wa_final-rxil_seller.
  wa_rxil-s_name        = wa_final-s_name.
  wa_rxil-s_gst         = wa_final-s_gst.
  wa_rxil-budat         = wa_final-budat.
  wa_rxil-ebeln         = wa_final-ebeln.
  wa_rxil-bedat         = wa_final-bedat.
  wa_rxil-prctr         = wa_final-prctr.
  wa_rxil-bupla         = wa_final-bupla.
  wa_rxil-secco         = wa_final-secco.
  wa_rxil-sedat         = sy-datum.
  wa_rxil-netdt         = wa_final-netdt.      " net due data
  wa_rxil-tot_amount    = wa_final-tot_amount.
  wa_rxil-net_amount    = wa_final-net_amount.
  wa_rxil-adj_amount    = wa_final-adj_amount.
  wa_rxil-waers         = wa_final-waers.

  APPEND wa_rxil TO it_rxil.
  CLEAR : wa_rxil.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DOC_POST_INT_PLT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM doc_post_int .

  DATA:
    lt_accountgl  TYPE TABLE OF bapiacgl09,   " GL account line items (BAPIACGL08)
    lt_currency   TYPE TABLE OF bapiaccr09,   " Currency line items
    lt_accountpay TYPE TABLE OF bapiacap09,   " account payable line items
    lt_accountrec TYPE TABLE OF bapiacar09,   " account receivable line items
    lt_return     TYPE TABLE OF bapiret2,     " Return messages
    lt_ext        TYPE TABLE OF bapiacextc,   " Extension for additional fields
    wa_header     TYPE bapiache09,            " Document header
    wa_return     TYPE bapiret2,               " Return structure
    obj_type      TYPE bapiache02-obj_type,
    obj_key       TYPE bapiache02-obj_key,
    obj_sys       TYPE bapiache02-obj_sys,
    lv_belnr_int  TYPE belnr_d,
    lv_gjahr_int  TYPE gjahr.

  DATA: lv_budat TYPE budat.

  DATA : lv_text TYPE string.
*         e_msg   TYPE string.

  SELECT SINGLE low FROM tvarvc INTO @DATA(lv_INT_GL)
                           WHERE name = 'INTEREST_GL_ACCOUNT'
                           AND   type = 'P'.


  SELECT SINGLE low FROM tvarvc INTO @DATA(lv_BANK_GL)
                             WHERE name = 'BANK_GL_ACCOUNT'
                             AND   type = 'P'.


  CLEAR : lv_belnr_int.
* Prepare document header
  CLEAR : lv_text.
  CONCATENATE wa_rxil_t-fuid '_' wa_rxil_t-mm_inv INTO lv_text .
  WRITE: wa_rxil_t-l1_date TO lv_budat DDMMYY.

  wa_header-doc_type   = c_doc_ty_kz.           " Document type (for GL posting)
  wa_header-doc_date   = wa_rxil_t-l1_date.     " Document date
  wa_header-pstng_date = wa_rxil_t-l1_date.     " Posting date
  wa_header-fisc_year  = wa_rxil_t-gjahr_l1.    " Fiscal year
  wa_header-username   = sy-uname.              " User who posts
  wa_header-ref_doc_no = wa_rxil_t-xblnr.       " Reference Doc

* Prepare GL account line items (debit and credit) with BAPIACGL08 structure

******platform charges
***  DATA(wa_accountrec) = VALUE bapiacar09(
**  DATA(wa_accountpay) = VALUE bapiacap09(
**    itemno_acc   = '0000000001'
**    vendor_no    = '0001000189'              " RXIL Vendor code
**    item_text    = lv_text
**    comp_code    = wa_rxil_t-bukrs           " Company code
***    costcenter   = wa_rxil_t-kostl"'10CP900003'              " Cost center if relevant
**      profit_ctr = wa_rxil_t-prctr
**  ).

**  APPEND wa_accountpay TO lt_accountpay.

**interest charges
  CLEAR : lv_text.
  CONCATENATE 'RXIL_' wa_rxil_t-seller '_' wa_rxil_t-fuid '_' wa_rxil_t-mm_inv INTO lv_text.
  DATA(wa_accountgl) = VALUE bapiacgl09(
    itemno_acc   = '0000000001'
    gl_account   = lv_INT_GL      "'0000730080' " GL Account
    item_text    = lv_text
    comp_code    = wa_rxil_t-bukrs     " Company code
    costcenter   = '0002000010'       "wa_rxil_t-kostl     " Cost center if relevant
    profit_ctr = wa_rxil_t-prctr
  ).

  APPEND wa_accountgl TO lt_accountgl.

* Prepare balancing GL account line item (credit)
  wa_accountgl = VALUE bapiacgl09(
    itemno_acc   = '0000000002'
    gl_account   = lv_BANK_GL "'0000420602'            " Balancing GL Account (Credit) need to be updated
    item_text    = lv_text
    comp_code    = wa_rxil_t-bukrs
     profit_ctr = wa_rxil_t-prctr
  ).

  APPEND wa_accountgl TO lt_accountgl.

  DATA : lv_amount   TYPE string,
         lv_amount_n TYPE string.

  lv_amount = wa_rxil_t-int_amount + wa_rxil-plt_charge.
  CONCATENATE '-' lv_amount INTO lv_amount_n.

*** Prepare currency data for each line item
**  DATA(wa_currency) = VALUE bapiaccr09(
**     itemno_acc   = '0000000001'
**     currency     = 'INR'
**     amt_doccur   = wa_rxil_t-plt_charge
**   ).

**  APPEND wa_currency TO lt_currency.

  DATA(wa_currency) = VALUE bapiaccr09(
     itemno_acc   = '0000000001'
     currency     = 'INR'
     amt_doccur  = lv_amount
   ).

  APPEND wa_currency TO lt_currency.

  wa_currency = VALUE bapiaccr09(
     itemno_acc   = '0000000002'
     currency     = 'INR'
     amt_doccur   = lv_amount_n
   ).
  APPEND wa_currency TO lt_currency.

  "--- Post Document
  CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
    EXPORTING
      documentheader    = wa_header
    TABLES
      accountgl         = lt_accountgl
      accountreceivable = lt_accountrec
      accountpayable    = lt_accountpay
      currencyamount    = lt_currency
      return            = lt_return.

* Check for errors in the return table
  READ TABLE lt_return INTO wa_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    " Error found, handle error messages
    LOOP AT lt_return INTO wa_return.
*      WRITE: / wa_return-message.
    ENDLOOP.
    CONCATENATE e_msg ' & ' 'Interest+Payment Documnet fail with error ' wa_return-message INTO e_msg.

    UPDATE zfi_rxil_inv SET message  = e_msg
                      WHERE bukrs = wa_rxil_t-bukrs
                      AND   ginid = wa_rxil_t-ginid
                      AND   fuid  = wa_rxil_t-fuid.
  ELSE.
    " No errors, commit the document
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

    READ TABLE lt_return INTO wa_return WITH KEY type = 'S'.
    lv_belnr_int = wa_return-message_v2+0(10).
    lv_gjahr_int = wa_return-message_v2+14(4).
    CONCATENATE e_msg ' &' ' Interest+Payment Document Posted.' INTO e_msg.

    UPDATE zfi_rxil_inv SET zbelnr_int = lv_belnr_int "obj_key+0(10)
                            gjahr_int  = lv_gjahr_int
                            message  = e_msg
                      WHERE bukrs = wa_rxil_t-bukrs
                      AND   ginid = wa_rxil_t-ginid
                      AND   fuid  = wa_rxil_t-fuid.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form doc_post_plt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM doc_post_plt .

  DATA:
    lt_accountgl  TYPE TABLE OF bapiacgl09,   " GL account line items (BAPIACGL08)
    lt_currency   TYPE TABLE OF bapiaccr09,   " Currency line items
    lt_accountpay TYPE TABLE OF bapiacap09,   " account payable line items
    lt_accountrec TYPE TABLE OF bapiacar09,   " account receivable line items
    lt_return     TYPE TABLE OF bapiret2,     " Return messages
    lt_ext        TYPE TABLE OF bapiacextc,   " Extension for additional fields
    wa_header     TYPE bapiache09,            " Document header
    wa_return     TYPE bapiret2,               " Return structure
    obj_type      TYPE bapiache02-obj_type,
    obj_key       TYPE bapiache02-obj_key,
    obj_sys       TYPE bapiache02-obj_sys,
    lv_belnr_plt  TYPE belnr_d,
    lv_gjahr_plt  TYPE gjahr.

  DATA: lv_budat TYPE budat.

  DATA : lv_text TYPE string,
         e_msg   TYPE string.

  CLEAR : lv_belnr_plt.
* Prepare document header
  CLEAR : lv_text.
  CONCATENATE wa_rxil_t-fuid '_' wa_rxil_t-mm_inv INTO lv_text .
  WRITE: wa_rxil_t-l1_date TO lv_budat DDMMYY.

  wa_header-doc_type   = c_doc_ty_kz.           " Document type (for GL posting)
  wa_header-doc_date   = wa_rxil_t-l1_date.     " Document date
  wa_header-pstng_date = wa_rxil_t-l1_date.     " Posting date
  wa_header-fisc_year  = wa_rxil_t-gjahr_l1.    " Fiscal year
  wa_header-username   = sy-uname.              " User who posts
  wa_header-ref_doc_no = wa_rxil_t-xblnr.       " Reference Doc

* Prepare GL account line items (debit and credit) with BAPIACGL08 structure

****platform charges
*  DATA(wa_accountrec) = VALUE bapiacar09(
  DATA(wa_accountpay) = VALUE bapiacap09(
    itemno_acc   = '0000000001'
    vendor_no    = '0001000189'              " RXIL Vendor code
    item_text    = lv_text
    comp_code    = wa_rxil_t-bukrs           " Company code
*    costcenter   = wa_rxil_t-kostl"'10CP900003'              " Cost center if relevant
      profit_ctr = wa_rxil_t-prctr
  ).

  APPEND wa_accountpay TO lt_accountpay.

**interest charges
  CLEAR : lv_text.
  CONCATENATE 'RXIL_' wa_rxil_t-seller '_' wa_rxil_t-fuid '_' wa_rxil_t-mm_inv INTO lv_text.
  DATA(wa_accountgl) = VALUE bapiacgl09(
    itemno_acc   = '0000000002'
    gl_account   = '0080026013'        " GL Account
    item_text    = lv_text
    comp_code    = wa_rxil_t-bukrs     " Company code
    costcenter   = '6001610001'"wa_rxil_t-kostl     " Cost center if relevant
    profit_ctr = wa_rxil_t-prctr
  ).

  APPEND wa_accountgl TO lt_accountgl.

* Prepare balancing GL account line item (credit)
  wa_accountgl = VALUE bapiacgl09(
    itemno_acc   = '0000000003'
    gl_account   = '0040041022'            " Balancing GL Account (Credit) need to be updated
    item_text    = lv_text
    comp_code    = wa_rxil_t-bukrs
     profit_ctr = wa_rxil_t-prctr
  ).

  APPEND wa_accountgl TO lt_accountgl.

  DATA : lv_amount TYPE string.
  lv_amount = wa_rxil_t-int_amount + wa_rxil_t-plt_charge.
  CONCATENATE '-' lv_amount INTO lv_amount.

* Prepare currency data for each line item
  DATA(wa_currency) = VALUE bapiaccr09(
     itemno_acc   = '0000000001'
     currency     = 'INR'
     amt_doccur   = wa_rxil_t-plt_charge
   ).

  APPEND wa_currency TO lt_currency.

  wa_currency = VALUE bapiaccr09(
    itemno_acc   = '0000000002'
    currency     = 'INR'
    amt_doccur  = wa_rxil_t-int_amount
  ).

  APPEND wa_currency TO lt_currency.

  wa_currency = VALUE bapiaccr09(
     itemno_acc   = '0000000003'
     currency     = 'INR'
     amt_doccur   = lv_amount
   ).
  APPEND wa_currency TO lt_currency.

  "--- Post Document
  CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
    EXPORTING
      documentheader    = wa_header
    TABLES
      accountgl         = lt_accountgl
      accountreceivable = lt_accountrec
      accountpayable    = lt_accountpay
      currencyamount    = lt_currency
      return            = lt_return.

* Check for errors in the return table
  READ TABLE lt_return INTO wa_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    " Error found, handle error messages
    LOOP AT lt_return INTO wa_return.
*      WRITE: / wa_return-message.
    ENDLOOP.
    CONCATENATE e_msg ' & ' 'Interest+Payment Documnet fail with error ' wa_return-message INTO e_msg.

    UPDATE zfi_rxil_inv SET message  = e_msg
                      WHERE bukrs = wa_rxil_t-bukrs
                      AND   ginid = wa_rxil_t-ginid
                      AND   fuid  = wa_rxil_t-fuid.
  ELSE.
    " No errors, commit the document
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

    READ TABLE lt_return INTO wa_return WITH KEY type = 'S'.
    lv_belnr_plt = wa_return-message_v2+0(10).
    lv_gjahr_plt = wa_return-message_v2+14(4).
    CONCATENATE e_msg ' &' ' Interest+Payment Document Posted.' INTO e_msg.

    UPDATE zfi_rxil_inv SET zbelnr_plt = lv_belnr_plt "obj_key+0(10)
                            gjahr_plt  = lv_gjahr_plt
                            message  = e_msg
                      WHERE bukrs = wa_rxil_t-bukrs
                      AND   ginid = wa_rxil_t-ginid
                      AND   fuid  = wa_rxil_t-fuid.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_p
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_p .

  DATA:lw_layout TYPE slis_layout_alv .

  lw_layout-info_fieldname    = 'COLOR'.
  lw_layout-colwidth_optimize = 'X'.
  lw_layout-zebra             = 'X'.
  lw_layout-totals_text       = 'Grand Total'.
  lw_layout-subtotals_text    = 'Subtotal for Vendor:'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
*     I_BYPASSING_BUFFER       = ' '
*     I_BUFFER_ACTIVE          = ' '
*     i_structure_name         = ty_sfb
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'PFB_STAT'
      i_callback_user_command  = 'USER_COMMAND_P'
*     i_callback_top_of_page   = 'HEADING'
      is_layout                = lw_layout
      it_fieldcat              = alv_fieldcat
      it_sort                  = it_sort
*     I_DEFAULT                = 'X'
*     i_save                   = 'A'
    TABLES
      t_outtab                 = it_final
    EXCEPTIONS
      program_error            = 1
**      OTHERS                   = 2.
    .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_sort
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_sort .

  DATA: wa_sort TYPE slis_sortinfo_alv.

  CLEAR wa_sort.

  wa_sort-fieldname = 'SELLER'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = 'X'.      " Subtotal by vendor
  APPEND wa_sort TO it_sort.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fieldcat_s
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fieldcat_s .

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'CHECK'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Sel'.
  fieldcat-checkbox  = 'X'.
  fieldcat-edit      = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUKRS'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Comp Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BELNR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Accounting Doc. No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-hotspot  = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'GJAHR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Fiscal Year'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BLART'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Doc. Type'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'XBLNR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Ref. Doc. No.'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'MM_INV'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Invoice Doc. No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-hotspot   = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BLDAT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Invoice Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'GOODS_ACC_DATE'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Goods Acceptance Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'DFGAD'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Days from Goods Acce Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUDAT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Posting Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'NETDT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Net Due Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'CREDIT_PERIOD'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Credit Period'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUYER'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'RXIL Buyer Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'B_GST'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Buyer GSTN'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'RXIL_SELLER'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'RXIL Seller Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'SELLER'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'SAP Seller Code'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-key       = 'X'. " Group by Vendor
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'S_GST'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Seller GSTN'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'S_NAME'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Seller Name'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'EBELN'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'PO No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BEDAT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'PO Date'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'PRCTR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Profit Center'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'BUPLA'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Business Place'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'SECCO'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Section Code'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.


  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'TOT_AMOUNT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Total Amount'.
  fieldcat-just      = 'C'.
  fieldcat-do_sum    = 'X'.   " Enable total & subtotal
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'WAERS'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Currency'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'ADJ_AMOUNT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Adj Amount'.
  fieldcat-just      = 'C'.
  fieldcat-do_sum    = 'X'.   " Enable total & subtotal
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'FIN_AMOUNT'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Final Amount'.
  fieldcat-just      = 'C'.
  fieldcat-do_sum    = 'X'.   " Enable total & subtotal
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'ADJ_BELNR'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Adj Doc. No.'.
  fieldcat-just      = 'C'.
  fieldcat-no_zero   = 'X'.
  fieldcat-hotspot   = 'X'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'ADJ_BLART'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Adj Doc. Type'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'INV_STATUS'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Status'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

  CLEAR : fieldcat.
  cnt = cnt + 1.
  fieldcat-col_pos   = cnt.
  fieldcat-fieldname = 'MESSAGE'.
  fieldcat-tabname   = 'IT_FINAL'.
  fieldcat-seltext_l = 'Message'.
  fieldcat-just      = 'C'.
  APPEND fieldcat TO alv_fieldcat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form total_amount
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM total_amount .

  DATA : lv_total     TYPE string,
         total_amount TYPE string.

  LOOP AT it_final INTO wa_final WHERE check = 'X'.
    lv_total = wa_final-fin_amount + lv_total.
  ENDLOOP.

  CONCATENATE 'Total Amount:' lv_total INTO total_amount.

  MESSAGE total_amount TYPE 'I'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh .

  LOOP AT it_final INTO wa_final WHERE check = 'X'.

    UPDATE zfi_rxil_inv SET inv_Status = ' '
                            adj_belnr = ' '
                            adj_blart = ' '
                            goods_acc_date = ' '
                            tot_amount = ' '
                            adj_amount = ' '
                            WHERE belnr = wa_final-belnr
                            AND   gjahr = wa_final-gjahr.
    CLEAR wa_final.

  ENDLOOP.

  Leave TO SCREEN 0.

ENDFORM.
