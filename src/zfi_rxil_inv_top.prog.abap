*&---------------------------------------------------------------------*
*& Include          ZFI_RXIL_INV_TOP
*&---------------------------------------------------------------------*

TABLES : bkpf, bseg, zfi_rxil_inv.

DATA : it_inv TYPE TABLE OF zfi_rxil_inv,
       wa_inv TYPE zfi_rxil_inv.

TYPES: ztt_json_messages TYPE STANDARD TABLE OF string WITH EMPTY KEY.

TYPES : BEGIN OF ty_ibpdata,     " Batch Push API output structure
          chargebearer         TYPE string,
          suplocation          TYPE string,
          goodsacceptdate      TYPE string,
          adjamount            TYPE string,
          description          TYPE string,
          groupinid            TYPE string,
          instnumber           TYPE string,
          salescategory        TYPE string,
          podate               TYPE string,
          maturitydate         TYPE string,
          currency             TYPE string,
          extendedcreditperiod TYPE string,
          id                   TYPE string,
          supname              TYPE string,
          instdate             TYPE string,
          counterrefnum        TYPE string,
          purlocation          TYPE string,
          amount               TYPE string,
          purchaserref         TYPE string,
          cashdiscountpercent  TYPE string,
          netamount            TYPE string,
          creditperiod         TYPE string,
          extendedduedate      TYPE string,
          haircutpercent       TYPE string,
          cashdiscountvalue    TYPE string,
          supplierref          TYPE string,
          purname              TYPE string,
          statduedate          TYPE string,
          tdsamount            TYPE string,
          fuid                 TYPE string,
          instduedate          TYPE string,
          ponumber             TYPE string,
          status               TYPE string,
          code                 TYPE string,
          messages             TYPE ztt_json_messages,
        END OF ty_ibpdata.

DATA : it_ibpdata TYPE TABLE OF ty_ibpdata,
       wa_ibpdata TYPE ty_ibpdata.

TYPES : ty_ibptable  TYPE STANDARD TABLE OF ty_ibpdata WITH EMPTY KEY.

TYPES : BEGIN OF ty_hbpdata,
          data        TYPE ty_ibptable, "stringtab,
          batchstatus TYPE string,
        END OF ty_hbpdata.

TYPES : BEGIN OF ty_stdata,
          suplocation     TYPE string,
          goodsacceptdate TYPE string,
          adjamount       TYPE string,
          description     TYPE string,
          type            TYPE string,
          checkerauid     TYPE string,
          instnumber      TYPE string,
          autoaccept      TYPE string,
          podate          TYPE string,
          maturitydate    TYPE string,
          supplier        TYPE string,
          currency        TYPE string,
          id              TYPE string,
          instimage       TYPE string,
          instdate        TYPE string,
          counterrefnum   TYPE string,
          statusremarks   TYPE string,
          purlocation     TYPE string,
          amount          TYPE string,
          netamount       TYPE string,
          purchaser       TYPE string,
          counterauid     TYPE string,
          makerentity     TYPE string,
          tdsamount       TYPE string,
          creditnoteimage TYPE string,
          fuid            TYPE string,
          instduedate     TYPE string,
          makerauid       TYPE string,
          ponumber        TYPE string,
          status          TYPE string,
        END OF ty_stdata.

TYPES : BEGIN OF ty_final,
          check          TYPE char1,
          bukrs          TYPE bukrs,
          belnr          TYPE belnr_d,
          gjahr          TYPE gjahr,
          blart          TYPE blart,
          xblnr          TYPE xblnr,
          bldat          TYPE bldat,  " Document Date
          budat          TYPE budat,  " Posting Date
          zfbdt          TYPE dzfbdt,
          ztagg          TYPE dztagg_052,
          netdt          TYPE netdt,
          mm_inv         TYPE re_belnr,
          buyer          TYPE lifnr,
          b_gst          TYPE jv_gstno,
          rxil_seller    TYPE lifnr,
          seller         TYPE lifnr,
          mtext          TYPE txt30,
          prctr          TYPE prctr,
          bupla          TYPE bupla,
          secco          TYPE secco,
          s_gst          TYPE jv_gstno,
          pan_no         TYPE j_1ipanno,
          s_name         TYPE name1_gp,
          ebeln          TYPE ebeln,
          bedat          TYPE bedat,
          bsart          TYPE esart,
          pstatus        TYPE char15,        " can be process & Overdue
          waers          TYPE waers,
          tot_amount     TYPE wrbtr,
          FIn_amount     TYPE wrbtr,
          adj_amount     TYPE wrbtr,
          adj_belnr      TYPE belnr_d,
          adj_blart      TYPE blart,
          net_amount     TYPE wrbtr,
          goods_acc_date TYPE datum,
          credit_period  TYPE zcp,
          inv_status     TYPE zinv_status,
          dfgad          TYPE char3,   " Days from Goods Acceptance Date
          msg_type       TYPE char1,
          message        TYPE char255,
        END OF ty_final,

        BEGIN OF ty_data,
          chargebearer         TYPE string,
          suplocation          TYPE string,
          goodsacceptdate      TYPE string,
          adjamount            TYPE string,
          description          TYPE string,
          groupinid            TYPE string,
          instnumber           TYPE string,
          salescategory        TYPE string,
          podate               TYPE string,
          maturitydate         TYPE string,
          currency             TYPE string,
          extendedcreditperiod TYPE string,
          id                   TYPE string,
          supname              TYPE string,
          instdate             TYPE string,
          counterrefnum        TYPE string,
          purlocation          TYPE string,
          amount               TYPE string,
          purchaserref         TYPE string,
          cashdiscountpercent  TYPE string,
          netamount            TYPE string,
          creditperiod         TYPE string,
          extendedduedate      TYPE string,
          haircutpercent       TYPE string,
          cashdiscountvalue    TYPE string,
          supplierref          TYPE string,
          purname              TYPE string,
          statduedate          TYPE string,
          tdsamount            TYPE string,
          fuid                 TYPE string,
          instduedate          TYPE string,
          ponumber             TYPE string,
          status               TYPE string,
        END OF ty_data,

        BEGIN OF ty_login,
          reason         TYPE string,
          lastlogin      TYPE string,
          lastname       TYPE string,
          loginkey       TYPE string,
          entitytype     TYPE string,
          login          TYPE string,
          platform       TYPE string,
          firstname      TYPE string,
          entitytypedesc TYPE string,
          domain         TYPE string,
          servertime     TYPE string,
          middlename     TYPE string,
          usertype       TYPE string,
          entitytypelist TYPE stringtab,
          entity         TYPE string,
          status         TYPE string,
        END OF ty_login,

        BEGIN OF ty_status,
          suplocation     TYPE string,               ": "AHMEDABAD",
          goodsacceptdate TYPE string,               ": "15-Jul-2024",
          adjamount       TYPE string,               ": 0,
          description     TYPE string,               ": null,
          type            TYPE string,               ": "INV",
          checkerauid     TYPE string,               ": null,
          instnumber      TYPE string,               ": "INV-202202-535",
          autoaccept      TYPE string,               ": "D",
          podate          TYPE string,               ": "02-Jan-2023",
          maturitydate    TYPE string,               ": "11-Oct-2024",
          supplier        TYPE string,               ": "AE0002484",
          currency        TYPE string,               ": "INR",
          id              TYPE string,               ": 2408120000007,
          instimage       TYPE string,               ": null,
          instdate        TYPE string,               ": "12-May-2024",
          counterrefnum   TYPE string,               ": "CNTR-403",
          statusremarks   TYPE string,               ": null,
          purlocation     TYPE string,               ": "Chennai",
          amount          TYPE string,                      ": 25000,
          netamount       TYPE string,                      ": 25000,
          purchaser       TYPE string,               ": "EI0043841",
          counterauid     TYPE string,               ": null,
          makerentity     TYPE string,               ": "EI0043841",
          tdsamount       TYPE string,               ": null,
          creditnoteimage TYPE string,               ": null,
          fuid            TYPE string,               ": 1242250000001,
          instduedate     TYPE string,               ": "13-Oct-2024",
          makerauid       TYPE string,                      ": 33058,
          ponumber        TYPE string,               ": "PO2022-728",
          status          TYPE string,               ": "FACUNT"
        END OF ty_status,

        BEGIN OF ty_oblig,
          date            TYPE string, ": "19-Aug-2024",
          amount          TYPE string, ": 982.45,
          interestcharges TYPE string, ": 864.45,
          txntype         TYPE string, ": "D",
          type            TYPE string, ": "L1",
          paymentrefno    TYPE stringtab, ": [
          tdsvalue        TYPE string, ": 0,
          inid            TYPE string, ": 2408170000016,
          fuid            TYPE string, ": 1242300000007,
          id              TYPE string, ": 1242300000034,
          respremarks     TYPE string, ": null,
          counterrefnum   TYPE string, ": null,
          resperrorcode   TYPE string, ": null,
          status          TYPE string, ": "SUC",
          platfromcharges TYPE string, ": 118
        END OF ty_oblig,

        BEGIN OF ty_linking,
          companycode TYPE string,          ": "ST0003319",
          gstn        TYPE stringtab ,      ": ["27AAICS4679N1ZG"],
          companyname TYPE string,          ": "STEAM EQUIPMENTS PRIVATE LIMITED",
          pan         TYPE string,          ": "AAICS4679N"
        END OF ty_linking,

        BEGIN OF ty_report,
          check       TYPE char1,
          bukrs       TYPE bukrs,
          belnr       TYPE belnr_d,
          gjahr       TYPE gjahr,
          blart       TYPE blart,
          xblnr       TYPE xblnr,
          budat       TYPE budat,
          mm_inv      TYPE re_belnr,
          buyer       TYPE lifnr,
          b_gstn      TYPE jv_gstno,
          rxil_seller TYPE lifnr,
          seller      TYPE lifnr,
          s_gstn      TYPE jv_gstno,
          pan_no      TYPE j_1ipanno,
          s_name      TYPE name1_gp,
          ebeln       TYPE ebeln,
          bedat       TYPE bedat,
          inid        TYPE zinid,
          fuid        TYPE zfuid,
          wrbtr       TYPE wrbtr,
          waers       TYPE waers,
          tot_amount  TYPE wrbtr,
          api_status  TYPE zinv_status,
        END OF ty_report,

        BEGIN OF ty_msg,
          code     TYPE string,
          messages TYPE stringtab,
        END OF ty_msg,

        BEGIN OF ty_messages,
          msg TYPE string,
        END OF ty_messages,

        BEGIN OF ty_decry,
          response                 TYPE string,
          request_reference_number TYPE string,
        END OF ty_decry.

TYPES: BEGIN OF zstruct_json_data,
         instnumber    TYPE char50,    " Invoice or Instrument Number
         code          TYPE char10,    " Status Code (e.g., '400')
         messages      TYPE ztt_json_messages, "string,    " Error message (could be multiple messages)
         counterrefnum TYPE char50,  " Counter Reference Number
       END OF zstruct_json_data.

TYPES: ztt_json_data TYPE STANDARD TABLE OF zstruct_json_data WITH EMPTY KEY.

TYPES: BEGIN OF zstruct_json_response,
         data         TYPE ztt_json_data,    " Table containing multiple records
         batch_status TYPE char20,          " Batch status (success/failure)
       END OF zstruct_json_response.

DATA: lt_data     TYPE ztt_json_data,
      ls_data     TYPE zstruct_json_data,
      ls_response TYPE zstruct_json_response.

DATA : it_hbpdata  TYPE TABLE OF ty_hbpdata,
       wa_hbpdata  TYPE ty_hbpdata,
       it_final    TYPE TABLE OF ty_final,
       wa_final    TYPE ty_final,
       it_report   TYPE TABLE OF ty_report,
       wa_report   TYPE ty_report,
       lt_login    TYPE TABLE OF ty_login,
       ls_login    TYPE ty_login,
*       lt_data     TYPE TABLE OF ty_data,
*       ls_data     TYPE ty_data,
       it_status   TYPE TABLE OF ty_status,
       wa_status   TYPE ty_status,
       it_oblig    TYPE TABLE OF ty_oblig,
       wa_oblig    TYPE ty_oblig,
       it_linking  TYPE TABLE OF ty_linking,
       wa_linking  TYPE ty_linking,
       it_supp_map TYPE TABLE OF zsupp_mapping,
       wa_supp_map TYPE zsupp_mapping,
       it_rxil     TYPE TABLE OF zfi_rxil_inv,
       it_rxil_t   TYPE TABLE OF zfi_rxil_inv,
       wa_rxil     TYPE zfi_rxil_inv,
       wa_rxil_t   TYPE zfi_rxil_inv,
       it_msg      TYPE TABLE OF ty_msg,
       it_messages TYPE TABLE OF ty_messages,
       wa_msg      TYPE ty_msg,
       wa_faede    TYPE faede,               " Structure for Net Due Date
       wa_decry    TYPE ty_decry,
       it_enc_key  TYPE TABLE OF zenc_dec_key,
       wa_enc_key  TYPE zenc_dec_key.

DATA :BEGIN OF fmsg OCCURS 0,
        text(100) TYPE c,
      END OF fmsg.

DATA : alv_fieldcat TYPE slis_t_fieldcat_alv,            " INTERNAL TABLE
       fieldcat     TYPE slis_fieldcat_alv,              " WORK AREA.
       it_fcat_l    TYPE slis_t_fieldcat_alv,            " INTERNAL TABLE
       wa_fcat_l    TYPE slis_fieldcat_alv,              " WORK AREA
       it_sort      TYPE slis_t_sortinfo_alv.

DATA : cnt                 TYPE i,
       lv_tokens           TYPE string,
       lv_url              TYPE string,
       lv_r                TYPE string,
       lv_ref_no           TYPE string,
       gv_http_status_code TYPE i,
       gv_http_status_text TYPE string,
       o_http_client       TYPE REF TO if_http_client,
       zinv_date(15)       TYPE c,
       lv_loginkey         TYPE string,
       lv_inst             TYPE string,
       lv_json             TYPE string,
       lv_fdate            TYPE datum,
       lv_tdate            TYPE datum,
       zt_date(15)         TYPE c,
       zf_date(15)         TYPE c,
       zdate               TYPE datum,
       st                  TYPE c,
       gv_msg              TYPE char255,
       lv_text             TYPE string,
       lv_enc_data         TYPE string,
*       lv_enc_datal        TYPE string,
       lv_iv               TYPE xstring,
       lv_ciphertext       TYPE xstring,
       gv_key              TYPE xstring,
       gv_client_id        TYPE string,
       gv_token_key        TYPE string,
       gv_text1            TYPE string,
       lv_bukrs            TYPE bukrs,
       lv_belnr            TYPE belnr_d,
       lv_gjahr            TYPE gjahr.

DATA: lo_rest_client TYPE REF TO cl_rest_http_client,
      lo_response    TYPE REF TO if_rest_entity,
      lv_http_status TYPE i.

DATA : i_repid LIKE sy-repid,
       e_msg   TYPE string.

DATA: bdcdata LIKE bdcdata    OCCURS 0 WITH HEADER LINE,
      messtab LIKE bdcmsgcoll OCCURS 0 WITH HEADER LINE.

CONSTANTS:
  gc_post             TYPE string VALUE 'POST',
  gc_authorization    TYPE string VALUE 'Authorization',
  gc_content_type     TYPE string VALUE 'Content-Type',
  gc_username         TYPE string VALUE 'username',
  gc_loginkey         TYPE string VALUE 'loginKey',
  gc_app_json         TYPE string VALUE 'application/json',
  gc_client_id        TYPE string VALUE 'client-id',
  gc_client_token_key TYPE string VALUE 'client-token-key'.

CONSTANTS : c_auglv_c      TYPE t041a-auglv   VALUE 'UMBUCHNG', "Posting with Clearing
            c_auglv_o      TYPE t041a-auglv   VALUE 'AUSGZAHL', "Outgoing payment
            c_tcode        TYPE sy-tcode      VALUE 'FB05',     "You get an error with any other value
            c_sgfunct      TYPE rfipi-sgfunct VALUE 'C',        "Post immediately
            c_k(1)         TYPE c VALUE 'K',                    " K
            c_s(1)         TYPE c VALUE 'S',                    " S
            c_p(1)         TYPE c VALUE 'P',                    " P
            c_fb05         TYPE tstc-tcode VALUE 'FB05',        " transaction FB05
            c_doc_ty_kz(2) TYPE c VALUE 'KZ',                   " KZ document type
            c_doc_ty_kr(2) TYPE c VALUE 'KR',                   " KR document type
            c_doc_ty_sa(2) TYPE c VALUE 'SA',                   " SA document type
            c_ind          TYPE c VALUE '',                     " Special indicator
            c21_key(2)     TYPE c VALUE '21',                   " 21 Posting Key "Credit memos"
            c35_key(2)     TYPE c VALUE '35',                   "  Posting Key
            c50_key(2)     TYPE c VALUE '50',                   " 50 Posting Key "Credit entry"
            c40_key(2)     TYPE c VALUE '40'.                   " 40 Posting Key "Debit entry"

DATA: gv_count   TYPE syindex,
      gv_ek      TYPE char1,
      gv_auglv   TYPE t041a-auglv,
      it_ftpost  TYPE STANDARD TABLE OF ftpost,
      it_blntab  TYPE STANDARD TABLE OF blntab,
      it_fttax   TYPE STANDARD TABLE OF fttax,
      it_ftclear TYPE STANDARD TABLE OF ftclear,
      wrk_msgid  TYPE sy-msgid,
      wrk_msgno  TYPE sy-msgno,
      wrk_msgty  TYPE sy-msgty,
      wrk_msgv1  TYPE sy-msgv1,
      wrk_msgv2  TYPE sy-msgv2,
      wrk_msgv3  TYPE sy-msgv3,
      wrk_msgv4  TYPE sy-msgv4,
      wrk_subrc  TYPE sy-subrc.

*->Field Symbols
FIELD-SYMBOLS: <wa_ftpost>  TYPE ftpost,
               <wa_blntab>  TYPE blntab,
               <wa_ftclear> TYPE ftclear.
