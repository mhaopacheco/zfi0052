*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F5
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_bcre_record_1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_bcre_record_1 .
  DATA:   wa_cre LIKE LINE OF tab_bcre,
          bank_code(2) TYPE n,
          squence TYPE i,
          fill_00,
          mssge(60),
          w_dcpfm TYPE usr01-dcpfm.

  DATA: wa_bkont TYPE lfbk-bkont,
        wa_bankn TYPE lfbk-bankn,
        wa_bankl TYPE lfbk-bankl.

  CLEAR: wa_cre.

Break jcastillo .

  REFRESH: tab_bcre.
* PERFORM get_records.
  PERFORM get_decimal CHANGING w_dcpfm.


  LOOP AT t_reguh.
    CLEAR: lfbk, mssge .
    CLEAR: wa_bankn, wa_bkont, wa_bankl .

    AT NEW stcd1 .
      squence = 0 .
    ENDAT .
    ADD 1 TO squence .

    wa_cre-sec_pro    = squence    .
    wa_cre-addat(2)   = addat+4(2) .
    wa_cre-addat+2(2) = addat+6(2) .
    wa_cre-addat+4(2) = addat+2(2) .

    PERFORM get_stcd USING t_reguh-zstc1 CHANGING wa_cre-stcd1 .
    wa_cre-stcd1 = t_reguh-zstc1 .

    SELECT SINGLE bankn bkont bankl INTO (wa_bankn, wa_bkont, wa_bankl) FROM lfbk WHERE lifnr = t_reguh-lifnr .

    wa_cre-koinh = t_reguh-znme1.
    bank_code = t_reguh-zbnkl+2(2).
*{   REPLACE        AMDK902338                                        4
*\    wa_cre-bankl = bank_code.
    wa_cre-bankl = wa_bankl.
*}   REPLACE
*{   REPLACE        AMDK902338                                        2
*\    CASE t_reguh-zbkon.
*\      WHEN '01' OR 'CC' OR '1'.
*\        wa_cre-bkont = 'CC'.
*\      WHEN '02' OR 'CA' OR '2'.
*\        wa_cre-bkont = 'CA'.
*\    ENDCASE.
    CASE wa_bkont.
      WHEN '01' OR 'CC' OR '1'.
        wa_cre-bkont = 'CC'.
      WHEN '02' OR 'CA' OR '2'.
        wa_cre-bkont = 'CA'.
    ENDCASE.
*}   REPLACE
*    wa_cre-bkont = wa_bkont.
*{   REPLACE        AMDK902338                                        3
*\    wa_cre-bankn = t_reguh-zbnkn.
    wa_cre-bankn = wa_bankn.
*}   REPLACE
    wa_cre-ttype = 'CR'.
    PERFORM add_record.
    PERFORM format_wrbtr_3 USING t_reguh-rwbtr wa_cre-rwbtr t_reguh-waers .
    wa_cre-xblnr = wa_text.
*    WRITE t_reguh-rwbtr TO wa_cre-tximp
*          CURRENCY t_reguh-waers DECIMALS 0 NO-SIGN.
*    IF w_dcpfm <> 'X'.
*      TRANSLATE wa_cre-tximp USING ',..,'.
*    ENDIF.
*    wa_cre-xsec_pro = squence.
    wa_cre-kont = t_reguh-ubknt.
    REPLACE ALL OCCURRENCES OF '-' IN wa_cre-kont WITH ''.
*    TRANSLATE wa_cre-kont USING '- '.
*    CONDENSE wa_cre-kont.
* Obtener las posiciones de documentos pagos.
    SELECT *
      INTO TABLE t_regup
      FROM regup
      WHERE laufd = t_reguh-laufd AND
            laufi = t_reguh-laufi AND
            xvorl = t_reguh-xvorl AND
            zbukr = t_reguh-zbukr AND
            lifnr = t_reguh-lifnr AND
            kunnr = t_reguh-kunnr AND
            empfg = t_reguh-empfg AND
            vblnr = t_reguh-vblnr.

    PERFORM bukrs_data USING bukrs 'X' CHANGING fill_00 wa_cre-nit .
    wa_cre-type_cta = 'CA'."'RO'.
    wa_cre-type_mov = 'DB'.
    LOOP AT t_regup.
      wa_cre-xsec_pro = sy-tabix.
      wa_cre-sec = wa_cre-sec + 1.
      WRITE t_regup-wrbtr TO wa_cre-tximp
            CURRENCY t_reguh-waers DECIMALS 0 NO-SIGN.
      IF w_dcpfm <> 'X'.
        TRANSLATE wa_cre-tximp USING ',..,'.
      ENDIF.
      CONCATENATE t_regup-blart t_regup-belnr t_regup-xblnr
        INTO wa_cre-xblnr SEPARATED BY space.
      APPEND wa_cre TO tab_bcre.
      wa_cre-rwbtr = 0.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " get_bcre_record_1

*&---------------------------------------------------------------------*
*&      Form  download_data_bcre
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_data_bcre .
  IF NOT tab_bcre[] IS INITIAL.
    REFRESH tdw_bcre.
    CLEAR   tdw_bcre.
    INSERT LINES OF tab_bcre INTO tdw_bcre INDEX 1.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
        col_select    = 'X'
      TABLES
        data_tab      = tdw_bcre
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.
    PERFORM lock_f110.
    MESSAGE i398 WITH text-m01 filename.
  ELSE.
    MESSAGE i208 WITH text-m02.
  ENDIF.
ENDFORM.                    " download_data_bcre
