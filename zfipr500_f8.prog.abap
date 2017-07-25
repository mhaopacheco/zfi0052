*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F8
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  GET_BOOC_RECORD_1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_booc_record_1 .
  CLEAR: wa_occi.
  wa_occi-type_rec    = 1.
  wa_occi-addat       = addat.
*  wa_occi-dec_rwbtr   = k_dec_bocc.
  wa_occi-kont        = t_reguh-ubknt.
  DESCRIBE TABLE t_reguh LINES wa_occi-numrecs.
  PERFORM format_wrbtr_7 USING t_reguh-rwbtr wa_occi-rwbtr.
  APPEND wa_occi.
ENDFORM.                    " GET_BOOC_RECORD_1

*&---------------------------------------------------------------------*
*&      Form  GET_BOCC_RECORD_2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_bocc_record_2 .
  DATA: w_cons(4) TYPE n,
        w_stcd    TYPE lfa1-stcd1.
  REFRESH: tab_occi.

  PERFORM get_regup.
**MOD: 10/12/2009 EN LA RGUH NO SE ESTA LLENANDO LOS DATOS BANCARIOS DEL
**ACREEDOR, POR TANTO SE HACE CONSULTA A TABLA LFBK, QUE CONTIENE CUENTA,
**BANCO Y TIPO CUENTA DEL ACREEDOR.
  CLEAR ti_lfbk.
  SELECT lifnr bankl bankn bkont
  FROM   lfbk
  INTO   TABLE ti_lfbk
  FOR ALL ENTRIES IN t_reguh
  WHERE  lifnr = t_reguh-lifnr.

  LOOP AT t_reguh.
    CLEAR: tab_occi, w_stcd. "lfbk, tab_occi, prq_rcc, wa_lifnr.
    w_cons = w_cons + 1.
    tab_occi-type_rec = '2'.
    tab_occi-consec = w_cons.
    tab_occi-kont   = t_reguh-ubknt.
    tab_occi-koinh  = t_reguh-znme1.
    SELECT SINGLE stcdt INTO w_stcd
    FROM lfa1
    WHERE stcd1 = t_reguh-zstc1.
    IF w_stcd  = '31'.
      tab_occi-stcd1  = t_reguh-zstc1+0(10).
    ELSE.
      tab_occi-stcd1  = t_reguh-zstc1.
    ENDIF.

    IF NOT ti_lfbk[] IS INITIAL.
      READ TABLE ti_lfbk WITH KEY lifnr = t_reguh-lifnr.
      IF sy-subrc = '0'.
        tab_occi-bankl = ti_lfbk-bankl.
        tab_occi-bankn  = ti_lfbk-bankn.
        IF ti_lfbk-bkont = '01' OR ti_lfbk-bkont = 'CC'.
          tab_occi-bkont = 'C'.
        ELSE.
          tab_occi-bkont = 'A'.
        ENDIF.
      ENDIF.
    ENDIF.


***MOD: MQA-MNG AUTONAL
*    tab_occi-bankl  = t_reguh-zbnkl.

****MOD: MQA-MNG    CARVAL CALI
****Si el banco de transferencia es Bancafe se toma codigo ACH ya que cambia
****por banco de transferencia
*    tab_occi-bankl = t_reguh-zbnkl.
*    IF tab_occi-bankl = '05'.
*      PERFORM data_bankl USING t_reguh-zbnkl
*                               t_reguh-ubnkl
*                      CHANGING w_bankl.
*      tab_occi-bankl = w_bankl.
*    ENDIF.

    tab_occi-addat  = addat.
***tab_occi-payfmr,
    PERFORM add_record.
    PERFORM format_wrbtr_7 USING t_reguh-rwbtr tab_occi-rwbtr.
    tab_occi-vbeln = t_reguh-vblnr.
    SHIFT tab_occi-vbeln RIGHT DELETING TRAILING ' '.
    "Eliminando espacios de la cuenta del banco del beneficiario
    CONDENSE t_reguh-zbnkn NO-GAPS.
    " Llenando con ceros a la izquierda el numero de cuenta del beneficiario
    "CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    "  EXPORTING
    "    input  = t_reguh-zbnkn
    "  IMPORTING
    "    output = tab_occi-bankn.

*    tab_occi-bankn = t_reguh-zbnkn.
*     tab_bbog-vbeln = T_REGUH-LAUFI.
*    tab_bbog-fill01 = 0.
*    tab_bbog-bankn = t_reguh-zbnkn(17).

*** MQA-MNG AUTONAL
*    IF t_reguh-zbkon = '01' OR t_reguh-zbkon = 'CC'.
*      tab_occi-bkont = 'C'.
*    ELSE.
*      tab_occi-bkont = 'A'.
*    ENDIF.

    IF t_reguh-zbnkl = t_reguh-ubnkl.               " Banco Receptor =
      tab_occi-payfmr = '2'.                        " Forma de pago
    ELSE.
      tab_occi-payfmr = '3'.
    ENDIF.

    IF not t_reguh-EMPFG is initial and
       not t_reguh-ZBNKN is initial.
           tab_occi-bankl = t_reguh-ZBNKL. "Código bancario del banco del receptor del pago
           tab_occi-bankn = t_reguh-ZBNKN. "Número de cuenta bancaria del receptor del pago
*           tab_bbog-bkont = t_reguh-ZBKON."Clave de control de bancos del banco del receptor del pago
    ENDIF.

    APPEND tab_occi.
  ENDLOOP.
ENDFORM.                    " GET_BOCC_RECORD_2
*&---------------------------------------------------------------------*
*&      Form  GET_BOCC_RECORD_3
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_bocc_record_3 .
  CLEAR: fo_occi.
  fo_occi-type_rec    = 3.
  fo_occi-fill01      = '9999'.
  DESCRIBE TABLE t_reguh LINES wa_occi-numrecs.
  PERFORM format_wrbtr_7 USING resume-sumite fo_occi-rwbtr.
  fo_occi-numrecs     = resume-nitems.
  APPEND fo_occi.
  wa_occi-rwbtr   = fo_occi-rwbtr.
  MODIFY wa_occi INDEX 1.
ENDFORM.                    " GET_BOCC_RECORD_3
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_DATA_BOOC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_data_booc .
  DATA: w_tdw_occi LIKE LINE OF tdw_occi,
        w_namefile TYPE string.

  DESCRIBE TABLE tab_occi.
  IF sy-tfill NE 0.
    REFRESH tdw_occi.
    CLEAR   tdw_occi.
    w_namefile = filename.

    INSERT LINES OF wa_occi INTO tdw_occi INDEX 1.
    INSERT LINES OF tab_occi INTO tdw_occi INDEX 2.
    DESCRIBE TABLE tdw_occi.
    sy-tfill = sy-tfill + 1.
    INSERT LINES OF fo_occi INTO tdw_occi INDEX sy-tfill.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                  = w_namefile
        trunc_trailing_blanks_eol = ' '
      TABLES
        data_tab                  = tdw_occi.
    IF sy-subrc = 0.
      MESSAGE i398 WITH text-m01 filename.
    ELSE.
      MESSAGE i208 WITH text-m02.
    ENDIF.
  ENDIF.
ENDFORM.                    " DOWNLOAD_DATA_BOOC
