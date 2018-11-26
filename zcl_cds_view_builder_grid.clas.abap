class ZCL_CDS_VIEW_BUILDER_GRID definition
  public
  final
  create protected .

public section.

  class-methods GET_INSTANCE
    importing
      !IV_CONT_NAME type CHAR30
      !IR_TREE type ref to ZCL_CDS_VIEW_BUILDER_TREE
    returning
      value(ER_GRID) type ref to ZCL_CDS_VIEW_BUILDER_GRID .
  methods DISPLAY_GRID .
  methods CHECK_DATA_CHANGED .
protected section.

  methods CONSTRUCTOR
    importing
      !IV_CONT_NAME type CHAR30
      !IR_TREE type ref to ZCL_CDS_VIEW_BUILDER_TREE optional .
private section.

  data MR_VIEW_BUILDER type ref to ZCL_CDS_VIEW_BUILDER_TREE .
  class-data MV_CONT_NAME type CHAR30 .
  data MR_CONTAINER type ref to CL_GUI_CUSTOM_CONTAINER .
  data MR_GRID type ref to CL_GUI_ALV_GRID .
  data GT_FIELDCATALOG type LVC_T_FCAT .
  data GR_ALV_DATA type ref to DATA .
  data MS_NODE_DETAILS type ZCDS_VIEW_TREE_NODES .
  data MS_ITEM_DETAILS type MTREEITM .
  data MS_NODE_DATAREF type ZCL_CDS_VIEW_BUILDER_TREE=>TY_NODE_DATAREF .
  class-data MR_VIEW_BUILDER_GRID type ref to ZCL_CDS_VIEW_BUILDER_GRID .

  methods IS_FIELD_EDITABLE
    importing
      !IV_FIELDNAME type FIELDNAME
    returning
      value(EV_EDIT) type ABAP_BOOL .
  methods IS_F4_REQUIRED
    importing
      !IV_FIELDNAME type FIELDNAME
    returning
      value(EV_F4_REQUIRED) type ABAP_BOOL .
  methods GET_NODE_TO_DISPLAY .
  methods SET_FIELD_CATALOG_AND_DATA .
  methods SET_EVENT_AND_HANDLERS .
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
  methods UPDATE_NODE_DATA_FROM_ALV .
  methods VALIDATE_CHANGED_DATA
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods REGISTER_F4_FIELDS .
  methods VALIDATE_ENTITY
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods VALIDATE_ASSOCIATIONS
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods VALIDATE_JOINS
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods VALIDATE_ELEMENTS
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods VALIDATE_PARAMETERS
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods VALIDATE_REF_CONSTRAINTS
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods VALIDATE_SEL_CONSTRAINTS
    importing
      !ER_DATA_CHANGED type ref to CL_ALV_CHANGED_DATA_PROTOCOL .
  methods HANDLE_USER_COMMAND
    for event USER_COMMAND of CL_GUI_ALV_GRID
    importing
      !E_UCOMM .
  methods SELECT_ELEMENTS .
  methods SELECT_REF_CONSTRAINTS .
  methods SELECT_SEL_CONSTRAINTS .
ENDCLASS.



CLASS ZCL_CDS_VIEW_BUILDER_GRID IMPLEMENTATION.


  METHOD CHECK_DATA_CHANGED.
*   Fire Changed Data Handling
    CALL METHOD mr_grid->check_changed_data( ).
  ENDMETHOD.


  METHOD constructor.
*   Set Instance for further use
    mr_view_builder = ir_tree.
    mv_cont_name    = iv_cont_name.
  ENDMETHOD.


  METHOD display_grid.
    DATA:
      ls_layout TYPE lvc_s_layo.

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

*   Get Current Node and relevant details
    DATA(lv_current_node) = mr_view_builder->get_current_node( ).
    CALL METHOD mr_view_builder->get_node_details(
      EXPORTING
        iv_node_key     = lv_current_node
      IMPORTING
        es_node_details = ms_node_details
        es_item_details = ms_item_details
        es_node_dataref = ms_node_dataref ).

    CHECK lv_current_node IS NOT INITIAL.

*   Set FieldCatalog
    CALL METHOD set_field_catalog_and_data( ).

*   Set F4 for fields
    CALL METHOD register_f4_fields( ).

*   Set Events and Handlers
    CALL METHOD set_event_and_handlers( ).

*   Set Layout
    ls_layout-cwidth_opt = abap_true.

*   Set Intractive Toolbar
    CALL METHOD mr_grid->set_toolbar_interactive( ).

    ASSIGN gr_alv_data->* TO FIELD-SYMBOL(<ft_table>).
    CALL METHOD mr_grid->set_table_for_first_display
      EXPORTING
        is_layout                     = ls_layout
      CHANGING
        it_outtab                     = <ft_table>
        it_fieldcatalog               = gt_fieldcatalog
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.

*   Flush Queue
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

    IF mr_view_builder_grid IS NOT BOUND.
*     Instantiate View Builder Grid
      CREATE OBJECT mr_view_builder_grid
        EXPORTING
          iv_cont_name = iv_cont_name
          ir_tree      = ir_tree.
    ENDIF.

    er_grid = mr_view_Builder_grid.

  ENDMETHOD.


  METHOD get_node_to_display.
*   Get Current Node
    data(lv_current_node) = mr_view_builder->get_current_node( ).

*   Get Current Node Details

  ENDMETHOD.


  METHOD handle_changed_data.

    DATA:
      ls_mod_cells    TYPE lvc_s_modi,
      ls_components   TYPE abap_componentdescr,
      lt_components   TYPE abap_component_tab,
      lr_struct_descr TYPE REF TO cl_abap_structdescr,
      lr_table_descr  TYPE REF TO cl_abap_tabledescr.

    FIELD-SYMBOLS:
      <fv_value>          TYPE any,
      <ft_table>          TYPE STANDARD TABLE,
      <fs_table>          TYPE any,
      <fs_node_data>      TYPE any,
      <ft_node_table>     TYPE STANDARD TABLE,
      <fs_node_table>     TYPE any,
      <fs_node_comp_data> TYPE any,
      <ft_node_data>      TYPE STANDARD TABLE.

*   Check for triggers because of F4
    CHECK               e_onf4 IS INITIAL.
    CHECK e_onf4_before IS INITIAL.
    CHECK e_onf4_after IS INITIAL.

*   Get reference of local table data
    ASSIGN gr_alv_data->* TO <ft_table>.

    CHECK ms_node_dataref-dataref IS NOT INITIAL.
    DATA(lr_type_descr) = cl_abap_typedescr=>describe_by_data_ref( ms_node_dataref-dataref ).

*   Flat Structure Types: This will be a leaf node with a single line. For example displaying
*   attributes of one of the fields of a table. Addition or Deletion of new rows is diabled
*   for these nodes and hence not required
    IF ( lr_type_descr->type_kind = cl_abap_structdescr=>kind_struct OR
         lr_type_descr->type_kind = cl_abap_structdescr=>typekind_struct1 ).

      lr_struct_descr ?= lr_type_descr.
*     Get data associated with the node
      ASSIGN ms_node_dataref-dataref->* TO <fs_node_comp_data>.

*     Process for modified cells
      IF er_data_changed->mt_mod_cells IS NOT INITIAL.
*       Process all the modified cells
        LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells.
*         Identify table row modified
          READ TABLE <ft_table> ASSIGNING <fs_table> INDEX ls_mod_cells-row_id.
          IF <fs_table> IS ASSIGNED.
*           Get reference of modified fieldname
            ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_table> TO <fv_value>.
            CHECK <fv_value> IS ASSIGNED.
            <fv_value> = ls_mod_cells-value.

*           Need to change the value in node data source
*           Get reference of modified fieldname
            UNASSIGN <fv_value>.
            ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_node_comp_data> TO <fv_value>.
            CHECK <fv_value> IS ASSIGNED.
            <fv_value> = ls_mod_cells-value.
          ENDIF.
        ENDLOOP.
      ENDIF.
*   Deep Structure Types: This is applicable for all the deep structures wherein
*   the first component is node followed by further deep and nested data attributes
    ELSEIF lr_type_descr->type_kind = cl_abap_structdescr=>typekind_struct2.

*     Get actual structure reference
      lr_struct_descr ?= lr_type_descr.

*     Get structure components and check for NODE element. This should be available
*     for all the deep structures.
      lt_components = lr_struct_descr->get_components( ).
      READ TABLE lt_components TRANSPORTING NO FIELDS WITH KEY name = 'NODE'.
      IF sy-subrc EQ 0.
*       Get data assoiated with the node
        ASSIGN ms_node_dataref-dataref->* TO <fs_node_data>.

*       Process for modified cells
        IF er_data_changed->mt_mod_cells IS NOT INITIAL.
*         Process all the modified cells
          LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells.
*           Identify table row modified
            READ TABLE <ft_table> ASSIGNING <fs_table> INDEX ls_mod_cells-row_id.
            IF <fs_table> IS ASSIGNED.
*             Get reference of modified fieldname
              ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_table> TO <fv_value>.
              CHECK <fv_value> IS ASSIGNED.
              <fv_value> = ls_mod_cells-value.

*             Also Change the data model source
              UNASSIGN <fv_value>.
              ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_node_data> TO <fv_value>.
              CHECK <fv_value> IS ASSIGNED.
              <fv_value> = ls_mod_cells-value.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.

*   Table Types
    ELSEIF ( lr_type_descr->type_kind = cl_abap_structdescr=>typekind_table OR
             lr_type_descr->type_kind = cl_abap_structdescr=>kind_table ).

*     Get tabular data associated with the node
      ASSIGN ms_node_dataref-dataref->* TO <ft_node_table>.

*     Get actual table type reference
      lr_table_descr ?= lr_type_descr.
      DATA(lr_table_line_type) = lr_table_descr->get_table_line_type( ).

*     Get reference to line type for the table
      lr_struct_descr ?= lr_table_line_type.

*     Flat Structure Types
      IF  lr_struct_descr->type_kind EQ cl_abap_structdescr=>typekind_struct1.

*       Process for modified cells
        IF er_data_changed->mt_mod_cells IS NOT INITIAL.
*         Process all the modified cells
          LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells.
*           Identify table row modified
            READ TABLE <ft_table> ASSIGNING <fs_table> INDEX ls_mod_cells-row_id.
            IF <fs_table> IS ASSIGNED.
*             Get reference of modified fieldname
              ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_table> TO <fv_value>.
              CHECK <fv_value> IS ASSIGNED.
              <fv_value> = ls_mod_cells-value.

*             Need to change the node data source as well
              READ TABLE <ft_node_table> ASSIGNING <fs_node_table> INDEX ls_mod_cells-row_id..
              IF <fs_node_table> IS ASSIGNED.
*               Get reference of modified fieldname
                ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_node_table> TO <fv_value>.
                CHECK <fv_value> IS ASSIGNED.
                <fv_value> = ls_mod_cells-value.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.

*       Process Inserted Rows
        IF er_data_changed->mt_inserted_rows IS NOT INITIAL.
*         Add to ALV Table
          APPEND INITIAL LINE TO <ft_table>.
*         Add to Node Data Table
          APPEND INITIAL LINE TO <ft_node_table>.
        ENDIF.

*       Process Deleted Rows
        IF er_data_changed->mt_deleted_rows IS NOT INITIAL.
          LOOP AT er_data_changed->mt_deleted_rows ASSIGNING FIELD-SYMBOL(<fs_del_rows>).
*           Delete from ALV Table
            DELETE <ft_table>      INDEX <fs_del_rows>-row_id.
*           Delete from Node data Table
            DELETE <ft_node_table> INDEX <fs_del_rows>-row_id.
          ENDLOOP.
        ENDIF.

*     Deep Structure Types
      ELSEIF lr_struct_descr->type_kind EQ cl_abap_structdescr=>typekind_struct2.

*       Get structure components and check for NODE element. This should be available
*       for all the deep structures.
        lt_components = lr_struct_descr->get_components( ).
        READ TABLE lt_components INTO ls_components WITH KEY name = 'NODE'.
        CHECK sy-subrc EQ 0.

*       Process for modified cells
        IF er_data_changed->mt_mod_cells IS NOT INITIAL.
*         Process all the modified cells
          LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells.
*           Identify table row modified
            READ TABLE <ft_table> ASSIGNING <fs_table> INDEX ls_mod_cells-row_id.
            IF <fs_table> IS ASSIGNED.
*             Get reference of modified fieldname
              ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_table> TO <fv_value>.
              CHECK <fv_value> IS ASSIGNED.
              <fv_value> = ls_mod_cells-value.

*             Need to change the node data source as well
              READ TABLE <ft_node_table> ASSIGNING <fs_node_table> INDEX ls_mod_cells-row_id..
              IF <fs_node_table> IS ASSIGNED.
*               Get reference of NODE sub structure
                ASSIGN COMPONENT 'NODE' OF STRUCTURE <fs_node_table> TO <fs_node_data>.
                CHECK <fs_node_data> IS ASSIGNED.

*               Now Get reference of the actual field to be modifed within the Node Sub-structure
                ASSIGN COMPONENT ls_mod_cells-fieldname OF STRUCTURE <fs_node_data> TO <fv_value>.
                CHECK <fv_value> IS ASSIGNED.
                <fv_value> = ls_mod_cells-value.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.

*   Validate Data
    CALL METHOD validate_changed_data( er_data_changed ).

  ENDMETHOD.


  METHOD handle_onf4.
    BREAK-POINT.
  ENDMETHOD.


  METHOD handle_toolbar.

    DATA:
     ls_toolbar    TYPE stb_button.

    FIELD-SYMBOLS:
      <fs_toolbar> TYPE stb_button.

*   Get Working Mode
    DATA(lv_mode) = mr_view_builder->get_mode( ).
    CHECK lv_mode EQ zcl_cds_modeller=>mc_mode_change.

*   Disable Local Append
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_append_row.
*   Disable Local Copy
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_copy.
*   Disable Local Copy Row
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_copy_row.
*   Disable Local Cut
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_cut.
*   Disable Local Delete Row
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_delete_row.
*   Disable Local Insert Row
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_insert_row.
*   Disable Local Move Row
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_move_row.
*   Disable Local Paste
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_paste.
*   Disable Local Paste Row
    DELETE TABLE e_object->mt_toolbar WITH TABLE KEY function = cl_gui_alv_grid=>mc_fc_loc_paste_new_row.

*   Check whether data to be displayed is a structure or table
    CHECK ms_node_dataref-dataref IS NOT INITIAL.
    DATA(lr_type_descr) = cl_abap_typedescr=>describe_by_data_ref( ms_node_dataref-dataref ).

*   For structure data
    IF ( lr_type_descr->type_kind = cl_abap_structdescr=>kind_struct OR
         lr_type_descr->type_kind = cl_abap_structdescr=>typekind_struct1 OR
         lr_type_descr->type_kind = cl_abap_structdescr=>typekind_struct2 ).

*     Do nothing already deleted

*   For table data
    ELSEIF ( lr_type_descr->type_kind = cl_abap_structdescr=>typekind_table OR
             lr_type_descr->type_kind = cl_abap_structdescr=>kind_table ).

*     Deletion and Addition of Associations and Nodes needs to be controlled
*     by View Builder Node functions and not from ALV functions
      IF ( ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_e OR
           ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_a OR
           ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_j ).
        "addition and deletion of rows will be done using
        "the node insertion and deletion functionality
      ELSE.
*       Add Separator
        CLEAR ls_toolbar.
        ls_toolbar-butn_type = 3.
        APPEND ls_toolbar TO e_object->mt_toolbar.

*       Append Function Code for Append Row
        CLEAR ls_toolbar.
        ls_toolbar-function  = 'ADD_ROW'.
        ls_toolbar-icon      = icon_insert_row.
        ls_toolbar-quickinfo = 'Add Row'.
        ls_toolbar-butn_type = 0.
        APPEND ls_toolbar TO e_object->mt_toolbar.

*       Append Function Code for Delete Row
        CLEAR ls_toolbar.
        ls_toolbar-function  = 'DELETE_ROW'.
        ls_toolbar-icon      = icon_delete_row.
        ls_toolbar-quickinfo = 'Delete Row'.
        ls_toolbar-butn_type = 0.
        APPEND ls_toolbar TO e_object->mt_toolbar.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD handle_user_command.

    DATA:
      lv_answer TYPE abap_bool.

    FIELD-SYMBOLS:
      <ft_table> TYPE STANDARD TABLE.

    BREAK-POINT.
*   Handle Add Row
    IF e_ucomm EQ 'ADD_ROW'.
      ASSIGN gr_alv_data->* TO <ft_table>.
      APPEND INITIAL LINE TO <ft_table>.

*     Provide Selection based on the Node Type
*     Node Type Element
      IF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_e.
        select_elements( ).
*     Node Type Referential Constrains
      ELSEIF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_r.
        select_ref_constraints( ).
*     Node Type Selection Constraints
      ELSEIF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_s.
        select_sel_constraints( ).
      ENDIF.

*   Handle Delete Row
    ELSEIF e_ucomm EQ 'DELETE_ROW'.
*     Get Selected Rows
      CALL METHOD mr_grid->get_selected_rows
        IMPORTING
          et_row_no = DATA(lt_selected_rows).

*     Check for Row Selection
      IF lt_selected_rows IS INITIAL.
        MESSAGE i006(zcds_messages).
        RETURN.
      ENDIF.

*     Confirm Action
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = TEXT-001
          text_question  = TEXT-002
          text_button_1  = TEXT-003
          text_button_2  = TEXT-004
          default_button = 2
        IMPORTING
          answer         = lv_answer
        EXCEPTIONS
          text_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
*       Implement suitable error handling here
      ELSE.
*       Check and process answer
        IF lv_answer EQ 1.  "User want
*         Delete required rows
          ASSIGN gr_alv_data->* TO <ft_table>.
          CHECK <ft_table> IS NOT INITIAL.

          LOOP AT lt_selected_rows INTO DATA(ls_selected_rows).
            DELETE <ft_table> INDEX ls_selected_rows-row_id.
          ENDLOOP.
        ELSE.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

*   Refresh Table Display
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


  METHOD is_f4_required.

*   Check if the F4 is required for the field
*   Node Type View
    IF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_v.
      IF iv_fieldname EQ 'SOURCE_TYPE'  "Data Element
      OR iv_fieldname EQ 'SEL_SOURCE_TYPE'. "Intenal Data Type
        ev_f4_required = abap_true.
      ENDIF.
*   Node Type Elements
    ELSEIF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_e.
      IF iv_fieldname EQ 'AGGR_FUNCTION'.
        ev_f4_required = abap_true.
      ENDIF.
*   Node Type Association
    ELSEIF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_a.
      IF  iv_fieldname EQ 'CARDINALITY'.
        ev_f4_required = abap_true.
      ENDIF.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_j.
      IF  iv_fieldname EQ 'JOIN_TYPE'.
        ev_f4_required = abap_true.
      ENDIF.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_p.
      IF iv_fieldname EQ 'ROLLNAME'  "Data Element
      OR iv_fieldname EQ 'INT_TYPE'. "Intenal Data Type
        ev_f4_required = abap_true.
      ENDIF.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_r.
      ev_f4_required = abap_true.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_s.
      IF iv_fieldname EQ 'OPERATOR'  "Operator
      OR iv_fieldname EQ 'CONNECTOR' "AND/OR Connectors
      OR iv_fieldname EQ 'GROUP'.    "Start and End of Group
        ev_f4_required = abap_true.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD is_field_editable.

*   Check Change mode
    DATA(lv_mode) = mr_view_builder->get_mode( ).
    CHECK lv_mode EQ zcl_cds_modeller=>mc_mode_change.

*   Set Editable fields based on the node type
*   Node Type View
    IF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_v.
      IF  iv_fieldname NE 'DDL_NAME'
      AND iv_fieldname NE 'SOURCE_TYPE'
      AND iv_fieldname NE 'SEL_SOURCE'
      AND iv_fieldname NE 'SEL_SOURCE_TYPE'.
        ev_edit = abap_true.
      ENDIF.
*   Node Type Elements
    ELSEIF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_e.
      IF iv_fieldname NE 'ELEMENT'.
        ev_edit = abap_true.
      ENDIF.
*   Node Type Association
    ELSEIF ms_node_details-node_type EQ zcl_cds_modeller=>mc_node_type_a.
      IF  iv_fieldname NE 'SEL_SOURCE'
      AND iv_fieldname NE 'SEL_SOURCE_TYPE'.
        ev_edit = abap_true.
      ENDIF.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_j.
      IF  iv_fieldname NE 'SEL_SOURCE'
      AND iv_fieldname NE 'SEL_SOURCE_TYPE'.
        ev_edit = abap_true.
      ENDIF.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_p.
      ev_edit = abap_true.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_r.
      ev_edit = abap_true.
*   Node Type Joins
    ELSEIF ms_node_details-node_type EQ  zcl_cds_modeller=>mc_node_type_s.
      ev_edit = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD register_f4_fields.

    DATA:
      lv_fieldname TYPE fieldname,
      ls_f4_fields TYPE lvc_s_f4,
      lt_f4_fields TYPE lvc_t_f4.

    CASE ms_node_details-node_type.
*     For Element Node Tables
      WHEN zcl_cds_modeller=>mc_node_type_e.
        lv_fieldname = 'ELEMENT'.
*     For Selection Constraints node table
      WHEN zcl_cds_modeller=>mc_node_type_s.
        lv_fieldname = 'ELEMENT'.
      WHEN OTHERS.
*       Not Required
    ENDCASE.

*   Register fields for F4
    IF lv_fieldname IS NOT INITIAL.
      ls_f4_fields-fieldname = lv_fieldname.
      ls_f4_fields-register  = abap_true.
      ls_f4_fields-getbefore = abap_true.
      APPEND ls_f4_fields TO lt_f4_fields.

      CALL METHOD mr_grid->register_f4_for_fields
        EXPORTING
          it_f4 = lt_f4_fields.
    ENDIF.
  ENDMETHOD.


  method SELECT_ELEMENTS.
  endmethod.


  method SELECT_REF_CONSTRAINTS.
  endmethod.


  method SELECT_SEL_CONSTRAINTS.
  endmethod.


  METHOD set_event_and_handlers.

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
    SET HANDLER me->handle_user_command FOR mr_grid.
  ENDMETHOD.


  METHOD set_field_catalog_and_data.
    DATA:
      lv_rel_name     TYPE string,
      lv_fieldname    TYPE fieldname,
      ls_components   TYPE abap_componentdescr,
      lt_components   TYPE abap_component_tab,
      lr_table        TYPE REF TO data,
      lr_struct_descr TYPE REF TO cl_abap_structdescr,
      lr_table_descr  TYPE REF TO cl_abap_tabledescr.

    FIELD-SYMBOLS:
      <fs_table_line>     TYPE any,
      <fs_node_data>      TYPE any,
      <fs_node_comp_data> TYPE any,
      <ft_node_data>      TYPE STANDARD TABLE,
      <ft_table>          TYPE STANDARD TABLE.

    CHECK ms_node_dataref-dataref IS NOT INITIAL.
    DATA(lr_type_descr) = cl_abap_typedescr=>describe_by_data_ref( ms_node_dataref-dataref ).

*   Flat Structure Types: This will be a leaf node with a single line. For example displaying
*   attributes of one of the fields of a table
    IF ( lr_type_descr->type_kind = cl_abap_structdescr=>kind_struct OR
         lr_type_descr->type_kind = cl_abap_structdescr=>typekind_struct1 ).

*     Get actual structure reference
      lr_struct_descr ?= lr_type_descr.

*     Get data associated with the node
      ASSIGN ms_node_dataref-dataref->* TO <fs_node_comp_data>.

*     Create a table type relative to the node data to be displayed
*     Entity/Elements/Joins will have different structures
      lv_rel_name = lr_struct_descr->get_relative_name( ).
      CREATE DATA gr_alv_data TYPE TABLE OF (lv_rel_name).
      ASSIGN gr_alv_data->* TO <ft_table>.

*     Set data to the ALV grid display table
      APPEND INITIAL LINE TO <ft_table> ASSIGNING <fs_table_line>.
      <fs_table_line> = <fs_node_comp_data>.

*   Deep Structure Types: This is applicable for all the deep structures wherein
*   the first component is node followed by further deep and nested data attributes
    ELSEIF lr_type_descr->type_kind = cl_abap_structdescr=>typekind_struct2.

*     Get actual structure reference
      lr_struct_descr ?= lr_type_descr.

*     Get structure components and check for NODE element. This should be available
*     for all the deep structures.
      lt_components = lr_struct_descr->get_components( ).
      READ TABLE lt_components TRANSPORTING NO FIELDS WITH KEY name = 'NODE'.
      IF sy-subrc EQ 0.

*       Get data assoiated with the node
        ASSIGN ms_node_dataref-dataref->* TO <fs_node_data>.

*       Get actual structure reference for the NODE Element
        lr_struct_descr ?= ls_components-type.

*       Create a table type relative to the node data to be displayed
*       Entity/Elements/Joins will have different structures
        lv_rel_name = lr_struct_descr->get_relative_name( ).
        CREATE DATA gr_alv_data TYPE TABLE OF (lv_rel_name).
        ASSIGN gr_alv_data->* TO <ft_table>.

*       Set data to the ALV grid display table
        UNASSIGN <fs_table_line>.
        ASSIGN COMPONENT 'NODE' OF STRUCTURE <fs_node_data> TO <fs_node_comp_data>.

        APPEND INITIAL LINE TO <ft_table> ASSIGNING <fs_table_line>.
        <fs_table_line> = <fs_node_comp_data>.
      ENDIF.


*   Table Types
    ELSEIF ( lr_type_descr->type_kind = cl_abap_structdescr=>typekind_table OR
             lr_type_descr->type_kind = cl_abap_structdescr=>kind_table ).

*     Get tabular data associated with the node
      ASSIGN ms_node_dataref-dataref->* TO <ft_node_data>.

*     Get actual table type reference
      lr_table_descr ?= lr_type_descr.
      DATA(lr_table_line_type) = lr_table_descr->get_table_line_type( ).

*     Get reference to line type for the table
      lr_struct_descr ?= lr_table_line_type.

*     Flat Structure Types
      IF  lr_struct_descr->type_kind EQ cl_abap_structdescr=>typekind_struct1.

        lv_rel_name = lr_struct_descr->get_relative_name( ).
        CREATE DATA gr_alv_data TYPE TABLE OF (lv_rel_name).
        ASSIGN gr_alv_data->* TO <ft_table>.

*       Set data to the ALV grid display table
        LOOP AT <ft_node_data> ASSIGNING <fs_node_data>.
          APPEND INITIAL LINE TO <ft_table> ASSIGNING <fs_table_line>.
          <fs_table_line> = <fs_node_data>.
        ENDLOOP.

*     Deep Structure Types
      ELSEIF lr_struct_descr->type_kind EQ cl_abap_structdescr=>typekind_struct2.

*       Get structure components and check for NODE element. This should be available
*       for all the deep structures.
        lt_components = lr_struct_descr->get_components( ).
        READ TABLE lt_components INTO ls_components WITH KEY name = 'NODE'.
        IF sy-subrc EQ 0.

*         Get actual structure reference for the NODE Element
          lr_struct_descr ?= ls_components-type.

*         Create a table type relative to the node data to be displayed
*         Entity/Elements/Joins will have different structures
          lv_rel_name = lr_struct_descr->get_relative_name( ).
          CREATE DATA gr_alv_data TYPE TABLE OF (lv_rel_name).
          ASSIGN gr_alv_data->* TO <ft_table>.

*         Set data to the ALV grid display table
          LOOP AT <ft_node_data> ASSIGNING <fs_node_data>.
            UNASSIGN <fs_table_line>.
            ASSIGN COMPONENT 'NODE' OF STRUCTURE <fs_node_data> TO <fs_node_comp_data>.

            APPEND INITIAL LINE TO <ft_table> ASSIGNING <fs_table_line>.
            <fs_table_line> = <fs_node_comp_data>.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.

*   Now that the ALV display table is created with the relevant content
*   we would need to create the fieldcatalog
*    TRY.
    CALL METHOD cl_salv_table=>factory
      IMPORTING
        r_salv_table = DATA(lr_salv_table)
      CHANGING
        t_table      = <ft_table>.
*     CATCH cx_salv_msg .
*    ENDTRY.

    DATA(lr_columns)      = lr_salv_table->get_columns( ).
    DATA(lr_aggregations) = lr_salv_table->get_aggregations( ).

*   Get Fieldcatalog
    CALL METHOD cl_salv_controller_metadata=>get_lvc_fieldcatalog
      EXPORTING
        r_columns      = lr_columns
        r_aggregations = lr_aggregations
      RECEIVING
        t_fieldcatalog = gt_fieldcatalog.

*   Enhance the fieldcatalog
    LOOP AT gt_fieldcatalog ASSIGNING FIELD-SYMBOL(<fs_fieldcatalog>).
*     Set as Checkbox
      IF <fs_fieldcatalog>-domname = 'ABAP_BOOL'.
        <fs_fieldcatalog>-checkbox = abap_true.
      ENDIF.

*     Optimize Column Width
      <fs_fieldcatalog>-col_opt = abap_true.

*     Set field is editable
      <fs_fieldcatalog>-edit       = is_field_editable( <fs_fieldcatalog>-fieldname ).
      <fs_fieldcatalog>-f4availabl = is_f4_required( <fs_fieldcatalog>-fieldname ).
    ENDLOOP.
  ENDMETHOD.


  method UPDATE_NODE_DATA_FROM_ALV.


  endmethod.


  METHOD VALIDATE_ASSOCIATIONS.
*  Validate Association source is not repeated in this view
*  Validate Association Name is not repeated in this view
*  Validate Association source is not already available in the stack
*  Validate Cardinality is provided
*  Validate Association Source not in Join
*  Validate Association Source not same as main entity data source
    BREAK-POINT.
  ENDMETHOD.


  METHOD validate_changed_data.

  ENDMETHOD.


  METHOD VALIDATE_ELEMENTS.

* Validation for at least one key
* validation for atleast one selection or addition of * as selection
* Validate Group by has Is Selected also set as true
  BREAK-POINT.

  ENDMETHOD.


  METHOD VALIDATE_ENTITY.

* Check Entity Name Duplicate and Length restrictions
* Source Type T is not allowed
* Check Parent DDL Name for Source Type Extend
* Check AMDP Class Name for Table Function
    BREAK-POINT.
  ENDMETHOD.


  METHOD VALIDATE_JOINS.
*  Validate Join source is not repeated in this view
*  Validate Join alias is not repeated in this view
*  Validate Join source is not already available in the stack
*  Validate Join Type is provided
*  Validate join Source not in Association
*  Validate Join Source not same as main entity data

    BREAK-POINT.
  ENDMETHOD.


  METHOD VALIDATE_PARAMETERS.

  BREAK-POINT.

  ENDMETHOD.


  METHOD VALIDATE_REF_CONSTRAINTS.

    BREAK-POINT.

  ENDMETHOD.


  METHOD VALIDATE_SEL_CONSTRAINTS.

    BREAK-POINT.

  ENDMETHOD.
ENDCLASS.
