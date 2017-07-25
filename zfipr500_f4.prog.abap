*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F4
*&---------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       FORM get_colp_record_1                                        *
*---------------------------------------------------------------------*
*       Registro tipo 1 para Colpatria                                *
*---------------------------------------------------------------------*
FORM get_colp_record_1.
  CLEAR: wa_colp1.
  SELECT SINGLE bankn
    INTO bankn
    FROM t012k
    WHERE bukrs = bukrs
      AND hbkid = k_colp
      AND hktid = hktid.
  CHECK sy-subrc = 0.
  wa_colp1-sec = 1.
  wa_colp1-type_rec = '01'.
  CONCATENATE f110v-laufd+6(2)
              f110v-laufd+4(2)
              f110v-laufd(4)
         INTO wa_colp1-laufd.
  wa_colp1-nit = knit.
  CLEAR wa_colp1-keybks.
  wa_colp1-office = '0196'.
  wa_colp1-kont = t_reguh-ubknt.
  wa_colp1-fill02 = space.
ENDFORM.                    " get_colp_record_1

*---------------------------------------------------------------------*
*       FORM get_colp_record_2                                        *
*---------------------------------------------------------------------*
*       Registro tipo 2 para Colpatria                                *
*---------------------------------------------------------------------*
FORM get_colp_record_2.
  DATA: i TYPE i VALUE 1.
* Selección de pagos para:
* 1. Fecha dada,
* 2. Vía de pago: Transferencias bancarias,
* 3. Registros ejecutados (no propuestas), e
* 4. Importes (en moneda local) distintos de 0.
  CLEAR: tab_colp.
  REFRESH: tab_colp.
*  PERFORM get_records.
  LOOP AT t_reguh.
    CLEAR: lfbk.
    i = i + 1.
* Selección datos bancarios del proveedor en el registro de pagos
    SELECT SINGLE * FROM lfbk
      WHERE lifnr = reguh-lifnr.
    CHECK sy-subrc = 0.
    tab_colp-sec = i.
    tab_colp-type_rec = '02'.
    IF lfbk-bankl = '019'.
      tab_colp-bankn = lfbk-bankn(12).
      tab_colp-trans = '902'.
    ELSE.
      tab_colp-banknsap = lfbk-bankn(17).
      tab_colp-trans = '911'.
    ENDIF.
    tab_colp-stcd1 = reguh-stcd1.
    tab_colp-koinh = lfbk-koinh(40).
    tab_colp-typload = ktypload.
    PERFORM format_wrbtr_4 USING reguh-rwbtr tab_colp-rwbtr.
* No registrada:
    CLEAR tab_colp-vbeln.
    CONCATENATE f110v-laufd+6(2)
                f110v-laufd+4(2)
                f110v-laufd(4)
           INTO tab_colp-laufd.
* No regsitrada:
    CLEAR: tab_colp-ctrlpay,
           tab_colp-valrete,
           tab_colp-valiva,
           tab_colp-notedeb,
           tab_colp-wrbtrdeb.
    tab_colp-bankl = lfbk-bankl.
    tab_colp-bkont = lfbk-bkont.
    tab_colp-type_id = k_idcolp.
    CLEAR tab_colp-fill01.
    CONCATENATE text-p00 text-p01
           INTO tab_colp-descript SEPARATED BY space.
    tab_colp-fill02 = space.
    APPEND tab_colp.
    PERFORM add_record .
  ENDLOOP.
  wa_colp3-sec = i + 1.
  wa_colp3-type_rec = '03'.
  wa_colp3-fill02 = space.
ENDFORM.                    " get_colp_record_2

*---------------------------------------------------------------------*
*       FORM download_data_colp                                       *
*---------------------------------------------------------------------*
*       Baja archivo con la información en el formato requerido por   *
*       Colpatria                                                   *
*---------------------------------------------------------------------*
FORM download_data_colp.
  DATA: nrecs TYPE i.
  IF NOT tab_colp[] IS INITIAL.
    REFRESH tdw_colp.
    CLEAR   tdw_colp.
    DESCRIBE TABLE tab_colp LINES nrecs.
    wa_colp1-numrecs = nrecs + 2.
    wa_colp3-numrecs = nrecs + 2.
    INSERT wa_colp1 INTO tdw_colp INDEX 1.
    INSERT LINES OF tab_colp INTO tdw_colp INDEX 2.
    APPEND wa_colp3 TO tdw_colp.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
        col_select    = 'X'
      TABLES
        data_tab      = tdw_colp
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.
    MESSAGE i398 WITH text-m01 filename.
  ELSE.
    MESSAGE i208 WITH text-m02.
  ENDIF.
ENDFORM.                    " download_data_colp

*---------------------------------------------------------------------*
*       FORM format_wrbtr_4                                           *
*---------------------------------------------------------------------*
*       Da formato al importe según requerimientos del banco          *
*---------------------------------------------------------------------*
*  -->  PRWBTR : Importe en formato tipo P                            *
*  -->  NRWBTR : Importe en formato tipo N                            *
*---------------------------------------------------------------------*
FORM format_wrbtr_4 USING prwbtr
                          nrwbtr.
  DATA: srwbtr(15).
  WRITE: prwbtr TO srwbtr CURRENCY 'COP'
                          NO-SIGN
                          DECIMALS 2.
  TRANSLATE srwbtr USING ', . '.
  CONDENSE srwbtr NO-GAPS.
  nrwbtr = srwbtr.
ENDFORM.                    " format_wrbtr_4
