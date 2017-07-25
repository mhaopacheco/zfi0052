*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F1
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&       FORM get_bbog_record_1                                        *
*&---------------------------------------------------------------------*
*&       Registro tipo 1 para el Banco de Bogotá                       *
*&---------------------------------------------------------------------*
FORM get_bbog_record_1.
  CLEAR: wa_bog.
  wa_bog-type_rec   = 1.
  wa_bog-addat      = addat.
  wa_bog-kont       = t_reguh-ubknt.
  wa_bog-type_mov   = format.
  wa_bog-codcity    = kcitbbog.
  wa_bog-laufd      = addat. "f110v-laufd. fecha de transferencia
  wa_bog-oficce     = wa_bog-kont(3).
  wa_bog-type_id    = 'N'.
  wa_bog-fill_s     = ' '.
  wa_bog-fill04     = space.
  CASE t_reguh-ubkon.
    WHEN 'CC' OR '01'.
      wa_bog-type_cta = '1'.
    WHEN 'CA' OR '02'.
      wa_bog-type_cta = '2'.
  ENDCASE.
  PERFORM bukrs_data USING bukrs space
                     CHANGING wa_bog-namebks wa_bog-nit.
ENDFORM.                    "get_bbog_record_1


*---------------------------------------------------------------------*
*       FORM bbog_record_2                                            *
*---------------------------------------------------------------------*
*       Registros tipo 2 para Banco de Bogotá                         *
*---------------------------------------------------------------------*
FORM get_bbog_record_2.
  DATA: mssge(60),
        w_zstc1 TYPE lifnr.
* Selección de pagos para:
* 1. Fecha dada,
* 2. Vía de pago: Transferencias bancarias,
* 3. Registros ejecutados (no propuestas), e
* 4. Importes (en moneda local) distintos de 0.
  DATA:   wa_stcdt TYPE lfa1-stcdt,
          wa_lifnr TYPE lifnr,
          wa_adrnr TYPE lfa1-adrnr,
          wa_bankl TYPE dzbnkl,
          t_adr6   TYPE STANDARD TABLE OF adr6 WITH HEADER LINE,
          bank_code(3) TYPE n,
          wa_email(50),
          wa_facturas(160),
          prq_rcc(15),
          contador_registros(5) TYPE n.

  REFRESH: tab_bbog,tab_bbog_email_2,tab_bbog_email.
  PERFORM  get_regup.
  REFRESH  tab_bbog_msg.

**MOD: 10/12/2009 EN LA RGUH NO SE ESTA LLENANDO LOS DATOS BANCARIOS DEL
**ACREEDOR, POR TANTO SE HACE CONSULTA A TABLA LFBK, QUE CONTIENE CUENTA,
**BANCO Y TIPO CUENTA DEL ACREEDOR.
  CLEAR: ti_lfbk,contador_registros.
  SELECT lifnr bankl bankn bkont
  FROM   lfbk
  INTO   TABLE ti_lfbk
  FOR ALL ENTRIES IN t_reguh
  WHERE  lifnr = t_reguh-lifnr.
*
  contador_registros = 1.
  LOOP AT t_reguh.
    CLEAR: lfbk, mssge, tab_bbog, prq_rcc.
* Selección datos bancarios del proveedor en el registro de pagos
    wa_lifnr = t_reguh-zstc1.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = wa_lifnr
      IMPORTING
        output = wa_lifnr.
    SELECT SINGLE stcdt adrnr
      INTO (wa_stcdt, wa_adrnr)
      FROM lfa1
      WHERE stcd1 = t_reguh-zstc1 AND
            ktokk <> 'CONT' AND
            stcdt <> '  '.
    IF sy-subrc = 4.
      CONCATENATE 'El tercero:' t_reguh-zstc1
                  'no tiene datos registrados'
                  INTO  mssge SEPARATED BY space.
      MESSAGE mssge TYPE 'W'.
      CONTINUE.
    ENDIF.
    tab_bbog-type_rec = 2.
    CLEAR tab_bbog-type_id.
*    SELECT SINGLE tynif INTO tab_bbog-type_id
*    FROM ztynif_trn
*    WHERE j_1atodc = wa_stcdt.

    IF wa_stcdt = '13'.
      tab_bbog-type_id = 'C'.
    ELSEIF wa_stcdt = '12'.
      tab_bbog-type_id = 'T'.
    ELSEIF wa_stcdt = '22'.
      tab_bbog-type_id = 'E'.
    ELSE.
      tab_bbog-type_id = 'N'.
    ENDIF.

    tab_bbog-stcd1  = t_reguh-zstc1.
    tab_bbog-vbeln  = t_reguh-vblnr.

***MOD. MQA-MNG se hace consulta en trabla interna, en la RGUH no tre datos de tercero
    IF NOT ti_lfbk[] IS INITIAL.
      READ TABLE ti_lfbk WITH KEY lifnr = t_reguh-lifnr.
      IF sy-subrc = '0'.
        "WRM:14.12.12,8.1980,Begin
        IF not t_reguh-EMPFG is initial and
           not t_reguh-ZBNKN is initial.
          tab_bbog-bankl = t_reguh-ZBNKL. "Código bancario del banco del receptor del pago
          tab_bbog-bankn = t_reguh-ZBNKN. "Número de cuenta bancaria del receptor del pago
          tab_bbog-bkont = t_reguh-ZBKON."Clave de control de bancos del banco del receptor del pago
        ELSE.
          "WRM:14.12.12,8.1980,End
          PERFORM data_bankl USING ti_lfbk-bankl
                                   t_reguh-ubnkl
                             CHANGING w_bankl.
          tab_bbog-bankl = w_bankl.
          tab_bbog-bankn  = ti_lfbk-bankn.
          IF ti_lfbk-bkont = '01' OR ti_lfbk-bkont = 'CC'.
            tab_bbog-bkont = '1'.
          ELSE.
            tab_bbog-bkont = '2'.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    tab_bbog-koinh  = t_reguh-znme1.
    tab_bbog-fill01 = 0.
*** MOD MQA-MNG CODIGO COMENTARIADO
*    IF t_reguh-zbkon = '01' OR t_reguh-zbkon = 'CC'.
*      tab_bbog-bkont = '1'.
*    ELSE.
*      tab_bbog-bkont = '2'.
*    ENDIF.
*    tab_bbog-bankn = t_reguh-zbnkn(17).
* Para control sumar y aumentar contador
    PERFORM add_record.
    PERFORM format_wrbtr_1 USING t_reguh-rwbtr tab_bbog-rwbtr.
    tab_bbog-payfmr  = 'A'.
    tab_bbog-bvtyp   = '0001'.
    tab_bbog-orige   = wa_bog-namebks.
    tab_bbog-fill07  = contador_registros.
    tab_bbog-faxmail = 'N'.
* Se usa cuando envía registro adicional con numero de factura
    tab_bbog-message = 'N'.

***MOD MQA-MNG No está trayendo datps la RGUH
*    tab_bbog-bankl = t_reguh-zbnkl.
**    IF tab_bbog-bankl = '05'.
**      PERFORM data_bankl USING t_reguh-zbnkl
**                               t_reguh-ubnkl
**                      CHANGING w_bankl.
**      tab_bbog-bankl = w_bankl.
**    ENDIF.


*** MOD: MQA-MNG   CARVAL - CALI
*** COD COMENTARIADO: No se genera archivo de mensajes
*    bbog_msg_h-messg = text-001.
*    bbog_msg_h-bkont = tab_bbog-bkont.
*    bbog_msg_h-bankn = tab_bbog-bankn.
*    bbog_msg_h-rwbtr = tab_bbog-rwbtr.
*    tab_bbog_msg-content = bbog_msg_h.
*    APPEND tab_bbog_msg.
*    CLEAR tab_bbog.
*** ENDMOD.
    CLEAR: wa_facturas.
    LOOP AT t_regup WHERE laufd = t_reguh-laufd AND
                          laufi = t_reguh-laufi AND
                          xvorl = t_reguh-xvorl AND
                          zbukr = t_reguh-zbukr AND
                          lifnr = t_reguh-lifnr AND
                          kunnr = t_reguh-kunnr AND
                          empfg = t_reguh-empfg AND
                          vblnr = t_reguh-vblnr.
      CONCATENATE tab_bbog-xblnr t_regup-xblnr INTO tab_bbog-xblnr
      SEPARATED BY '-'.
    ENDLOOP.
    wa_facturas = tab_bbog-xblnr.
** registros tipo 2
    APPEND tab_bbog.

** Datos Email registros tipo 3
    CLEAR wa_email.
    PERFORM get_e_mail USING wa_adrnr CHANGING wa_email.
    tab_bbog_email-type_rec = 3.
    tab_bbog_email-email    = wa_email.
    tab_bbog_email-texto    = wa_facturas.
    tab_bbog_email-fill01   = contador_registros.
    APPEND tab_bbog_email.
    APPEND tab_bbog_email.
    CLEAR tab_bbog_email.

    tab_bbog_email_2-type_rec = 3.             " Tipo de registro (3)
    tab_bbog_email_2-email    = wa_email.
    tab_bbog_email_2-via_mail = wa_facturas.
    tab_bbog_email_2-fill01   = contador_registros.
    APPEND tab_bbog_email_2.
    CLEAR tab_bbog_email_2.
    contador_registros = contador_registros + 1.
  ENDLOOP.
ENDFORM.                    "get_bbog_record_2


*---------------------------------------------------------------------*
*       FORM format_wrbtr_1                                           *
*---------------------------------------------------------------------*
*       Da formato al importe según requerimientos del banco          *
*---------------------------------------------------------------------*
*  -->  PRWBTR : Importe en formato tipo P                            *
*  -->  NRWBTR : Importe en formato tipo N                            *
*---------------------------------------------------------------------*
FORM format_wrbtr_1 USING prwbtr
                          nrwbtr.
  DATA: srwbtr(18).
  WRITE: prwbtr TO srwbtr CURRENCY 'COP'
                          NO-SIGN
                          DECIMALS 2.
  TRANSLATE srwbtr USING ', . '.
  CONDENSE srwbtr NO-GAPS.
  nrwbtr = srwbtr.
ENDFORM.                    " format_wrbtr_1

*---------------------------------------------------------------------*
*       FORM download_data_bbog                                       *
*---------------------------------------------------------------------*
*       Baja archivo con la información en el formato requerido por   *
*       el Banco de Bogotá                                            *
*---------------------------------------------------------------------*
FORM download_data_bbog.
  DATA: w_tdw_bbog LIKE LINE OF tdw_bbog,
        w_msg_file LIKE filename,
        w_cont(5)  TYPE n.

  IF NOT tab_bbog[] IS INITIAL.

    DATA: w_namefile TYPE string.
    REFRESH tdw_bbog.
    CLEAR   tdw_bbog.
    w_namefile = filename.
    INSERT wa_bog INTO tdw_bbog INDEX 1.
*    INSERT LINES OF tab_bbog INTO tdw_bbog INDEX 2.

* Codigo Plastilene
    LOOP AT tab_bbog.
      CONDENSE tab_bbog-fill07 NO-GAPS.
      w_cont = tab_bbog-fill07.
      CLEAR tab_bbog-fill07.
      tdw_bbog-reg = tab_bbog.
      APPEND tdw_bbog.

      LOOP AT tab_bbog_email WHERE fill01 = w_cont.
        CLEAR tab_bbog_email-fill01.
        tdw_bbog-reg = tab_bbog_email.
        APPEND tdw_bbog.
      ENDLOOP.

      LOOP AT tab_bbog_email_2 WHERE fill01 = w_cont.
        CLEAR tab_bbog_email_2-fill01.
        tdw_bbog-reg = tab_bbog_email_2.
        APPEND tdw_bbog.
      ENDLOOP.
    ENDLOOP.
***  Fin Plastilene

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
*       BIN_FILESIZE              =
        filename                  = w_namefile
        trunc_trailing_blanks_eol = ' '
      TABLES
        data_tab                  = tdw_bbog.
    IF sy-subrc = 0.
      MESSAGE i398 WITH text-m01 filename.
    ELSE.
      MESSAGE i208 WITH text-m02.
    ENDIF.
  ENDIF.
ENDFORM.                    " download_data_bbog

*&--------------------------------------------------------------------*
*&      Form  select_bank
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
"FORM select_bank.
"  CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
"    EXPORTING
"      action               = 'S'
"      show_selection_popup = 'X'
"      view_name            = 'ZBNKA_OPR'.
"ENDFORM.                    "select_bank

*&--------------------------------------------------------------------*
*&      Form  get_regup
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM get_regup.

  REFRESH: t_regup, ti_regup.
  SELECT *
    INTO TABLE t_regup
    FROM regup
    FOR ALL ENTRIES IN t_reguh
    WHERE laufd = t_reguh-laufd AND
          laufi = t_reguh-laufi AND
          xvorl = t_reguh-xvorl AND
          zbukr = t_reguh-zbukr.

  IF t_regup[] is not initial.


    LOOP AT t_regup.
      move-corresponding t_regup to wa_regup.
      append wa_regup to ti_regup.
    ENDLOOP.
    sort ti_regup by laufd laufi xvorl zbukr lifnr waers blart.
  ENDIF.
ENDFORM.                    "get_regup

*&--------------------------------------------------------------------*
*&      Form  get_typid
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_STCDT    text
*      -->CHANGINF   text
*      -->P_TYPE_ID  text
*---------------------------------------------------------------------*
FORM get_typid USING p_stcdt CHANGING p_type_id.
*  CLEAR p_type_id.
*  SELECT SINGLE p_type_id INTO TABLE t_tynif
*  FROM ztynif_trn.
*  where j_1atodc = p_stcdt.
*  READ TABLE t_tynif WITH KEY j_1atodc = p_stcdt.
*  IF sy-subrc = 0.
*    p_type_id = t_tynif-tynif.
*  ELSE.
*    CLEAR p_type_id.
*  ENDIF.
ENDFORM.                    "get_typid
