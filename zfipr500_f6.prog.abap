*&---------------------------------------------------------------------*
*&  Include           ZTR_TRANF_F6
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------*
*       FORM get_daviv_record_1                                       *
*---------------------------------------------------------------------*
*       Registro tipo 1 para Davivienda                               *
*---------------------------------------------------------------------*
FORM get_daviv_record_1.
  DATA:  wa_namebks(16).
  CLEAR: wa_daviv.
  wa_daviv-type_rec = 'RC'.
  PERFORM bukrs_data USING bukrs space
                     CHANGING wa_namebks
                              wa_daviv-nit.
*  wa_daviv-bankn    = t_t012k-bankn.
  wa_daviv-cod_serv = format(4).
*  wa_daviv-cod_serv = 'PROV'.
  wa_daviv-cod_sser = '0000'.
  wa_daviv-cod_bank = '000051'.
  wa_daviv-fec_proc =  t_reguh-zaldt.
  wa_daviv-cod_oper = 0.
  wa_daviv-cod_npro = '9999'.
  wa_daviv-fec_gene = '00000000'.
  wa_daviv-hora_gen = '000000'.
  wa_daviv-ind_insc = '00'.
* Tipo de identificaciÃ³n (Pendiente ???? Aclarar ????)
  wa_daviv-type_id = '01'.
  wa_daviv-num_clie = '000000000000'.
  wa_daviv-ofi_reca = '0000'.
  wa_daviv-fill999  = 0.
  wa_daviv-sum_vals = 0.
  wa_daviv-bankn    = t_reguh-ubknt+4.
  CASE t_reguh-ubkon.
    WHEN 'CC' OR '01'.
      wa_daviv-type_cta = 'CC'.
    WHEN 'CA' OR '02'.
      wa_daviv-type_cta = 'CA'.
  ENDCASE.
ENDFORM.                    " get_daviv_record_1

*---------------------------------------------------------------------*
*       FORM get_daviv_record_2                                       *
*---------------------------------------------------------------------*
*       Registro tipo 2 para el Banco Davivienda                      *
*---------------------------------------------------------------------*
FORM get_daviv_record_2.
* SelecciÃ³n de pagos para:
* 1. Fecha dada,
* 2. VÃ­a de pago: Transferencias bancarias,
* 3. Registros ejecutados (no propuestas), e
* 4. Importes (en moneda local) distintos de 0.
  DATA:   "wa_bkont TYPE lfbk-bkont,
*          wa_name1 TYPE lfa1-name1,
*          wa_stkzn TYPE lfa1-stcdt,
*          wa_bankn TYPE lfbk-bankn,
*          wa_bankl TYPE lfbk-bankl,
*          wa_bvtyp TYPE lfbk-bvtyp,
          wa_fax TYPE adrc-fax_number,
          bank_code(3) TYPE n,
          mssge(60),
          w_zstc1  TYPE lifnr,
          w_stcdt  TYPE j_1atoid.
  CLEAR: tab_daviv.
  REFRESH: tab_daviv.
* Maestro de bancos, para obtener cÃ³digo ACH
  DATA: t_bnka TYPE STANDARD TABLE OF bnka WITH HEADER LINE.
  SELECT * INTO TABLE t_bnka FROM bnka.
  CLEAR: lfbk,
         mssge.
  LOOP AT t_reguh.
    tab_daviv-type_rec = 'TR'.
    PERFORM get_stcd1 USING t_reguh-zstc1
                   CHANGING tab_daviv-stcd1
                            w_stcdt.
    CASE w_stcdt.
      WHEN '31'.  tab_daviv-type_id = '01'.
      WHEN '13'.  tab_daviv-type_id = '02'.
      WHEN '12'.  tab_daviv-type_id = '03'.
      WHEN '22'.  tab_daviv-type_id = '04'.
      WHEN '41'.  tab_daviv-type_id = '05'.
    ENDCASE.
*    tab_daviv-koinh = t_reguh-znme1.
*    PERFORM data_bankl USING t_reguh-zbnkl
*                    CHANGING tab_daviv-bankl.
*    READ TABLE t_bnka WITH KEY banks = 'CO' bankl = t_reguh-zbnkl.
*    IF sy-subrc = 0.
*      tab_daviv-bankl = t_bnka-rccode(9).
*    ENDIF.
*    tab_daviv-cod_bank = '000051'.
    tab_daviv-bankn    = t_reguh-zbnkn.
    SELECT SINGLE rccode INTO tab_daviv-cod_bank
          FROM zbnka_ach
        WHERE
          bankt = t_reguh-zbnkl AND
          bankl = t_reguh-ubnkl.
*    IF sy-subrc = 0.
*
*    ENDIF.
    CASE t_reguh-zbkon.
      WHEN 'CC' OR '01'.
        tab_daviv-type_cta = 'CC'.
      WHEN 'CA' OR '02'.
        tab_daviv-type_cta = 'CA'.
    ENDCASE.
    PERFORM add_record.
    PERFORM format_wrbtr_6 USING t_reguh-waers t_reguh-rwbtr
    tab_daviv-rwbtr.
    tab_daviv-talon    = 0.
    tab_daviv-valid_tr = '1'.
    tab_daviv-res_proc = '9999'.
    tab_daviv-msg_rta  = 0.                                 "(40)
    tab_daviv-val_acum = 0.                                 "(18)
    tab_daviv-fec_apli = '00000000'.
    tab_daviv-ofi_reca = '0000'.
    tab_daviv-motivo   = '0000'.
    tab_daviv-fill999  = '0000000'.
    APPEND tab_daviv.
  ENDLOOP.
* NÃºmero de registros en el detalle
  DESCRIBE TABLE tab_daviv LINES wa_daviv-sum_regs.
  wa_daviv-sum_regs = wa_daviv-sum_regs.
* Importe total en el detalle
  LOOP AT tab_daviv.
    wa_daviv-sum_vals = wa_daviv-sum_vals + tab_daviv-rwbtr.
  ENDLOOP.
ENDFORM.                    " get_daviv_record_2

*---------------------------------------------------------------------*
*       FORM download_data_daviv                                      *
*---------------------------------------------------------------------*
*       Baja archivo con la informaciÃ³n en el formato requerido por   *
*       Davivienda                                                    *
*---------------------------------------------------------------------*
FORM download_data_daviv.
  REFRESH tdw_daviv.
  CLEAR   tdw_daviv.
  IF NOT tab_daviv[] IS INITIAL.
    INSERT wa_daviv  INTO tdw_daviv INDEX 1.
    INSERT lines of tab_daviv INTO tdw_daviv INDEX 2.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
*        filetype      = 'TXT'
        col_select    = 'X'
      TABLES
        data_tab      = tdw_daviv
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.
    PERFORM lock_f110.
    MESSAGE i398(ZTR_TR) WITH text-m01 filename.
  ELSE.
    MESSAGE i208(ZTR_TR) WITH text-m02.
  ENDIF.
ENDFORM.                    " download_data_daviv

*---------------------------------------------------------------------*
*       FORM format_wrbtr_6                                           *
*---------------------------------------------------------------------*
*       Da formato al importe segÃºn requerimientos del banco          *
*---------------------------------------------------------------------*
*  -->  PRWBTR : Importe en formato tipo P                            *
*  -->  NRWBTR : Importe en formato tipo N                            *
*---------------------------------------------------------------------*
FORM format_wrbtr_6 USING pwaers
                          prwbtr
                          nrwbtr.
  DATA: srwbtr(10),
        wa_wrbtr TYPE wrbtr.
  wa_wrbtr = prwbtr.
  WRITE: wa_wrbtr TO srwbtr CURRENCY pwaers
                          NO-SIGN
                          DECIMALS 0.
  TRANSLATE srwbtr USING ', . '.
  CONDENSE srwbtr NO-GAPS.
  nrwbtr = srwbtr.
ENDFORM.                    " format_wrbtr_6

*---------------------------------------------------------------------*
*       FORM get_bankl                                                *
*---------------------------------------------------------------------*
*       Obtiene los cÃ³digo de los bancos                              *
*---------------------------------------------------------------------*
*  -->  P_BANKL : CÃ³digo del banco en SAP (maestro de bancos)         *
*  -->  T_BANKL : CÃ³digo externo (lista de bancos)                    *
*---------------------------------------------------------------------*
*FORM get_bankl USING p_bankl
*                     t_bankl
*                     p_kont
*                     t_office.
*  CASE p_bankl.
** Bancolombia
*    WHEN '003' OR '007' OR '07' OR 'BA0171' OR 'BA2112'.
*      t_bankl = 005600078.
** Conavi
*    WHEN '55' OR '055' OR 'VI2041' OR 'VI3062'.
*      t_bankl = 0570110.
*      IF NOT p_kont IS INITIAL.
*        t_office = p_kont(4).
*      ENDIF.
** Citibank
*    WHEN '009'.
*      t_bankl = 005600094.
** Davivienda
*    WHEN '051'.
*      t_bankl = 005895142.
** Colpatria
*    WHEN '019' OR 'CO0012' OR 'CO0171'.
*      t_bankl = 005600191.
** Santander
*    WHEN '006'.
*      t_bankl = 005600065.
** Banco CrÃ©dito
*    WHEN '014'.
*      t_bankl = 005600146.
** Sudameris
*    WHEN '012' OR 'SU9007'.
*      t_bankl = 005600120.
** Banco de Occidente
*    WHEN '023' OR 'OC0234'.
*      t_bankl = 005600230.
** Banco UniÃ³n Colombiano
*    WHEN 'BU5991'.
*      t_bankl = 005600227.
** Banco Popular
*    WHEN '002'.
*      t_bankl = 005600023.
** Interbanco
*    WHEN 'IN0000' OR 'IN0001'.
*      t_bankl = 005600353.
** Tequendama
*    WHEN 'TE0007'.
*      t_bankl = 005600298.
** ABN AMRO
*    WHEN '008'.
*      t_bankl = 005600081.
** Banco de BogotÃ¡
*    WHEN '001' OR 'BO0093' OR 'BO093'.
*      t_bankl = 005600010.
** Banco Cafetero
*    WHEN 'CF1001'.
*      t_bankl = 005600052.
** Banco Ganadero
*    WHEN '013'.
*      t_bankl = 005600133.
*  ENDCASE.
*ENDFORM.                    " get_bankl
