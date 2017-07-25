*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F3
*&---------------------------------------------------------------------*


*---------------------------------------------------------------------*
*       FORM get_bcol_record_1                                        *
*---------------------------------------------------------------------*
*       Registro tipo 1 para el Banco de Colombia                     *
*---------------------------------------------------------------------*
FORM get_bcol_record_1.
  CLEAR: wa_bcol.

  DATA: lv_bkont TYPE bkont .

  wa_bcol-type_rec = 1.

  PERFORM bukrs_data_col USING bukrs 'X' CHANGING wa_bcol-namebks wa_bcol-nit .

*   wa_bcol-nit = wa_bcol-nit(10).
*  OVERLAY wa_bcol-nit WITH '0000000000'.
*}   INSERT
  wa_bcol-type_mov = format(4).
  wa_bcol-objetive = wa_text.
  wa_bcol-laufd    = f110v-laufd+2(6).
  wa_bcol-sendsec  = 'A'.
  wa_bcol-addat    = addat+2(6).
  wa_bcol-debwrbtr = 0.
  wa_bcol-kont     = t_reguh-ubknt.

  CLEAR lv_bkont .
  IF t_reguh-ubkon IS INITIAL .
    SELECT SINGLE bkont INTO lv_bkont FROM t012k WHERE bukrs = t_reguh-zbukr AND
                                                       hbkid = t_reguh-hbkid AND
                                                       hktid = t_reguh-hktid .
  ELSE .
    MOVE t_reguh-ubkon TO lv_bkont .
  ENDIF.

  CASE lv_bkont .
    WHEN 'CC' OR '01'.
      wa_bcol-type_cta = 'D'.
    WHEN 'CA' OR '02'.
      wa_bcol-type_cta = 'S'.
  ENDCASE.
ENDFORM.                    " get_bcol_record_1

*---------------------------------------------------------------------*
*       FORM get_conav_record                                         *
*---------------------------------------------------------------------*
*       Registro tipo 1 para el Conavi                                *
*---------------------------------------------------------------------*
FORM get_conav_record .
  IF format = 'E'.
    wa_cnav-format = 'NOE'.
  ELSE.
    wa_cnav-format = 'PPE'.
  ENDIF.
  wa_cnav-objetive = format.
  wa_cnav-kont = t_reguh-ubknt.
  CASE t_reguh-ubkon.
    WHEN 'CC' OR '01'.
      wa_cnav-type_cta = '1'.
    WHEN 'CA' OR '02'.
      wa_cnav-type_cta = '2'.
  ENDCASE.
ENDFORM.                    " get_conav_record

*---------------------------------------------------------------------*
*       FORM get_bcol_record_2                                        *
*---------------------------------------------------------------------*
*       Registro tipo 2 para el Banco de Colombia                     *
*---------------------------------------------------------------------*
FORM get_bcol_record_2.
* SelecciÃ³n de pagos para:
* 1. Fecha dada,
* 2. Via de pago: Transferencias bancarias,
* 3. Registros ejecutados (no propuestas), e
* 4. Importes (en moneda local) distintos de 0.
  DATA:   wa_fax       TYPE adrc-fax_number,
          bank_code(3) TYPE n,
          mssge(60),
          w_zstc1      TYPE lifnr,
*{   INSERT         AMDK902338                                        3
          wa_bkont TYPE lfbk-bkont,
          wa_bankn TYPE lfbk-bankn,
          wa_bankl TYPE lfbk-bankl,
*}   INSERT
          w_stcdt  TYPE j_1atoid,
          wa_adrnr TYPE lfa1-adrnr,
          wa_email(50),
          contador_registros(5) TYPE n,
          wa_facturas(93),
          count TYPE i.

  CLEAR:   tab_bcol,tab_bcol_txt,tab_bcol_email.
  REFRESH: tab_bcol,tab_bcol_txt,tab_bcol_email.
* Maestro de bancos, para obtener cÃ³digo ACH
  DATA: t_bnka TYPE STANDARD TABLE OF bnka WITH HEADER LINE.
  SELECT * INTO TABLE t_bnka FROM bnka.
  CLEAR: lfbk,
         mssge.

  PERFORM  get_regup.

  contador_registros = 1.
  LOOP AT t_reguh.
    tab_bcol-type_rec = 6 .
*** SI ES PERSONA NATURAL SE QUITA DIGITO DE VERIFICACION
    PERFORM get_stcd1 USING t_reguh-zstc1 CHANGING tab_bcol-stcd1 w_stcdt .
    tab_bcol-koinh = t_reguh-znme1.
*** MQA/MNG 15.09.08  FUNCIONA OK
*MOD 15/09/2007 MNG SE COMENTARIO ESTA FUNCION, SE ENVIA PARAMETRO
*PERO DE TABLA CON DATOS BANCARIOS ACREEDOR
    DATA: v_cod_bancol TYPE zcond_bancol.
    SELECT SINGLE bankn bkont bankl
          INTO (wa_bankn, wa_bkont, wa_bankl)
          FROM lfbk
         WHERE lifnr = t_reguh-lifnr.
    IF sy-subrc = 0.
      SELECT SINGLE cod_bancol INTO v_cod_bancol
      FROM zfi_valida_banco
      WHERE bankl = wa_bankl.
      tab_bcol-bankl = v_cod_bancol.
    ENDIF.

    IF tab_bcol-bankl IS INITIAL OR tab_bcol-bankl = '000000000'.
      SELECT SINGLE rccode INTO tab_bcol-bankl
        FROM zbnka_ach
         WHERE banks = t_reguh-ubnks
           AND bankl = t_reguh-ubnkl
           AND bankt = wa_bankl.
    ENDIF.

    tab_bcol-bankn = wa_bankn.
    tab_bcol-place = '3'.
    tab_bcol-place = 'S'.
    IF wa_bkont = 'CC' OR wa_bkont = '01'.
      tab_bcol-typtrans = '27'.
    ELSE.
      tab_bcol-typtrans = '37'.
    ENDIF.
    PERFORM add_record.
    PERFORM format_wrbtr_3 USING t_reguh-rwbtr tab_bcol-rwbtr t_reguh-waers .
    tab_bcol-xblnr = wa_text.
    CONCATENATE '00' t_reguh-vblnr INTO tab_bcol-xblnr1 .

    tab_bcol-fill03 = contador_registros.

    IF not t_reguh-EMPFG is initial and
       not t_reguh-ZBNKN is initial.
      tab_bcol-bankl = t_reguh-ZBNKL. "Código bancario del banco del receptor del pago
      tab_bcol-bankn = t_reguh-ZBNKN. "Número de cuenta bancaria del receptor del pago
*      tab_bcol-bkont = t_reguh-ZBKON."Clave de control de bancos del banco del receptor del pago
    ENDIF.

    APPEND tab_bcol.

    CLEAR: wa_facturas.
    LOOP AT t_regup WHERE laufd = t_reguh-laufd AND
                          laufi = t_reguh-laufi AND
                          xvorl = t_reguh-xvorl AND
                          zbukr = t_reguh-zbukr AND
                          lifnr = t_reguh-lifnr AND
                          kunnr = t_reguh-kunnr AND
                          empfg = t_reguh-empfg AND
                          vblnr = t_reguh-vblnr.
      CONCATENATE wa_facturas t_regup-xblnr INTO wa_facturas SEPARATED BY ' '.
    ENDLOOP.

    CONCATENATE 'PAGO FACTURAS' wa_facturas INTO wa_facturas SEPARATED BY space.

    count = 0.
    DO 93 TIMES.
      IF wa_facturas+count(1) = ''.
        wa_facturas+count(1) = '*'.
      ENDIF.
      count = count + 1.
    ENDDO.

*-- Llenado Correo Electronico
    SELECT SINGLE adrnr INTO wa_adrnr
      FROM lfa1
      WHERE lifnr = t_reguh-lifnr.
    CLEAR wa_email.
    PERFORM get_e_mail USING wa_adrnr CHANGING wa_email.
    tab_bcol_email-type_rec   = '3'.
    tab_bcol_email-type_info  = '@'.
    tab_bcol_email-fill03     = contador_registros.
    tab_bcol_email-email      = wa_email.
    APPEND tab_bcol_email.
    CLEAR tab_bcol_email.

    tab_bcol_txt-type_rec  = '3'.
    tab_bcol_txt-type_info = '*'.
    tab_bcol_txt-fill03    = wa_facturas.
    tab_bcol_txt-contador  = contador_registros.
    APPEND  tab_bcol_txt.

    contador_registros = contador_registros + 1.
  ENDLOOP.

* Número de registros en el detalle
  DESCRIBE TABLE tab_bcol LINES wa_bcol-numrecs.

  LOOP AT tab_bcol_email.
    wa_bcol-numrecs = wa_bcol-numrecs + 1.
  ENDLOOP.

  LOOP AT tab_bcol_txt.
    wa_bcol-numrecs = wa_bcol-numrecs + 1.
  ENDLOOP.

* Importe total en el detalle
  LOOP AT tab_bcol.
    wa_bcol-crewrbtr = wa_bcol-crewrbtr + tab_bcol-rwbtr.
  ENDLOOP.
ENDFORM.                    " get_bcol_record_2


*---------------------------------------------------------------------*
*       FORM get_cnav_data                                            *
*---------------------------------------------------------------------*
*       Registro tipo 2 para conavi                                   *
*---------------------------------------------------------------------*
FORM get_cnav_data.
* SelecciÃ³n de pagos para:
* 1. Fecha dada,
* 2. VÃ­a de pago: Transferencias bancarias,
* 3. Registros ejecutados (no propuestas), e
* 4. Importes (en moneda local) distintos de 0.
  CLEAR: tab_cnav.
  REFRESH: tab_cnav.
  CLEAR: tdw_cnav.
  REFRESH: tdw_cnav.
*  PERFORM get_records.
  CLEAR: lfbk.
  LOOP AT t_reguh.
* SelecciÃ³n datos bancarios del proveedor en el registro de pagos
    SELECT SINGLE *
      FROM lfbk
      WHERE lifnr = reguh-zstc1.
    CHECK sy-subrc = 0.
    tab_cnav-type_rec = 1.
*    tab_cnav-stcd1 = reguh-stcd1.
    CASE lfbk-bkont.
      WHEN '01'.
        tab_cnav-account_type = 1.
      WHEN '02'.
        tab_cnav-account_type = 2.
    ENDCASE.
    tab_cnav-posde = 0.
    PERFORM get_bankl USING lfbk-bankl
                            tab_cnav-bankl
                            lfbk-bankn
                            tab_cnav-office.
    tab_cnav-bankn = lfbk-bankn(17).
    PERFORM format_wrbtr_3 USING reguh-rwbtr tab_cnav-rwbtr t_reguh-waers .
* Importe total en el detalle
    wa_cnav-ammount = wa_cnav-ammount + tab_cnav-rwbtr.
    APPEND tab_cnav.
  ENDLOOP.
* NÃºmero de registros en el detalle
  DESCRIBE TABLE tab_cnav LINES wa_cnav-numrecs.
  IF wa_cnav-numrecs > 0.
    INSERT wa_cnav INTO tdw_cnav INDEX 1.
    INSERT LINES OF tab_cnav INTO tdw_cnav INDEX 2.
  ENDIF.
ENDFORM.                    " get_bcol_record_2

*---------------------------------------------------------------------*
*       FORM download_data_bcol                                       *
*---------------------------------------------------------------------*
*       Baja archivo con la informaciÃ³n en el formato requerido por   *
*       Bancolombia                                                   *
*---------------------------------------------------------------------*
FORM download_data_bcol.
*  DATA: w_namefile TYPE string.
  DATA: cont(5) TYPE n.
  REFRESH tdw_bcol.
  CLEAR   tdw_bcol.
  IF NOT tab_bcol[] IS INITIAL.
    INSERT wa_bcol INTO tdw_bcol INDEX 1.

*   Registros detalles
    LOOP AT tab_bcol .
      CONDENSE tab_bcol-fill03 NO-GAPS.
      cont = tab_bcol-fill03.
      tab_bcol-fill03 = space.
      tdw_bcol-reg = tab_bcol.
      APPEND tdw_bcol .

      LOOP AT tab_bcol_email WHERE fill03 = cont.
        tab_bcol_email-fill03 = '****************************************************'.
        tdw_bcol-reg = tab_bcol_email.
        APPEND tdw_bcol.
        CLEAR: tdw_bcol.
      ENDLOOP.

      LOOP AT tab_bcol_txt WHERE contador = cont.
        CLEAR: tab_bcol_txt-contador.
        tdw_bcol-reg = tab_bcol_txt.
        APPEND tdw_bcol.
        CLEAR: tdw_bcol.
      ENDLOOP.
    ENDLOOP .


*    INSERT LINES OF tab_bcol INTO tdw_bcol INDEX 2.

    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
*       filetype      = 'TXT'
        col_select    = 'X'
      TABLES
        data_tab      = tdw_bcol
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.
    PERFORM lock_f110.
    MESSAGE i398 WITH text-m01 filename.
  ELSE.
    MESSAGE i208 WITH text-m02.
  ENDIF.
ENDFORM.                    " download_data_bcol

*---------------------------------------------------------------------*
*       FORM download_data_cnav                                       *
*---------------------------------------------------------------------*
*       Baja archivo con la informaciÃ³n en el formato requerido por   *
*       Conavi                                                   *
*---------------------------------------------------------------------*
FORM download_data_cnav.
  IF NOT tdw_cnav[] IS INITIAL.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
        col_select    = 'X'
      TABLES
        data_tab      = tdw_cnav
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.

    MESSAGE i398 WITH text-m01 filename.
  ELSE.
    MESSAGE i208 WITH text-m02.
  ENDIF.
ENDFORM.                    " download_data_bcol

*---------------------------------------------------------------------*
*       FORM format_wrbtr_3                                           *
*---------------------------------------------------------------------*
*       Da formato al importe segÃºn requerimientos del banco          *
*---------------------------------------------------------------------*
*  -->  PRWBTR : Importe en formato tipo P                            *
*  -->  NRWBTR : Importe en formato tipo N                            *
*---------------------------------------------------------------------*
FORM format_wrbtr_3 USING prwbtr
                          nrwbtr
                          p_waers TYPE waers  .
  DATA: srwbtr(10).
  WRITE: prwbtr TO srwbtr CURRENCY p_waers NO-SIGN DECIMALS 0 .
  TRANSLATE srwbtr USING ', . '.
  CONDENSE srwbtr NO-GAPS.
  nrwbtr = srwbtr.
ENDFORM.                    " format_wrbtr_3

*---------------------------------------------------------------------*
*       FORM get_bankl                                                *
*---------------------------------------------------------------------*
*       Obtiene los cÃ³digo de los bancos                              *
*---------------------------------------------------------------------*
*  -->  P_BANKL : CÃ³digo del banco en SAP (maestro de bancos)         *
*  -->  T_BANKL : CÃ³digo externo (lista de bancos)                    *
*---------------------------------------------------------------------*
FORM get_bankl USING p_bankl
                     t_bankl
                     p_kont
                     t_office.
  CASE p_bankl.
* Bancolombia
    WHEN '003' OR '007' OR '07' OR 'BA0171' OR 'BA2112'.
      t_bankl = 005600078.
* Conavi
    WHEN '55' OR '055' OR 'VI2041' OR 'VI3062'.
      t_bankl = 0570110.
      IF NOT p_kont IS INITIAL.
        t_office = p_kont(4).
      ENDIF.
* Citibank
    WHEN '009'.
      t_bankl = 005600094.
* Davivienda
    WHEN '051'.
      t_bankl = 005895142.
* Colpatria
    WHEN '019' OR 'CO0012' OR 'CO0171'.
      t_bankl = 005600191.
* Santander
    WHEN '006'.
      t_bankl = 005600065.
* Banco CrÃ©dito
    WHEN '014'.
      t_bankl = 005600146.
* Sudameris
    WHEN '012' OR 'SU9007'.
      t_bankl = 005600120.
* Banco de Occidente
    WHEN '023' OR 'OC0234'.
      t_bankl = 005600230.
* Banco UniÃ³n Colombiano
    WHEN 'BU5991'.
      t_bankl = 005600227.
* Banco Popular
    WHEN '002'.
      t_bankl = 005600023.
* Interbanco
    WHEN 'IN0000' OR 'IN0001'.
      t_bankl = 005600353.
* Tequendama
    WHEN 'TE0007'.
      t_bankl = 005600298.
* ABN AMRO
    WHEN '008'.
      t_bankl = 005600081.
* Banco de BogotÃ¡
    WHEN '001' OR 'BO0093' OR 'BO093'.
      t_bankl = 005600010.
* Banco Cafetero
    WHEN 'CF1001'.
      t_bankl = 005600052.
* Banco Ganadero
    WHEN '013'.
      t_bankl = 005600133.
  ENDCASE.
ENDFORM.                    " get_bankl

*---------------------------------------------------------------------*
*       FORM get_cnav_data2                                           *
*---------------------------------------------------------------------*
*       Registro tipo 2 para conavi                                   *
*---------------------------------------------------------------------*
FORM get_cnav_data2.
* SelecciÃ³n de pagos para:
* 1. Fecha dada,
* 2. VÃ­a de pago: Transferencias bancarias,
* 3. Registros ejecutados (no propuestas), e
* 4. Importes (en moneda local) distintos de 0.
  DATA: w_regup TYPE regup,
        count TYPE i,
        ti_reguh TYPE STANDARD TABLE OF reguh WITH HEADER LINE.

  CLEAR: tab_cnav2, tdw_cnav.
  REFRESH: tab_cnav3, tdw_cnav.
*  PERFORM get_records.
  LOOP AT ti_reguh.
    CLEAR: lfbk.
    CLEAR tab_cnav2.
* SelecciÃ³n datos bancarios del proveedor en el registro de pagos
    SELECT SINGLE *
      FROM lfbk
      WHERE lifnr = ti_reguh-zstc1.
    CHECK sy-subrc = 0.
    tab_cnav2-type_rec = 1.
    CASE lfbk-bkont.
      WHEN '01' OR 'CC'.
        tab_cnav2-account_type = 1.
      WHEN '02' OR 'CA'.
        tab_cnav2-account_type = 2.
    ENDCASE.
    tab_cnav2-posde = 0.
*    tab_cnav-stcd1 = ti_reguh-stcd1.
    PERFORM get_bankl USING lfbk-bankl
                            tab_cnav2-bankl
                            lfbk-bankn
                            tab_cnav2-office.
    tab_cnav2-bankn = lfbk-bankn(17).
    PERFORM format_wrbtr_3 USING ti_reguh-rwbtr tab_cnav2-rwbtr t_reguh-waers .
    wa_cnav-ammount = wa_cnav-ammount + tab_cnav2-rwbtr.
    CLEAR tab_cnav3.
    REFRESH tab_cnav3.
    SELECT * INTO w_regup
        FROM regup
        WHERE laufd = ti_reguh-laufd AND
              laufi = ti_reguh-laufi AND
              xvorl = ti_reguh-xvorl AND
              zbukr = ti_reguh-zbukr AND
              lifnr = ti_reguh-lifnr AND
              kunnr = ti_reguh-kunnr.
      PERFORM format_wrbtr_3 USING w_regup-dmbtr tab_cnav3-amount t_reguh-waers .
      tab_cnav3-docref = w_regup-xblnr.
      tab_cnav3-signpos = '+'.
      tab_cnav3-signneg = '-'.
      tab_cnav3-type_rec = 2.
      tab_cnav3-dscdec = 0.
      tab_cnav3-pagdec = 0.
      APPEND tab_cnav3.
    ENDSELECT.
*    APPEND tab_cnav2.
    DESCRIBE TABLE tab_cnav3 LINES tab_cnav2-details.
    APPEND tab_cnav2 TO tdw_cnav.
    APPEND LINES OF tab_cnav3 TO tdw_cnav.
  ENDLOOP.
  DESCRIBE TABLE ti_reguh LINES wa_cnav-numrecs.
  INSERT wa_cnav INTO tdw_cnav INDEX 1.
ENDFORM.                    " get_bcol_record_2

*&--------------------------------------------------------------------*
*&      Form  bukrs_name
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_BUKRS    text
*      -->P_NAME     text
*---------------------------------------------------------------------*
FORM bukrs_data_col USING p_bukrs p_split CHANGING p_name p_nit .
  DATA: wa_nit TYPE t001z-paval,
        fill.
  SELECT SINGLE butxt INTO p_name FROM t001 WHERE bukrs = p_bukrs .
  SELECT SINGLE paval INTO wa_nit FROM t001z WHERE bukrs = p_bukrs  AND
                                                   party = 'CO_NIT' .
  IF wa_nit CN '0123456789- ' .
    "Los mensajes están montados en ZFITB 07/02/2012 JDG
    "MESSAGE e017(zfi) WITH wa_nit.
    MESSAGE e017(zfitb) WITH wa_nit.
*   El nit de la empresa contiene cartacteres no válidos: &
    EXIT.
  ENDIF.
  IF p_split = 'X'.
**    UNPACK wa_nit TO p_nit.
    p_nit = wa_nit.
*    concatenate '0' p_nit into p_nit .
*   SPLIT wa_nit AT '-' INTO wa_nit fill.
  ELSE.
    REPLACE '-' IN wa_nit WITH space.
  ENDIF.
* UNPACK wa_nit TO p_nit.
ENDFORM.                    "bukrs_name
