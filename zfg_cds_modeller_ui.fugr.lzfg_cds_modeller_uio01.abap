*----------------------------------------------------------------------*
***INCLUDE LZFG_CDS_MODELLER_UIO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_9000 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_9000 OUTPUT.
  SET PF-STATUS 'COCKPIT'.
  SET TITLEBAR 'COCKPIT'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module MODIFY_SCREEN_ELEMENTS OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE output_9001 OUTPUT.
  LOOP AT SCREEN.
*   Switch Off Parent DDL Name if it is not a View Extension
    IF screen-group1 EQ 'EXT'.
      IF gs_ddddlsource-source_type EQ 'E'. "Extend View
        screen-input     = 1.
      ELSE.
        screen-input     = 0.
        screen-invisible = 1.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_9001 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_9001 OUTPUT.
  SET PF-STATUS '9001'.
  SET TITLEBAR '9001'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module OUTPUT_9002 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE output_9002 OUTPUT.

  SET PF-STATUS '9001'.

* Instaniate Source based on type
* Table Source Selected
  IF gs_source_type-table IS NOT INITIAL.
    CLEAR: gs_data_source-vima_val,
           gs_data_source-ddl_source.
* View Source Selected
  ELSEIF gs_source_type-view IS NOT INITIAL.
    CLEAR: gs_data_source-tbma_val,
           gs_data_source-ddl_source.
* DDL Source Selected
  ELSEIF gs_source_type-cds IS NOT INITIAL.
    CLEAR: gs_data_source-tbma_val,
           gs_data_source-vima_val.
  ENDIF.

  LOOP AT SCREEN.
*   Display for Source Table
    IF gs_source_type-table IS NOT INITIAL.
      IF screen-group1 EQ 'TAB'.
        screen-input = 1.
      ELSEIF screen-group1 EQ 'VEW' OR screen-group1 EQ 'CDS'.
        screen-input = 0.
      ENDIF.

*   Display for Source View
    ELSEIF gs_source_type-view IS NOT INITIAL.
      IF screen-group1 EQ 'VEW'.
        screen-input = 1.
      ELSEIF screen-group1 EQ 'TAB' OR screen-group1 EQ 'CDS'.
        screen-input = 0.
      ENDIF.

*   Display for source CDS
    ELSEIF gs_source_type-cds IS NOT INITIAL.
      IF screen-group1 EQ 'CDS'.
        screen-input = 1.
      ELSEIF screen-group1 EQ 'VEW' OR screen-group1 EQ 'TAB'.
        screen-input = 0.
      ENDIF.
    ENDIF.

    IF gv_no_details EQ abap_true
    AND ( screen-name EQ 'BOX2' OR screen-name EQ 'SELECTION' ).
      screen-input = 0.
      screen-invisible = 1.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_9003 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_9003 OUTPUT.
  SET PF-STATUS '9001'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INSTANTIATE_SELECTIONS OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE instantiate_selections OUTPUT.
  PERFORM instantiate_selections.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module OUTPUT_9003 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE output_9003 OUTPUT.
* Switch Off screen if details are not required
  LOOP AT SCREEN.
    IF gv_no_details EQ abap_true
    AND ( screen-name EQ 'BOX1' OR screen-name EQ 'SELECTION' ).
      screen-input = 0.
      screen-invisible = 1.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.
