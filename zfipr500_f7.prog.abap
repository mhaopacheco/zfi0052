*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F7
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  GET_BSAN_RECORD_1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_bsan_record_1 .
  DATA:   wa_bansant LIKE LINE OF tab_bansant,  "Area de trabajo banco de satander
          w_stcdt  TYPE j_1atoid,               "Determinar tipo documento
          mssge(60),
          w_regup TYPE regup,
          validacion(1) TYPE c VALUE 0,
          prq_rcc(15).
  CLEAR: tab_bansant.
  REFRESH: tab_bansant.
  CLEAR: lfbk,
         mssge.
*Verificar valides identificacion
  IF valiselsan NE space.
    validacion = 1.
  ENDIF.
  LOOP AT t_reguh.
    CLEAR:  wa_bansant, prq_rcc, w_regup.
    PERFORM get_stcd1 USING t_reguh-zstc1
                     CHANGING wa_bansant-stcd1
                              w_stcdt.
    wa_bansant-koinh = t_reguh-znme1.
    wa_bansant-bankn = t_reguh-zbnkn.
    PERFORM format_wrbtr_7 USING t_reguh-rwbtr wa_bansant-rwbtr.
    wa_bansant-dec_rwbtr   = k_dec_bsan.
* Obtener las posiciones de documentos pagos.
    SELECT SINGLE * INTO w_regup FROM regup
        WHERE laufd = t_reguh-laufd AND
              laufi = t_reguh-laufi AND
              xvorl = t_reguh-xvorl AND
              zbukr = t_reguh-zbukr AND
              lifnr = t_reguh-lifnr AND
              kunnr = t_reguh-kunnr.
    wa_bansant-xblnr = w_regup-xblnr.
    IF t_reguh-zbkon = '01'.
      wa_bansant-bkont = '2'.
    ELSEIF t_reguh-zbkon = '02'.
      wa_bansant-bkont = '1'.
    ENDIF.
*    SELECT SINGLE rccode FROM zbnka_ach
*      INTO prq_rcc
*     WHERE bankl = '01'
*       AND bankt =  t_reguh-zbnkl.
*     tab_bbog-bankl = prq_rcc+0(4).
    wa_bansant-bankl = t_reguh-zbnkl.
***MOD: MQA-MNG    CARVAL CALI
***Si el banco de transferencia es Bancafe se toma codigo ACH ya que cambia
***por banco de transferencia
    wa_bansant-bankl = t_reguh-zbnkl.
    IF wa_bansant-bankl = '05'.
      PERFORM data_bankl USING t_reguh-zbnkl
                               t_reguh-ubnkl
                      CHANGING w_bankl.
      wa_bansant-bankl = w_bankl.
    ENDIF.
    CASE w_stcdt.
      WHEN '31'.  wa_bansant-type_id = '03'.
      WHEN '13'.  wa_bansant-type_id = '01'.
      WHEN '12'.  wa_bansant-type_id = '04'.
      WHEN '22'.  wa_bansant-type_id = '02'.
*      WHEN '41'.  wa_bansant-type_id = '05'.
    ENDCASE.
    wa_bansant-val_id       = validacion.

    wa_bansant-pla_bansan  = '0001'. "k_plaza_bsan.
    PERFORM add_record.
    APPEND wa_bansant TO tab_bansant.
  ENDLOOP.
ENDFORM.                    " GET_BSAN_RECORD_1

*---------------------------------------------------------------------*
*       FORM format_wrbtr_7                                           *
*---------------------------------------------------------------------*
*       Da formato al importe segun requerimientos del banco          *
*---------------------------------------------------------------------*
*  -->  PRWBTR : Importe en formato tipo P                            *
*  -->  NRWBTR : Importe en formato tipo N                            *
*---------------------------------------------------------------------*
FORM format_wrbtr_7 USING prwbtr nrwbtr.
  DATA: srwbtr(13).
  WRITE: prwbtr TO srwbtr CURRENCY 'COP'
                          NO-SIGN
                          DECIMALS 0.
  TRANSLATE srwbtr USING ', . '.
  CONDENSE srwbtr NO-GAPS.
  nrwbtr = srwbtr.
ENDFORM.                    " format_wrbtr_7

*---------------------------------------------------------------------*
*       FORM download_data_bsan                                       *
*---------------------------------------------------------------------*
*       Baja archivo con la informacion en el formato requerido por   *
*       Banco Santander                                               *
*---------------------------------------------------------------------*
FORM download_data_bsan .
  REFRESH tdw_sant.
  CLEAR   tdw_sant.
  IF NOT  tab_bansant[] IS INITIAL.
*    INSERT tab_bansant INTO tdw_sant INDEX 1.
    INSERT LINES OF tab_bansant INTO tdw_sant INDEX 1.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
*        filetype      = 'TXT'
        col_select    = 'X'
      TABLES
        data_tab      = tdw_sant
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.
    PERFORM lock_f110.
    MESSAGE i398(ztr_tr) WITH text-m01 filename.
  ELSE.
    MESSAGE i208(ztr_tr) WITH text-m02.
  ENDIF.
ENDFORM.                    " DOWNLOAD_DATA_BSAN
