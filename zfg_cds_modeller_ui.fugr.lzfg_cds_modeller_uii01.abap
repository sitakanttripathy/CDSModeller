*----------------------------------------------------------------------*
***INCLUDE LZFG_CDS_MODELLER_UII01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  CHECK_DDL_NAME  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_ddl_name INPUT.
* Check for Valid DDL Name
  IF gs_ddddlsource-ddlname IS NOT INITIAL.
    SELECT SINGLE * FROM ddddlsrc INTO @DATA(ls_ddddlsource)
                         WHERE ddlname = @gs_ddddlsource-ddlname.
    IF sy-subrc EQ 0.
      MESSAGE e003(zcds_messages) WITH gs_ddddlsource-ddlname.
      RETURN.
    ENDIF.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INSTANTIATE_BIEW_BUILDER OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE instantiate_view_builder OUTPUT.
  PERFORM instantiate_view_builder.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command INPUT.

* Set Flag for operation cancelled
  gv_cancelled = abap_true.

  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9000 INPUT.
  PERFORM user_command_9000.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9001 INPUT.
  CASE sy-ucomm.
    WHEN 'ENTER'.
*     Check for parent DDL Name
      IF  gs_ddddlsource-source_type EQ 'E'
      AND gs_ddddlsource-parentname IS INITIAL.
        MESSAGE i398(00) WITH 'Please provide Parent DDL Name.'
          DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_SOURCE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_source INPUT.
* Validate Table
  IF gs_data_source-tbma_val IS NOT INITIAL.
    SELECT SINGLE * FROM dd02l INTO @DATA(ls_table)
                               WHERE tabname  = @gs_data_source-tbma_val
                               AND   tabclass = 'TRANSP'.
    IF sy-subrc NE 0.
      MESSAGE e000(zcds_messages) WITH gs_data_source-tbma_val.
    ENDIF.
  ENDIF.

* Validate Views
  IF gs_data_source-vima_val IS NOT INITIAL.
    SELECT SINGLE * FROM dd02l INTO @DATA(ls_view)
                               WHERE tabname  = @gs_data_source-vima_val
                               AND   tabclass = 'VIEW'.
    IF sy-subrc NE 0.
      MESSAGE e001(zcds_messages) WITH gs_data_source-vima_val.
    ENDIF.
  ENDIF.

* Validate CDS Source
  IF gs_data_source-ddl_source IS NOT INITIAL.
    SELECT SINGLE * FROM ddddlsrc INTO @DATA(ls_ddl_source)
                                  WHERE ddlname = @gs_data_source-ddl_source.
    IF sy-subrc NE 0.
      MESSAGE e002(zcds_messages) WITH gs_data_source-ddl_source.
    ENDIF.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9002  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9002 INPUT.
  DATA:
    lv_return TYPE abap_bool.

  CASE sy-ucomm.
    WHEN 'ENTER'.
      CLEAR lv_return.
      PERFORM check_updates CHANGING lv_return.
      CHECK lv_return IS INITIAL.

      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CHECK_SOURCE_CHANGE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_source_change INPUT.
  PERFORM check_source_change.
ENDMODULE.
