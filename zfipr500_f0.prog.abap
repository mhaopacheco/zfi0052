*&---------------------------------------------------------------------*
*&  Include           ZTR_TRANF_F0
*&---------------------------------------------------------------------*


*---------------------------------------------------------------------*
*       FORM init_pbo_1010                                            *
*---------------------------------------------------------------------*
*       Define valores para las estructuras iniciales                 *
*---------------------------------------------------------------------*
FORM get_bank.
  CHECK vrm_value IS INITIAL.
* Selección de los parÃ¡metros de los bancos para transferencia
*bancaria
* (sÃ³lo bancos que estÃ¡n activos)
* Estas cuentas son activadas en la tabla ZBNKA_TRN
  SELECT DISTINCT p~bukrs d~banka p~hbkid
    INTO TABLE t_bank
    FROM t012 AS p JOIN bnka AS d
         ON p~bankl = d~bankl
    WHERE p~bukrs = bukrs AND
          p~hbkid IN ( SELECT hbkid FROM zbnka_trn WHERE status = 'X' ).
  SORT t_bank.
  LOOP AT t_bank.
    vrm_val-key = t_bank-hbkid.
    CONCATENATE t_bank-banka t_bank-hbkid INTO vrm_val-text
                SEPARATED BY space.
    APPEND vrm_val TO vrm_value.
  ENDLOOP.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'TBANK'
      values = vrm_value.
  CHECK NOT t_bank[] IS INITIAL.
  READ TABLE t_bank INDEX 1.
  tbank = t_bank-hbkid.
  PERFORM set_value_bnka.
*  laufd = sy-datum.
  addat = sy-datum.
*  ck_print = space.
  ck_down = space.
  PERFORM set_name_init_file.
ENDFORM.                    " init_pbo_1010

*---------------------------------------------------------------------*
*       FORM set_value_bnka                                           *
*---------------------------------------------------------------------*
*       Define el valor para el acrÃ³nimo del banco seleccionado       *
*---------------------------------------------------------------------*
FORM set_value_bnka.
  CHECK tbank NE space.
  READ TABLE t_bank WITH KEY hbkid = tbank.
  hbkid = t_bank-hbkid.
  PERFORM set_value_hktid.
  PERFORM set_value_format.
ENDFORM.                    " set_value_bnka


*---------------------------------------------------------------------*
*       FORM set_value_hktid                                           *
*---------------------------------------------------------------------*
*       Define el valor para el acrÃ³nimo del banco seleccionado       *
*---------------------------------------------------------------------*
FORM set_value_hktid.
  CLEAR account_value.
  REFRESH account_value.
  SELECT t~bukrs b~hktid t~bankn t~bkont b~fname
    INTO TABLE t_t012k
    FROM zbnka_trn AS b INNER JOIN t012k AS t
    ON b~bukrs = t~bukrs AND b~hbkid = t~hbkid
    WHERE t~hbkid = hbkid AND
          b~bukrs = bukrs.
  LOOP AT t_t012k.
    CLEAR account_val.
    CONCATENATE t_t012k-bukrs t_t012k-hktid t_t012k-bkont t_t012k-bankn
                   INTO account_val-key.
    account_val-text = t_t012k-bankn.
    APPEND account_val TO account_value.
  ENDLOOP.
  CALL FUNCTION 'VRM_DELETE_VALUES'
    EXPORTING
      id           = 'HKTID'
    EXCEPTIONS
      id_not_found = 1
      OTHERS       = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'HKTID'
      values = account_value.
ENDFORM.                    " set_value_hktid

*&--------------------------------------------------------------------*
*&      Form  set_value_format
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM set_value_format.
  DATA: t_operation TYPE STANDARD TABLE OF zbnka_opr WITH HEADER LINE.
  REFRESH vrm_it_format.
  SELECT *
    INTO TABLE t_operation
    FROM zbnka_opr
    WHERE hbkid = hbkid AND
          bukrs = bukrs.
  IF sy-subrc = 4.
    MESSAGE w010(zfitb) WITH hbkid 'ZBNKA_OPR'.
  ENDIF.
  LOOP AT t_operation.
    vrm_format-key = t_operation-codeo.
    vrm_format-text = t_operation-nameo.
    APPEND vrm_format TO vrm_it_format.
  ENDLOOP.
  REFRESH t_operation.
  FREE t_operation.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'FORMAT'
      values = vrm_it_format.
ENDFORM.                    "set_value_format

*---------------------------------------------------------------------*
*       FORM set_param_hktid                                           *
*---------------------------------------------------------------------*
*       Define el valor para el acrÃ³nimo del banco seleccionado       *
*---------------------------------------------------------------------*
FORM set_param_hktid.
  WRITE hktid(4)     TO wa_t012k-bukrs.
  WRITE hktid+4(5)   TO wa_t012k-hktid.
  WRITE hktid+9(2)   TO wa_t012k-bkont.
  WRITE hktid+11(18) TO wa_t012k-bankn.
ENDFORM.                    " set_param_hktid
.
*---------------------------------------------------------------------*
*       FORM command_1010                                             *
*---------------------------------------------------------------------*
*       Manejo del comando del usuario                                *
*---------------------------------------------------------------------*
FORM command_1010.
  ok_code = sy-ucomm.
  CASE sy-ucomm.
    WHEN 'EXEC'.
      PERFORM more_data.
      IF f110v-xmore = 'X' OR sy-ucomm = 'OK_2015'.
*        PERFORM check_lock.
        PERFORM exec_transfer_bank.
      ENDIF.
      SET SCREEN 1010.
    WHEN 'EXIT' OR
         'BACK'.
      LEAVE PROGRAM.
    WHEN 'TBNK'.
      PERFORM set_value_bnka.
      PERFORM set_name_init_file.
      SET SCREEN 1010.
    WHEN 'HKTI'.
      PERFORM set_param_hktid.
      SET SCREEN 1010.
    WHEN 'BNK'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action    = 'S'
          view_name = 'ZBNKA_TRN'.
      SET SCREEN 1010.
    WHEN 'OPR'.
      PERFORM select_bank.
      SET SCREEN 1010.
    WHEN 'ACH'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action    = 'S'
          view_name = 'ZV_BNKA_ACH'.
      SET SCREEN 1010.
    WHEN 'OK'.
      SET SCREEN 1010.
  ENDCASE.
  CLEAR ok_code.
ENDFORM.                    " command_1010


*---------------------------------------------------------------------*
*       FORM set_name_init_file                                       *
*---------------------------------------------------------------------*
*       Retorna el valor por defecto para el fichero                  *
*---------------------------------------------------------------------*
FORM set_name_init_file.
  DATA: tfile(12).
  CLEAR vrm_it_format.
  tfile = text-f00.
  CONCATENATE  tfile(8) hbkid '_' f110v-laufd '_'
               sy-uzeit(4) tfile+8(4) '.TXT'
         INTO  w_filename.
  CONCATENATE 'C:/TEMP/' w_filename
         INTO  filename.
ENDFORM.                    " set_name_init_file


*---------------------------------------------------------------------*
*       FORM get_filename                                             *
*---------------------------------------------------------------------*
*       Obtiene el nombre del archivo para bajar los datos            *
*---------------------------------------------------------------------*
FORM get_filename.
* Tabla para lista de ficheros seleccionados
  DATA: lst_file TYPE file_table OCCURS 0,
        rc TYPE i,
        txt_g00 TYPE string.
  txt_g00 = text-g00.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = txt_g00
      default_extension       = '.txt'
    CHANGING
      file_table              = lst_file
      rc                      = rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      OTHERS                  = 5.
  CHECK sy-subrc = 0.
  READ TABLE lst_file INDEX 1 INTO filename.
ENDFORM.                    " get_filename

*&---------------------------------------------------------------------*
*&      Form  get_dirname
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_dirname.
* Tabla para lista de ficheros seleccionados
  DATA: lst_file TYPE file_table OCCURS 0,
        rc TYPE i,
        txt_g00 TYPE string,
        dirname TYPE string,
        wa_len  TYPE i.
  txt_g00 = text-g00.
  CALL METHOD cl_gui_frontend_services=>directory_browse
    EXPORTING
      window_title         = txt_g00
*     INITIAL_FOLDER       =
    CHANGING
      selected_folder      = dirname
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  wa_len = strlen( dirname ).
  CONCATENATE dirname(wa_len) '\' w_filename INTO filename.
ENDFORM.                    " get_filename


*---------------------------------------------------------------------*
*       FORM exec_transfer_bank                                       *
*---------------------------------------------------------------------*
*       Ejecuta cada transferencia dependiendo la entidad             *
*---------------------------------------------------------------------*
FORM exec_transfer_bank .

  DATA: wa_form TYPE zbnka_opr-form ,
        wa_fname LIKE zbnka_trn-fname .

** Variables impresiÃ³n
  DATA: lf_fm_name            TYPE rs38l_fnam.
  DATA: ls_control_param      TYPE ssfctrlop.
  DATA: ls_composer_param     TYPE ssfcompop.
  DATA: ls_recipient          TYPE swotobjid.
  DATA: ls_sender             TYPE swotobjid.
  DATA: lf_formname           TYPE tdsfname.

* Inicializar estructura de control de totales en propuesta
  CLEAR resume .
  SELECT SINGLE texto form
    INTO (wa_text, wa_form)
    FROM zbnka_opr
   WHERE bukrs = bukrs AND
         hbkid = hbkid AND
         codeo = format .

  IF f110v-xmore = 'X'.
* Elegir el mensajero que reclama los cheques
    PERFORM get_messenger .
    SELECT SINGLE fname INTO lf_formname
      FROM zbnka_trn
      WHERE bukrs = bukrs AND
            hbkid = hbkid AND
            hktid = hktid.
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = lf_formname
      IMPORTING
        fm_name            = lf_fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    IF sy-subrc = 0.
      CALL FUNCTION lf_fm_name
        EXPORTING
          user_settings    = 'X'
          f110v            = f110v
        EXCEPTIONS
          formatting_error = 1
          internal_error   = 2
          send_error       = 3
          user_canceled    = 4
          OTHERS           = 5.
    ENDIF.
  ELSE.
    break abap1_mqa.
    CASE wa_form .
****MQA CUERPO PRINCIPAL DEL PROGRAMA
* BancafÃ© : F2
*      WHEN 'BCAF'.
*        PERFORM get_bcaf_record.
*        PERFORM show_resume.
*        CHECK ck_down IS INITIAL.
*        PERFORM download_data_bcaf.
* Banco de BogotÃ¡ : F1
      WHEN 'BBOG'.
        PERFORM get_bbog_record_1.
        CHECK NOT wa_bog IS INITIAL.
        PERFORM get_bbog_record_2.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_bbog.
* Bancolombia : F3
      WHEN 'BCOL'.

        PERFORM get_bcol_record_1.
        CHECK NOT wa_bcol IS INITIAL.
        PERFORM get_bcol_record_2.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_bcol.
      WHEN 'CONA1'.
        PERFORM get_conav_record.
        CHECK NOT wa_cnav IS INITIAL.
        CASE format.
          WHEN 'E'.
            PERFORM get_cnav_data.
          WHEN 'P'.
            PERFORM get_cnav_data2.
        ENDCASE.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_cnav.
* Davivienda
      WHEN 'DVIV'.
        PERFORM get_daviv_record_1.
        CHECK NOT wa_daviv IS INITIAL.
        PERFORM get_daviv_record_2.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_daviv.
* Tequendama : F5
*      WHEN 'TEQU'.
*        BREAK-POINT.
*Banco Santander
      WHEN 'BSAN'.
        PERFORM get_bsan_record_1.
        DESCRIBE TABLE tab_bansant.
        CHECK NOT sy-tfill IS INITIAL.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_bsan.
      WHEN 'BOCC'.
        PERFORM get_booc_record_1.
        CHECK NOT wa_occi IS INITIAL.
        PERFORM get_bocc_record_2.
        PERFORM get_bocc_record_3.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_booc.
*{   INSERT         AMDK902242                                        1

*Colmena
      WHEN 'COLM'.
        PERFORM generar_colmena.
        DESCRIBE TABLE it_linea.
        CHECK NOT sy-tfill IS INITIAL.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_colmena.

*}   INSERT
      WHEN 'BBVA'.
**       Unico registro por proveedor
*        PERFORM get_bbva_record .
*        CHECK NOT tab_bbva IS INITIAL.
**       Resultados
*        PERFORM show_resume.
*        CHECK ck_down IS INITIAL.
**       Generar archivo plano para banco Santander
*        PERFORM download_data_bbva .
* Avvillas
      WHEN 'BAVV' .
**       Registro de encabezado
*        PERFORM get_bavv_record_1 .
*        CHECK NOT wa_bavv IS INITIAL .
**       Registro de pagos
*        PERFORM get_bavv_record_2 .
**       Registro de totales
*        PERFORM get_bavv_record_3 .
**       Resultados
*        PERFORM show_resume .
*        CHECK ck_down IS INITIAL.
**       Generar archivo plano para banco Occidente
*        PERFORM download_data_bavv.
* Sudameris
      WHEN 'BSUD'.
**       Unico registro por proveedor
*        PERFORM get_bsud_record .
*        CHECK NOT tab_bsud IS INITIAL.
**       Resultados
*        PERFORM show_resume.
*        CHECK ck_down IS INITIAL.
**       Generar archivo plano para banco Santander
*        PERFORM download_data_bsud .
* Colpatria : F4
      WHEN 'COLP'.
        PERFORM get_colp_record_1.
        CHECK NOT wa_colp1 IS INITIAL.
        PERFORM get_colp_record_2.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_colp.
*Banco de Helm
      WHEN 'BHEL'.
        PERFORM get_bcre_record_1.
        DESCRIBE TABLE tab_bcre.
        CHECK NOT sy-tfill IS INITIAL.
        PERFORM show_resume.
        CHECK ck_down IS INITIAL.
        PERFORM download_data_bcre.
*CR
      WHEN 'CRER'.
*        PERFORM get_crer_record_1.
*        DESCRIBE TABLE it_crer.
*        CHECK NOT sy-tfill IS INITIAL.
*        PERFORM show_resume.
*        CHECK ck_down IS INITIAL.
*        PERFORM download_data_crer.

      WHEN 'CITI'. "Citibank
*        PERFORM get_bcit_record_1.
*        DESCRIBE TABLE it_bciti.
*        CHECK NOT sy-tfill IS INITIAL.
*        PERFORM show_resume.
*        CHECK ck_down IS INITIAL.
*        PERFORM download_data_bcit.

        " **********************************************************************
        " BEGINOF : MPACHECO : 15.Feb.2012 : Inclusión Banco Bogota Miami
      WHEN 'MIA0'. " Banco Bogota Miami
**        PERFORM get_bbog_record_1_12 . " Workarea Cabecera
**        CHECK NOT wa_bog IS INITIAL . "
*        PERFORM get_mia01_record_2 . " Tabla Pagos
*        PERFORM show_resume .
*        CHECK ck_down IS INITIAL.
*        PERFORM download_data_mia01 .
*        " ENDOF : MPACHECO : 15.Feb.2012 : Inclusión Banco Bogota Miami
*        " **********************************************************************
    ENDCASE.

  ENDIF.
*  if not ck_print is initial.
*    perform print_report.
*  endif.
ENDFORM.                    " exec_transfer_bank

*&--------------------------------------------------------------------*
*&      Form  bukrs_name
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_BUKRS    text
*      -->P_NAME     text
*---------------------------------------------------------------------*
FORM bukrs_data USING p_bukrs p_split CHANGING p_name p_nit .

  DATA: wa_nit TYPE t001z-paval,
        fill.
  SELECT SINGLE butxt INTO p_name FROM t001 WHERE bukrs = p_bukrs .
  SELECT SINGLE paval INTO wa_nit FROM t001z WHERE bukrs = p_bukrs  AND
                                                   party = 'CO_NIT' .


  REPLACE ALL OCCURRENCES OF  '.'  IN wa_nit WITH ''.
  IF wa_nit CN '0123456789- ' .
    MESSAGE e017(zfitb) WITH wa_nit.
*   El nit de la empresa contiene cartacteres no válidos: &
    EXIT.
  ENDIF.
  IF p_split = 'X'.
    SPLIT wa_nit AT '-' INTO wa_nit fill.
  ELSE.
    REPLACE '-' IN wa_nit WITH space.
  ENDIF.
  UNPACK wa_nit TO p_nit.

ENDFORM.                    "bukrs_name

*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND_1020
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_command_1020 .
  CASE sy-ucomm.
    WHEN 'EXIT' OR
         'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.                    " USER_COMMAND_1020

*&--------------------------------------------------------------------*
*&      Form  get_records
*&--------------------------------------------------------------------*
*   Obtener la los pagos realizados por medio de transferencia
*   electrÃ³nica
*---------------------------------------------------------------------*
FORM get_records.
  DATA: t_bkpf TYPE STANDARD TABLE OF bkpf WITH HEADER LINE.
  REFRESH t_reguh.
  IF f110v-xmore = 'X'.
    SELECT * INTO TABLE t_reguh
      FROM reguh
      WHERE laufd = f110v-laufd
        AND laufi = f110v-laufi
        AND xvorl = space
        AND rbetr NE 0.
  ELSE.
    DATA: w_zlsch TYPE  t042z-zlsch.
    SELECT SINGLE zlsch INTO w_zlsch FROM t042z WHERE land1 = 'CO'.
    SELECT * INTO TABLE t_reguh
      FROM reguh
      WHERE laufd = f110v-laufd
        AND laufi = f110v-laufi
*        AND rzawe IN ( SELECT zlsch FROM t042z WHERE land1 = 'CO' )
        AND vblnr NE '          '
        AND xvorl = ' '      "space
        AND rbetr NE 0
        AND rzawe EQ 'T'.  " SOLO T TRANSFERENCIAS BANCARIAS, SE EXCLUYEN LOS TIPO C CHEQUES MODIFICADO POR MQA 27-08-2010 CCASTILLO
*    SELECT *
*      INTO TABLE t_reguh
*      FROM reguh
*      WHERE laufd = f110v-laufd
*        AND laufi = f110v-laufi
*        AND rzawe IN ( SELECT zlsch FROM t042z WHERE xbkkt = 'X' AND
*                             land1 = 'CO' )
*        AND xvorl = space
*        AND rbetr NE 0.
  ENDIF.
* Consultar si el documento estÃ¡ anulado
  SELECT * FROM bkpf INTO TABLE t_bkpf
  FOR ALL ENTRIES IN t_reguh
  WHERE bukrs = t_reguh-zbukr AND
        belnr = t_reguh-vblnr AND
        gjahr = t_reguh-zaldt(4) AND
        xreversal = 1.
* Retirar de la propuesta las posiciones de documentos anulados
  LOOP AT t_bkpf.
    DELETE t_reguh WHERE vblnr = t_bkpf-belnr AND
                         zbukr = t_bkpf-bukrs.
  ENDLOOP.
  IF t_reguh[] IS INITIAL.
    MESSAGE e029(zfitb).
  ENDIF.
ENDFORM.                    "get_records

*&--------------------------------------------------------------------*
*&      Form  data_bankl
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_ZBNKL    text
*      -->P_BANKL    text
*---------------------------------------------------------------------*
FORM data_bankl USING p_zbnkl TYPE reguh-zbnkl
                      p_ubnkl TYPE reguh-ubnkl
             CHANGING p_bankl.
*  DATA: fill TYPE string,
*        nbnk(2) TYPE n.
*  SPLIT p_zbnkl AT '-' INTO fill nbnk.
*  UNPACK nbnk TO p_bankl.
  SELECT SINGLE rccode INTO p_bankl
        FROM zbnka_ach
      WHERE
        bankl = p_ubnkl AND
        bankt = p_zbnkl.
  IF sy-subrc <> 0.
"WRM:16.01.13,Ca8.1980,Begin
    MESSAGE w033(zfitb) WITH p_zbnkl.
*    WRITE: /5 'No existe codigo bancario destino para banco : ',
*           p_zbnkl.
*    STOP.
  ENDIF.
ENDFORM.                    "data_bankl

*&--------------------------------------------------------------------*
*&      Form  select_bank
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM select_bank.
  CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
    EXPORTING
      action               = 'S'
      show_selection_popup = 'X'
      view_name            = 'ZBNKA_OPR'.
ENDFORM.                    "select_bank

*&--------------------------------------------------------------------*
*&      Form  MORE_DATA
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM more_data.
*  DATA: t_reguh TYPE STANDARD TABLE OF reguh WITH HEADER LINE.
  REFRESH t_reguh.
  PERFORM get_records.
* validar banco y cuenta unicos.
  READ TABLE t_reguh INDEX 1.
  bukrs = t_reguh-zbukr.
  hbkid = t_reguh-hbkid.
  hktid = t_reguh-hktid.
* Obtener cuenta.
  IF f110v-xmore IS INITIAL.
    PERFORM set_value_format.
    PERFORM set_name_init_file.
    CALL SCREEN 2015 STARTING AT 20 10 ENDING AT 90 15.
  ENDIF.
ENDFORM.                    "MORE_DATA
*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND_2015
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_command_2015 .
  break cposso.
  CASE sy-ucomm.
    WHEN 'NO_2015'.
      LEAVE TO SCREEN 0.
    WHEN 'OK_2015'.
      CHECK NOT format IS INITIAL.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.                    " USER_COMMAND_2015
*&---------------------------------------------------------------------*
*&      Form  get_decimal
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_DECSE  text
*----------------------------------------------------------------------*
FORM get_decimal CHANGING p_decse.
  SELECT SINGLE dcpfm INTO p_decse FROM usr01 WHERE bname = sy-uname.
ENDFORM.                    " get_decimal

*&---------------------------------------------------------------------*
*&      Form  get_stcd1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_REGUH_STCD1  text
*      -->P_WA_STKZN  text
*      <--P_TAB_BCOL_STCD1  text
*      <--P_TAB_BCOL_KOINH  text
*      <--P_=  text
*      <--P_T_REGUH_NAME1  text
*----------------------------------------------------------------------*
FORM get_stcd1  USING    p_stcd1
*                         p_stkzn
                CHANGING o_stcd1
                         o_stcdt.
  DATA: w_len TYPE i,
        w_stkzn TYPE stkzn, "Persona fÃ­sica?
        w_stcdt TYPE j_1atoid.

  SELECT SINGLE stkzn stcdt INTO (w_stkzn, w_stcdt)
    FROM lfa1
    WHERE stcd1 = p_stcd1.
  IF w_stkzn IS INITIAL.
    w_len = strlen( p_stcd1 ) - 1.
    o_stcd1 = p_stcd1(w_len).
  ELSE.
    o_stcd1 = p_stcd1.
  ENDIF.
  o_stcdt = w_stcdt.
ENDFORM.                                                    " get_stcd1

*&--------------------------------------------------------------------*
*&      Form  get_messenger
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM get_messenger.
* Obtener lista de mensajeros
  DATA: h_shlp TYPE shlp_descr_t,
        rc     LIKE sy-subrc,
        return_values LIKE ddshretval OCCURS 0 WITH HEADER LINE,
        d_retval LIKE ddshretval OCCURS 0 WITH HEADER LINE,
        w_interface LIKE LINE OF h_shlp-interface,
        w_intdescr  LIKE h_shlp-intdescr,
        w_seloption TYPE ddshselopt.
* Obtener los valores ingresados por el usuario
  CALL FUNCTION 'F4IF_GET_SHLP_DESCR'
    EXPORTING
      shlpname = 'KREDA'
      shlptype = 'SH'
    IMPORTING
      shlp     = h_shlp.
  w_intdescr = h_shlp-intdescr.
  w_intdescr-dialogtype = 'D'.
  h_shlp-intdescr = w_intdescr.
  READ TABLE h_shlp-interface INTO w_interface
       WITH KEY shlpfield = 'SORTL'.
  w_interface-valfield = 'SORTL'.
  w_interface-value = 'MENSAJERO'.
  MODIFY h_shlp-interface INDEX sy-tabix FROM w_interface.

  READ TABLE h_shlp-interface INTO w_interface
       WITH KEY shlpfield = 'LIFNR'.
  w_interface-valfield = 'LIFNR'.
  MODIFY h_shlp-interface INDEX sy-tabix FROM w_interface.

* Adicionar la condiciÃ³n del comprador
  w_seloption-shlpname = h_shlp-shlpname.
  w_seloption-shlpfield = 'SORTL'.
  w_seloption-sign = 'I'.
  w_seloption-option = 'EQ'.
  w_seloption-low = 'MENSAJERO'.
  APPEND w_seloption TO h_shlp-selopt.

  CALL FUNCTION 'F4IF_START_VALUE_REQUEST'
    EXPORTING
      shlp          = h_shlp
    IMPORTING
      rc            = rc
    TABLES
      return_values = return_values.
* Verificar que haya elegido un valor

  CHECK rc = 0.
  READ TABLE return_values WITH KEY fieldname = 'LIFNR'.
  f110v-vonkk = return_values-fieldval.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = f110v-vonkk
    IMPORTING
      output = f110v-vonkk.

ENDFORM.                    "get_messenger

*&--------------------------------------------------------------------*
*&      Form  check_lock
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM check_lock.
  DATA: w_lock TYPE zf110_lock.
  SELECT SINGLE * INTO w_lock FROM zf110_lock
  WHERE laufd = f110v-laufd AND
        laufi = f110v-laufi.
*bukrs = reguh-zbukr AND

  IF sy-subrc = 0.
    MESSAGE e028(zfitb) WITH w_lock-fname w_lock-uname w_lock-datum.
  ENDIF.
ENDFORM.                    "check_lock

*&--------------------------------------------------------------------*
*&      Form  lock_f110
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM lock_f110.
  DATA: w_lock TYPE zf110_lock.
  w_lock-bukrs = bukrs.
  w_lock-laufd = f110v-laufd.
  w_lock-laufi = f110v-laufi.
  w_lock-datum = addat.
  w_lock-uname = sy-uname.
  w_lock-fname = filename.
  INSERT zf110_lock FROM w_lock.
ENDFORM.                                                    "lock_f110

*&--------------------------------------------------------------------*
*&      Form  add_record
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM add_record.
  resume-nitems = resume-nitems + 1.
  resume-sumite = resume-sumite + t_reguh-rwbtr.
  resume-waers  = t_reguh-waers.
ENDFORM.                    "add_record

*&--------------------------------------------------------------------*
*&      Form  show_resume
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM show_resume.

  DATA: message TYPE string,
        g_respuesta,
        valedit(18).

  WRITE resume-sumite TO valedit CURRENCY resume-waers.

  CONCATENATE text-002 valedit text-003 resume-nitems
         INTO message SEPARATED BY space.
  CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
    EXPORTING
      defaultoption  = 'Y'
      diagnosetext1  = message
      diagnosetext2  = text-004
*     diagnosetext3  =
      textline1      = text-006
      textline2      = text-007
      titel          = text-005
      start_column   = 20
      start_row      = 10
      cancel_display = ' '
    IMPORTING
      answer         = g_respuesta.

  IF g_respuesta <> 'J'.
    ck_down = 'X'.
  ELSE.
    CLEAR ck_down.
  ENDIF.

ENDFORM.                    "add_record
*&---------------------------------------------------------------------*
*&      Form  GET_STCD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_REGUH_ZSTC1  text
*      <--P_WA_CRE_STCD1  text
*----------------------------------------------------------------------*
FORM get_stcd  USING    p_stcd1
*                       p_stkzn
                CHANGING o_stcd1.
  DATA: w_len TYPE i,
        w_stkzn TYPE stkzn, "Persona fÃ­sica?
        w_stcdt TYPE j_1atoid.

  SELECT SINGLE stkzn stcdt INTO (w_stkzn, w_stcdt)
    FROM lfa1
    WHERE stcd1 = p_stcd1.
  IF w_stkzn IS INITIAL.
    w_len = strlen( p_stcd1 ) - 1.
    o_stcd1 = p_stcd1(w_len).
  ELSE.
    o_stcd1 = p_stcd1.
  ENDIF.
  o_stcd1 = w_stcdt.
ENDFORM.                    " GET_STCD

*&---------------------------------------------------------------------*
*&      Form  get_stcd1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_STCD1    text
*      -->P_LIFNR    text
*      -->O_STCD1    text
*      -->O_STCDT    text
*      -->O_FITYP    text
*----------------------------------------------------------------------*
FORM get_stcd2  USING    p_stcd1
                         p_lifnr
*                         p_stkzn
                CHANGING o_stcd1
                         o_stcdt
                         o_fityp.
  DATA: w_len TYPE i,
        w_stkzn TYPE stkzn, "Persona fÃ­sica?
        w_fityp TYPE lfa1-fityp,
        w_stcdt TYPE j_1atoid.
  RANGES: r_lifnresp FOR lfa1-lifnr.

  SELECT SINGLE stkzn stcdt fityp INTO (w_stkzn, w_stcdt, w_fityp)
    FROM lfa1
    WHERE stcd1 = p_stcd1.
  IF w_fityp = 'PJ' OR p_lifnr IN r_lifnresp.
*  IF w_stkzn IS INITIAL.
    w_len = strlen( p_stcd1 ) - 1.
    o_stcd1 = p_stcd1(w_len).
    o_stcdt = '13'.
    o_fityp = w_fityp.
  ELSE.
    o_stcd1 = p_stcd1.
    o_stcdt = w_stcdt.
    o_fityp = w_fityp.
  ENDIF.

ENDFORM.                                                    " get_stcd1
