class ZCL_CDS_ANNOT_GRID definition
  public
  final
  create protected .

public section.

  class-methods GET_INSTANCE
    importing
      !IV_CONT_NAME type CHAR30
      !IR_ANNOT_TREE type ref to ZCL_CDS_ANNOT_TREE
    returning
      value(ER_ANNOT_GRID) type ref to ZCL_CDS_ANNOT_GRID .
  methods DISPLAY_GRID .
protected section.

  class-data MR_ANNOT_GRID type ref to ZCL_CDS_ANNOT_GRID .

  methods CONSTRUCTOR
    importing
      !IV_CONT_NAME type CHAR30
      !IR_ANNOT_TREE type ref to ZCL_CDS_ANNOT_TREE .
private section.

  data MR_ANNOT_TREE type ref to ZCL_CDS_ANNOT_TREE .
  data MV_CONT_NAME type CHAR30 .
  data MR_GRID type ref to CL_GUI_ALV_GRID .
  data MR_CONTAINER type ref to CL_GUI_CUSTOM_CONTAINER .
  data MV_CURRENT_NODE type TV_NODEKEY .
  data MS_NODE_ANNOTATIONS type ZCL_CDS_ANNOT_TREE=>TY_NODE_ANNOT_DETAILS .
  data MR_TABLE_DEF type ref to CL_BLE_DYNAMIC_TABLE .
  data MT_FIELDCAT type LVC_T_FCAT .
  data MR_ALV_TABLE type ref to DATA .

  methods SET_GRID_TOOLBAR .
  methods SET_EVENTS_AND_HANDLERS .
  methods CREATE_DYNAMIC_TABLE .
  methods HANDLE_CHANGED_DATA
    for event DATA_CHANGED of CL_GUI_ALV_GRID
    importing
      !ER_DATA_CHANGED
      !E_ONF4
      !E_ONF4_BEFORE
      !E_ONF4_AFTER
      !E_UCOMM .
  methods HANDLE_ONF4
    for event ONF4 of CL_GUI_ALV_GRID
    importing
      !E_FIELDNAME
      !E_FIELDVALUE
      !ES_ROW_NO
      !ER_EVENT_DATA
      !ET_BAD_CELLS
      !E_DISPLAY .
  methods HANDLE_TOOLBAR
    for event TOOLBAR of CL_GUI_ALV_GRID
    importing
      !E_OBJECT
      !E_INTERACTIVE .
  methods REFRESH_TABLE_DISPLAY .
  methods REFRESH_OUTPUT_TABLE .
ENDCLASS.



CLASS ZCL_CDS_ANNOT_GRID IMPLEMENTATION.


  METHOD constructor.
    mr_annot_tree = ir_annot_tree.
    mv_cont_name = iv_cont_name.
  ENDMETHOD.


  METHOD create_dynamic_table.

    DATA: ls_fieldcat  TYPE lvc_s_fcat,
          lv_lines     TYPE sy-index,
          lv_result    TYPE string,
          ls_f4_fields TYPE lvc_s_f4,
          lt_f4_fields TYPE lvc_t_f4,
          lt_result    TYPE STANDARD TABLE OF string.

*   Set all the annotations as individual columns in the grid display
    REFRESH mt_fieldcat.
    LOOP AT ms_node_annotations-annotations INTO DATA(ls_annotations).

      CLEAR ls_fieldcat.
      ls_fieldcat-col_pos    = sy-tabix.

*     Drop parent annotations and just keep the actual one
      SPLIT ls_annotations-key AT '.' INTO TABLE lt_result.
      DESCRIBE TABLE lt_result LINES lv_lines.
      READ TABLE lt_result INTO lv_result INDEX lv_lines.

      ls_fieldcat-fieldname  = lv_result.
      ls_fieldcat-scrtext_m  = lv_result.

*     Set Data Type for fields
      CASE ls_annotations-type.
        WHEN 'Boolean'.
          ls_fieldcat-inttype  = 'C'.
          ls_fieldcat-intlen   = 1.
          ls_fieldcat-checkbox = abap_true.

        WHEN 'String'.
          ls_fieldcat-inttype   = 'g'.
          IF ls_annotations-length IS NOT INITIAL.
            ls_fieldcat-intlen    = ls_annotations-length.
            ls_fieldcat-outputlen = ls_annotations-length.
          ELSE.
            ls_fieldcat-outputlen = 40.
          ENDIF.

        WHEN 'Integer'.
          ls_fieldcat-datatype = 'INT1'.

        WHEN 'Decimal'.
          ls_fieldcat-inttype  = 'p'.
          ls_fieldcat-intlen   = ls_annotations-length.
          ls_fieldcat-decimals = ls_annotations-decimals.

        WHEN 'entityRef'.
          ls_fieldcat-inttype  = 'C'.
          ls_fieldcat-intlen   = 1.

        WHEN 'parameterRef'.
          ls_fieldcat-inttype  = 'C'.
          ls_fieldcat-intlen   = 1.

*         Append field for F4
          ls_fieldcat-f4availabl = abap_true.
          CLEAR ls_f4_fields.
          ls_f4_fields-fieldname = ls_fieldcat-fieldname.
          ls_f4_fields-register  = abap_true.
          ls_f4_fields-getbefore = abap_true.
          INSERT ls_f4_fields INTO TABLE lt_f4_fields.

        WHEN 'elementRef'.
          ls_fieldcat-inttype  = 'C'.
          ls_fieldcat-intlen   = 30.

*         Append field for F4
          ls_fieldcat-f4availabl = abap_true.
          CLEAR ls_f4_fields.
          ls_f4_fields-fieldname = ls_fieldcat-fieldname.
          ls_f4_fields-register  = abap_true.
          ls_f4_fields-getbefore = abap_true.
          INSERT ls_f4_fields INTO TABLE lt_f4_fields.

        WHEN 'associationRef'.
          ls_fieldcat-inttype  = 'C'.
          ls_fieldcat-intlen   = 1.

*         Append field for F4
          ls_fieldcat-f4availabl = abap_true.
          CLEAR ls_f4_fields.
          ls_f4_fields-fieldname = ls_fieldcat-fieldname.
          ls_f4_fields-register  = abap_true.
          ls_f4_fields-getbefore = abap_true.
          INSERT ls_f4_fields INTO TABLE lt_f4_fields.

        WHEN 'Expression'.
          ls_fieldcat-inttype  = 'C'.
          ls_fieldcat-intlen   = 30.

        WHEN OTHERS.
*         Lets see
          ls_fieldcat-inttype  = 'C'.
          ls_fieldcat-intlen   = 10.
      ENDCASE.


*     Set F4 Help Available
      IF ls_annotations-enum_vals IS NOT INITIAL.
        ls_fieldcat-f4availabl = abap_true.

*       Append field for F4
        CLEAR ls_f4_fields.
        ls_f4_fields-fieldname = ls_fieldcat-fieldname.
        ls_f4_fields-register  = abap_true.
        ls_f4_fields-getbefore = abap_true.
        INSERT ls_f4_fields INTO TABLE lt_f4_fields.
      ENDIF.

*     Set Edit Flag
      DATA(lv_mode) = mr_annot_tree->mr_view_builder_tree->get_mode( ).
      IF lv_mode = zcl_cds_modeller=>mc_mode_change.
        ls_fieldcat-edit = abap_true.
      ENDIF.

      ls_fieldcat-col_opt = abap_true.
      APPEND ls_fieldcat TO mt_fieldcat.
    ENDLOOP.

*   Create Dynamic Table
    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        it_fieldcatalog           = mt_fieldcat
      IMPORTING
        ep_table                  = mr_alv_table
      EXCEPTIONS
        generate_subpool_dir_full = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.

*   Register fields for F4
    IF lt_f4_fields IS NOT INITIAL.
      CALL METHOD mr_grid->register_f4_for_fields
        EXPORTING
          it_f4 = lt_f4_fields.
    ENDIF.
  ENDMETHOD.


  METHOD display_grid.

    DATA:
      ls_layout               TYPE lvc_s_layo,
      lv_refresh_fieldcatalog TYPE abap_bool,
      lv_refresh_table        TYPE abap_bool.

    FIELD-SYMBOLS:
          <ft_table> TYPE table.

*   Instantiate Grid Container
    IF mr_container IS NOT BOUND.
      CREATE OBJECT mr_container
        EXPORTING
          container_name              = mv_cont_name
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5
          OTHERS                      = 6.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ENDIF.

*   Instantiate Grid Control
    IF mr_grid IS NOT BOUND.
      CREATE OBJECT mr_grid
        EXPORTING
          i_parent          = mr_container
        EXCEPTIONS
          error_cntl_create = 1
          error_cntl_init   = 2
          error_cntl_link   = 3
          error_dp_create   = 4
          OTHERS            = 5.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ENDIF.

*   Get Selected Node
    DATA(lv_current_node) = mr_annot_tree->get_selected_node( ).

    CLEAR: lv_refresh_fieldcatalog, lv_refresh_table.
    IF lv_current_node NE mv_current_node.
      lv_refresh_fieldcatalog = abap_true.
      lv_refresh_table        = abap_true.

*     Set new node as current node required to be displayed
      mv_current_node = lv_current_node.
    ENDIF.

*   Get annotations relevant to node
    ms_node_annotations = mr_annot_tree->get_node_annotations( mv_current_node ).
    CHECK ms_node_annotations IS NOT INITIAL.

*   Set Toolbar
    CALL METHOD set_grid_toolbar( ).

*   Set Events and Handlers
    CALL METHOD set_events_and_handlers( ).

*   Create Table for the Annotations
*    IF lv_refresh_fieldcatalog EQ abap_true.
    CALL METHOD create_dynamic_table.
*    ENDIF.

*    IF lv_refresh_table EQ abap_true.
    CALL METHOD refresh_output_table( ).
*    ENDIF.

    ASSIGN mr_alv_table->* TO <ft_table>.
    APPEND INITIAL LINE TO <ft_table>.

    ls_layout-cwidth_opt = abap_true.
    CALL METHOD mr_grid->set_table_for_first_display
      EXPORTING
        is_layout                     = ls_layout
      CHANGING
        it_outtab                     = <ft_table>
        it_fieldcatalog               = mt_fieldcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.


*   Set Editable Options
    DATA(lv_mode) = mr_annot_tree->mr_view_builder_tree->get_mode( ).
    IF lv_mode = zcl_cds_modeller=>mc_mode_change.
      CALL METHOD mr_grid->set_ready_for_input( 1 ).
    ELSE.
      CALL METHOD mr_grid->set_ready_for_input( 0 ).
    ENDIF.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.
  ENDMETHOD.


  METHOD get_instance.
*   Instantiate Annotation Grid Class
    IF mr_annot_grid IS NOT BOUND.
      CREATE OBJECT mr_annot_grid
        EXPORTING
          iv_cont_name  = iv_cont_name
          ir_annot_tree = ir_annot_tree.
    ENDIF.

    er_annot_grid = mr_annot_grid.
  ENDMETHOD.


  method HANDLE_CHANGED_DATA.
  endmethod.


  METHOD handle_onf4.

    DATA:
      ls_modi      TYPE lvc_s_modi,
      ls_f4_values TYPE zcds_annot_f4_help,
      lt_f4_values TYPE STANDARD TABLE OF zcds_annot_f4_help,
      lt_return    TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY.

    FIELD-SYMBOLS:
      <ft_alv_table>      TYPE STANDARD TABLE,
      <ft_f4_event_table> TYPE STANDARD TABLE.

    LOOP AT ms_node_annotations-annotations ASSIGNING FIELD-SYMBOL(<fs_annot>).
*     Check If the annotation has Enumerations
      READ TABLE <fs_annot>-key_tokens TRANSPORTING NO FIELDS
                                       WITH KEY lexem = e_fieldname.
      CHECK sy-subrc EQ 0.

*     Provide F4 Help if the Enumerations are available
      IF <fs_annot>-enum_vals IS NOT INITIAL.
*       Set Enumerations
        REFRESH lt_f4_values.
        LOOP AT <fs_annot>-enum_vals INTO DATA(ls_enum_values).
          ls_f4_values-value = ls_enum_values-symbol.
          APPEND ls_f4_values TO lt_f4_values.
        ENDLOOP.
      ENDIF.

*     Show F4 Help
      IF lt_f4_values IS NOT INITIAL.
        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
          EXPORTING
            ddic_structure  = 'ZCDS_ANNOT_F4_HELP'
            retfield        = 'VALUE'
            window_title    = 'Select required value'
          TABLES
            value_tab       = lt_f4_values
            return_tab      = lt_return
          EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
        IF sy-subrc <> 0.
*         Implement suitable error handling here
        ENDIF.
      ENDIF.
    ENDLOOP.

*   Set Data for the choosen value
    IF lt_return IS NOT INITIAL.

      READ TABLE lt_return INTO DATA(ls_return) INDEX 1.

*     Update application ALV table
      ASSIGN mr_alv_table->* TO <ft_alv_table>.
      READ TABLE <ft_alv_table> ASSIGNING FIELD-SYMBOL(<fs_alv_table>)
                                INDEX es_row_no-row_id.
      IF sy-subrc EQ 0.
        ASSIGN COMPONENT e_fieldname OF STRUCTURE <fs_alv_table>
                                     TO FIELD-SYMBOL(<fv_value>).
        CHECK <fv_value> IS ASSIGNED.
        <fv_value> = ls_return-fieldval.
      ENDIF.

*     Update F4 Event table
      ASSIGN er_event_data->m_data->* TO <ft_f4_event_table>.
      ls_modi-row_id    = es_row_no-row_id.
      ls_modi-fieldname = e_fieldname.
      ls_modi-value     = ls_return-fieldval.
      APPEND ls_modi TO <ft_f4_event_table>.
    ENDIF.


*   Set Event handled
    er_event_data->m_event_handled = abap_true.

*   Refresh ALV Table
    CALL METHOD refresh_table_display( ).
  ENDMETHOD.


  METHOD handle_toolbar.

    FIELD-SYMBOLS:
      <fs_toolbar> TYPE stb_button.

*   Get Working Mode
    DATA(lv_mode) = mr_annot_tree->mr_view_builder_tree->get_mode( ).
    IF lv_mode = zcl_cds_modeller=>mc_mode_change.

      IF ms_node_annotations-is_array IS NOT INITIAL.
        DELETE e_object->mt_toolbar WHERE function NE '&DETAIL'
                                    and   function NE cl_gui_alv_grid=>mc_fc_loc_append_row
                                    and   function NE cl_gui_alv_grid=>mc_fc_loc_delete_row.
      ELSE.
*       Dont need any other Toolbar except for Detail
        DELETE e_object->mt_toolbar WHERE function NE '&DETAIL'.
      ENDIF.
    ELSE.
*     Dont need any other Toolbar except for Detail
      DELETE e_object->mt_toolbar WHERE function NE '&DETAIL'.
    ENDIF.
  ENDMETHOD.


  method REFRESH_OUTPUT_TABLE.
  endmethod.


  METHOD refresh_table_display.

    CALL METHOD mr_grid->refresh_table_display
      EXPORTING
        i_soft_refresh = 'X'
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.
  ENDMETHOD.


  METHOD set_events_and_handlers.

*   Register Modified Event
    CALL METHOD mr_grid->register_edit_event(
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

*   Register Enter event
    CALL METHOD mr_grid->register_edit_event(
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter ).

*   Set Handlers
    SET HANDLER me->handle_toolbar      FOR mr_grid.
    SET HANDLER me->handle_changed_data FOR mr_grid.
    SET HANDLER me->handle_onf4         FOR mr_grid.
  ENDMETHOD.


  method SET_GRID_TOOLBAR.
  endmethod.
ENDCLASS.
