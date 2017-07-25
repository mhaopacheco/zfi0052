*&---------------------------------------------------------------------*
*&  Include           ZFIPR500_F9
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  generar_colmena
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM generar_colmena.

  DATA: c_infadi(80) TYPE c,
        parte1(40)   TYPE c,
        parte2(40)   TYPE c.

  CLEAR: wa_salida.
  BREAK JLOPEZ.
  PERFORM get_regup.

  LOOP AT T_REGUP.
* Busca el pagador alternativo
  SELECT SINGLE lnrza
    INTO g_lnrza
    FROM lfa1
   WHERE lifnr = T_reguh-lifnr.

* Adiciona la nota explicativa con 80 car.
  CLEAR: c_infadi, parte1, parte2.
  MOVE: 'PAGOS TRANSFERENCIAS                    ' TO c_infadi(40).
  MOVE: '                                       .' TO c_infadi+40(40).

* Mueve los datos constantes del registro
  MOVE: '6' TO wa_salida-idereg,    "valor identificacion del registro
     c_infadi TO wa_salida-infadi,  "informacion adicional
    'V ' TO wa_salida-valide.   "validacion identificacion titular

* Buscar monto transaccion
  PERFORM monto_transaccion.

* Buscar el numero de la cuenta
  PERFORM buscar_cuenta_col.

* Buscar el numero de identificacion del participante
  PERFORM buscar_ident.

  MOVE: wa_salida TO wa_linea.

  APPEND wa_linea  TO it_linea.
ENDLOOP.

resume-nitems = resume-nitems + 1.
  resume-sumite = resume-sumite + t_reguh-rwbtr.
  resume-waers  = t_reguh-waers.
ENDFORM. "generar_colmena


*&---------------------------------------------------------------------*
*&      Form  monto_transaccion
*&---------------------------------------------------------------------*
*     Con 2 decimales, alineado a la derecha y los espacios se llenan
*     con ceros a la izquierda. no deben contener puntos ni comas
*----------------------------------------------------------------------*
FORM monto_transaccion .

  DATA: w_valori(10) TYPE n,
        w_valorf(12) TYPE n.

  WRITE T_regup-wrbtr TO wa_salida-montra
     CURRENCY t_reguh-waers. "parte entera
  MOVE: wa_salida-montra  TO w_valori.  "Importe en moneda local
  w_valorf = w_valori * 100.
  MOVE: w_valorf TO wa_salida-montra.

ENDFORM.                    " monto_transaccion



*&---------------------------------------------------------------------*
*&      Form  buscar_cuenta
*&---------------------------------------------------------------------*
* NUMERO CUENTA:  Alineado a la izquierda y rellaenado con espacios a
* la derecho sin guiones ni letras
* CODIGO BANCO RECEPTOR : codigos del banco de la republica
* IDENTIFICACION DEL PARTICIPANTE: alineado a la izq.completando con
* espacios a la derecha.
*----------------------------------------------------------------------*
FORM buscar_cuenta_col .

  TYPES: BEGIN OF ty_datos,
          koinh TYPE lfbk-koinh,  "Titular de la cuenta
          bkont TYPE lfbk-bkont,  "No.acreedor
          banks TYPE lfbk-banks,  "Clave pais banco
          bankl TYPE lfbk-bankl,  "Codigo banco
          bankn TYPE lfbk-bankn,  "numero cuenta
        END OF ty_datos.

  DATA: wa_datos TYPE ty_datos.

* Busca el pagador alternativo
  IF g_lnrza IS INITIAL.
    SELECT SINGLE koinh bkont banks bankl bankn
      INTO CORRESPONDING FIELDS OF wa_datos
      FROM lfbk
     WHERE lifnr = t_reguh-lifnr.
  ELSE.
    SELECT SINGLE koinh bkont banks bankl bankn
      INTO CORRESPONDING FIELDS OF wa_datos
      FROM lfbk
     WHERE lifnr = g_lnrza.
  ENDIF.

  IF sy-subrc IS INITIAL.

* Busca el codigo de la transaccion
    IF wa_datos-bkont = '01'. "cuenta corriente
      MOVE: '22' TO wa_salida-codtra.
    ELSE.                     "cuenta ahorros
      MOVE: '32' TO wa_salida-codtra.
    ENDIF.

    WRITE wa_datos-bankn TO wa_salida-numcta LEFT-JUSTIFIED.




data: V_COD_BANCOL type ZCOND_BANCOL.


    SELECT SINGLE COD_BANCOL INTO V_COD_BANCOL
    FROM ZFI_VALIDA_BANCO
    WHERE BANKL = wa_datos-bankl.
    wa_salida-codban = V_COD_BANCOL.



    wa_salida-codban = V_COD_BANCOL.


*   Busca la tabla de equivalencias
*    SELECT SINGLE zctaach
*      INTO wa_salida-codban
*      FROM zfi_achcenit
*     WHERE zbankl = wa_datos-bankl.

  ENDIF.

  MOVE: wa_datos-koinh TO wa_salida-nompar.

ENDFORM.                    " buscar_cuenta_col


*&---------------------------------------------------------------------*
*&      Form  buscar_ident
*&---------------------------------------------------------------------*
*      Busca el numero de identificacion del participante sin ceros
*      a la izquierda
*----------------------------------------------------------------------*
FORM buscar_ident .

  DATA: w_lifnr TYPE lfa1-stcd1,
        w_stcdt TYPE lfa1-stcdt.

*** INICIO MODIFICACION APV110406
* Se fija en el campo STCDT el cual contiene
* 01-cedula ciudadania : toma la cedula de LFA1-STCD1
* 02-NIT: toma la identif. de STCD1 con DV
* 03-RUT: toma la identif. de REGUH-LIFNR
* 04-Ced.extran: como 01
* 05-Pasaporte: como 01
* 06-Tarjeta identidad: como 01

  IF g_lnrza IS INITIAL.

    SELECT SINGLE stcd1 stcdt
      INTO (w_lifnr , w_stcdt )
      FROM lfa1
     WHERE lifnr = t_reguh-lifnr.

    CASE w_stcdt. "nuevo indicador de tipo documento

      WHEN '01' OR '04' OR '05' OR '06'.
*    Es una persona natural y toma la identifiacion LFA1-STCD1
        MOVE: w_lifnr TO wa_salida-idepar.
      WHEN '31'.
        MOVE: w_lifnr(9)   TO wa_salida-idepar.
      WHEN '03'. "RUT
*    RUT de una persona natural
        MOVE: t_reguh-lifnr TO wa_salida-idepar.
    ENDCASE.

  ELSE.

    SELECT SINGLE stcd1 stcdt
       INTO (w_lifnr , w_stcdt )
       FROM lfa1
      WHERE lifnr = g_lnrza.

    CASE w_stcdt. "nuevo indicador de tipo documento

      WHEN '11' OR '12' OR '13' OR '21' OR '22'.
*  Es una persona natural y toma la identifiacion LFA1-STCD1
        MOVE: g_lnrza TO wa_salida-idepar.
      WHEN '31'.
        MOVE: g_lnrza TO wa_salida-idepar.
      WHEN '03'. "RUT
*  RUT de una persona natural
        MOVE: g_lnrza TO wa_salida-idepar.
    ENDCASE.

  ENDIF.

*   CASE w_stcdt. "nuevo indicador de tipo documento
*
*    WHEN '01' OR '04' OR '05' OR '06'.
**Es una persona natural y toma la identifiacion LFA1-STCD1
*       MOVE: w_lifnr TO wa_salida-idepar.
*    WHEN '02'.
*       MOVE: w_lifnr(9)   TO wa_salida-idepar.
*    WHEN '03'. "RUT
**RUT de una persona natural
*       MOVE: wa_reguh-lifnr TO wa_salida-idepar.
*   ENDCASE.

*** FIN MODIFICACION APV110406

ENDFORM.                    " buscar_ident
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_DATA_COLMENA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DOWNLOAD_DATA_COLMENA .

  IF NOT it_linea[] IS INITIAL.
*    REFRESH tdw_bcre.
*    CLEAR   tdw_bcre.
    INSERT LINES OF tab_bcre INTO tdw_bcre INDEX 1.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        filename      = filename
        col_select    = 'X'
      TABLES
        data_tab      = it_linea
      EXCEPTIONS
        no_batch      = 4
        unknown_error = 5
        OTHERS        = 7.
    PERFORM lock_f110.
    MESSAGE i398 WITH text-m01 filename.
  ELSE.
    MESSAGE i208 WITH text-m02.
  ENDIF.
                    " download_data_bcre
ENDFORM.                    " DOWNLOAD_DATA_COLMENA
