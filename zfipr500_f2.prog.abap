*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F2
*&---------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       FORM get_bcaf_record                                          *
*---------------------------------------------------------------------*
*       Registros para el Bancafé                                     *
*---------------------------------------------------------------------*
FORM get_bcaf_record.
* Selección de pagos para:
* 1. Fecha dada,
* 2. Vía de pago: Transferencias bancarias,
* 3. Registros ejecutados (no propuestas), e
* 4. Importes (en moneda local) distintos de 0.

*  SELECT SINGLE bankn
*    INTO bankn
*    FROM t012k
*    WHERE bukrs = bukrs
*      AND hbkid = k_bcaf
*      AND hktid = hktid.
  CLEAR: tab_bcaf.
  REFRESH: tab_bcaf.
*  PERFORM get_records.
  CLEAR: lfbk.
  LOOP AT t_reguh.
* Selección datos bancarios del proveedor en el registro de pagos
    SELECT SINGLE *
      FROM lfbk
      WHERE lifnr = reguh-lifnr.
    CHECK sy-subrc = 0.
    tab_bcaf-stcd1 = reguh-stcd1.
    tab_bcaf-type_id = k_idbcaf.
    tab_bcaf-bankn = lfbk-bankn(17).
    CASE lfbk-bkont.
      WHEN 'CC'. " Corriente
        tab_bcaf-bkont = 0.
      WHEN 'CA'. " Ahorros
        tab_bcaf-bkont = 1.
    ENDCASE.
    tab_bcaf-koinh = lfbk-koinh(22).
    TRANSLATE tab_bcaf-koinh USING 'ñnÑN'.
    PERFORM add_record.
    PERFORM format_wrbtr_2 USING reguh-rwbtr tab_bcaf-rwbtr.
    tab_bcaf-datum = addat.
    tab_bcaf-day = addat+6(2).
    CONCATENATE text-p00 text-p01
           INTO tab_bcaf-xblnr SEPARATED BY space.
    tab_bcaf-filler = space.
    APPEND tab_bcaf.
  ENDLOOP.
ENDFORM.                    " get_bcaf_record

*---------------------------------------------------------------------*
*       FORM format_wrbtr_2                                           *
*---------------------------------------------------------------------*
*       Da formato al importe según requerimientos del banco          *
*       13.2 XXXXXXXXXXXXX.DD                                         *
*---------------------------------------------------------------------*
*  -->  PRWBTR : Importe en formato tipo P                            *
*  -->  SRWBTR : Importe en formato tipo C                            *
*---------------------------------------------------------------------*
FORM format_wrbtr_2 USING prwbtr
                          srwbtr.
  DATA: nrwbtr(16) TYPE n.
  WRITE: prwbtr TO srwbtr CURRENCY 'COP'
                          NO-SIGN
                          DECIMALS 2.
  TRANSLATE srwbtr USING ', . '.
  CONDENSE srwbtr NO-GAPS.
  nrwbtr = srwbtr.
  CONCATENATE nrwbtr+1(13)
              '.'
              nrwbtr+14(2)
         INTO srwbtr.
ENDFORM.                    " format_wrbtr_2


*---------------------------------------------------------------------*
*       FORM download_data_bcaf                                       *
*---------------------------------------------------------------------*
*       Baja archivo con la información en el formato requerido por   *
*       Bancafé                                                       *
*---------------------------------------------------------------------*
FORM download_data_bcaf.
  IF NOT tab_bcaf[] IS INITIAL.
    REFRESH tdw_bcaf.
    CLEAR   tdw_bcaf.
    INSERT LINES OF tab_bcaf INTO tdw_bcaf INDEX 1.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
        col_select    = 'X'
      TABLES
        data_tab      = tdw_bcaf
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.
    MESSAGE i398 WITH text-m01 filename.
  ELSE.
    MESSAGE i208 WITH text-m02.
  ENDIF.
ENDFORM.                    " download_data_bcaf
