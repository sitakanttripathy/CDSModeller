*----------------------------------------------------------------------*
***INCLUDE LZFG_CDS_MODELLER_UIF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form INSTANTIATE_VIEW_BUILDER
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM instantiate_view_builder .

* Instantiate View Builder
  IF gr_view_builder IS NOT BOUND.
    gr_view_builder = zcl_cds_view_builder_tree=>get_instance( EXPORTING iv_cont_name = 'CONT_VB' ) .
  ENDIF.

* Instantiate View Builder Grid
  IF gr_view_builder_grid IS NOT BOUND.
    gr_view_builder_grid =
        zcl_cds_view_builder_grid=>get_instance(
          EXPORTING
            iv_cont_name = 'CONT_VB_DETAILS'
            ir_tree      = gr_view_builder ).
  ENDIF.

* Instantiate CDS Annotation Tree
  IF gr_cds_annot_tree IS NOT BOUND.
    gr_cds_annot_tree =
        zcl_cds_annot_tree=>get_instance(
        EXPORTING
          iv_cont_name    = 'CONT_ANNOT'
          ir_view_builder_tree = gr_view_builder ).
  ENDIF.

* Instantiate Annotation Grid
  IF gr_cds_annot_grid IS NOT BOUND.
    gr_cds_annot_grid =
      zcl_cds_annot_grid=>get_instance(
      EXPORTING
        iv_cont_name  = 'CONT_ANNOT_ATTR'
        ir_annot_tree = gr_cds_annot_tree ).
  ENDIF.

* Display View Builder Tree
  CALL METHOD gr_view_builder->display_tree( ).

* Display node details
  CALL METHOD gr_view_builder_grid->display_grid( ).

* Display Annotation Tree
  CALL METHOD gr_cds_annot_tree->display_tree( ).

* Display Annotation Grid
  CALL METHOD gr_cds_annot_grid->display_grid( ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form USER_COMMAND_9000
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM user_command_9000 .
* Dispatch Events
  CALL METHOD cl_gui_cfw=>dispatch.
* Check for changed data in View Builder Grid
  CALL METHOD gr_view_builder_grid->check_data_changed( ).
* Handling needs to be done in the UI and Model classes
  CALL METHOD gr_view_builder->handle_events( sy-ucomm ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form POPULATE_METADATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM select_table_view_fields.

  DATA:
    lv_source         TYPE char16,
    lv_refresh_grid   TYPE abap_bool,
    lt_sel_field      TYPE slis_selfield,
    ls_fieldlist_mark TYPE ty_field_list.

* Show fields for Tables and Views data Source
  IF gs_data_source-tbma_val IS NOT INITIAL.
    lv_source = gs_data_source-tbma_val.
  ELSEIF gs_data_source-vima_val IS NOT INITIAL.
    lv_source = gs_data_source-vima_val.
  ENDIF.

  IF lv_source IS NOT INITIAL.
*   Get Field List details
    DATA(lt_fieldlist) =
    CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( lv_source ) )->get_ddic_field_list( ).

*   Check for changes
    IF lt_fieldlist NE gt_fieldlist.
*     Source has changed: Grid references to be re-instantiated
      lv_refresh_grid = abap_true.
      gt_fieldlist = lt_fieldlist.
      REFRESH gt_fieldlist_mark.
    ELSE.
*     Source hasn't changed: Grid references can stay the same
    ENDIF.

    IF gt_fieldlist IS NOT INITIAL.

*     Set Fiedlist with Select Marking
      LOOP AT gt_fieldlist INTO DATA(ls_fieldlist).
        MOVE-CORRESPONDING ls_fieldlist TO ls_fieldlist_mark.
        APPEND ls_fieldlist_mark TO gt_fieldlist_mark.
      ENDLOOP.


*     Instantiate ALV Grid only when required
      IF lv_refresh_grid IS NOT INITIAL.

        cl_salv_table=>factory(
            EXPORTING
              r_container    = gr_selection_cont
              container_name = 'SELECTION'
            IMPORTING
              r_salv_table   = gr_selection_grid
            CHANGING
              t_table        = gt_fieldlist_mark ).

*       Optimize Columns
        DATA(lr_columns) = gr_selection_grid->get_columns( ).
        CALL METHOD lr_columns->set_optimize( abap_true ).

*       Set Functions
        DATA(lr_functions) = gr_selection_grid->get_functions( ).
        CALL METHOD lr_functions->set_all( abap_true ).

*       Get Columns and set selection as checkbox
        DATA(lr_alv_column) = gr_selection_grid->get_columns( ).
        DATA(lr_column_sel) = CAST cl_salv_column_table( lr_alv_column->get_column( 'MARK' ) ).
        CALL METHOD lr_column_sel->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).

*       Set Event
        DATA(lr_events) = gr_selection_grid->get_event( ).
        CREATE OBJECT gr_grid_events.
        SET HANDLER gr_grid_events->on_link_click FOR lr_events.

*       Display Selection Fields
        CALL METHOD gr_selection_grid->display( ).
*      ELSE.
**       Set New Data Tables for ALV Grid
*        CALL METHOD gr_selection_grid->set_data( CHANGING t_table = gt_fieldlist_mark ).
*        CALL METHOD gr_selection_grid->refresh.
      ENDIF.
    ENDIF.
  ENDIF.

* Show Associations and Elements for the
  IF gs_data_source-ddl_source IS NOT INITIAL.


  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INSTANTIATE_SELECTIONS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM instantiate_selections .

* Check if details are required
  CHECK gv_no_details IS INITIAL.

* Instantiate Container
  IF ( gs_data_source-tbma_val   IS NOT INITIAL OR
       gs_data_source-vima_val   IS NOT INITIAL OR
       gs_data_source-ddl_source IS NOT INITIAL )
  AND gr_selection_cont IS INITIAL.
    CREATE OBJECT gr_selection_cont
      EXPORTING
        container_name              = 'SELECTION'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.

* Display Fieldlist on the ALV Grid
  IF ( gs_data_source-tbma_val   IS NOT INITIAL OR
       gs_data_source-vima_val   IS NOT INITIAL ).

    PERFORM select_table_view_fields.

* Display Associations Drill Down and Element Details
  ELSEIF gs_data_source-ddl_source IS NOT INITIAL.
    PERFORM select_associations.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_SOURCE_CHANGE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_source_change .
  DATA:
    lv_confirm TYPE abap_bool,
    lv_answer  TYPE abap_bool.

* Table Source Selected
  IF gs_source_type-table IS NOT INITIAL.

*   Check if any of the table or CDS are populated
*   Source is being changed, needs warning
    IF gs_data_source-vima_val    IS NOT INITIAL
    OR gs_data_source-ddl_source  IS NOT INITIAL.
      lv_confirm = abap_true.
    ENDIF.

* View Source Selected
  ELSEIF gs_source_type-view IS NOT INITIAL.

*   Check if any of the table or CDS are populated
*   Source is being changed, needs warning
    IF gs_data_source-tbma_val      IS NOT INITIAL
    OR gs_data_source-ddl_source IS NOT INITIAL.
      lv_confirm = abap_true.
    ENDIF.

* DDL Source Selected
  ELSEIF gs_source_type-cds IS NOT INITIAL.

*   Check if any of the table or CDS are populated
*   Source is being changed, needs warning
    IF gs_data_source-tbma_val IS NOT INITIAL
    OR gs_data_source-ddl_source  IS NOT INITIAL.
      lv_confirm = abap_true.
    ENDIF.
  ENDIF.

  IF lv_confirm IS NOT INITIAL.
*   Confirm Source Type Change
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

*     Check and process answer
      IF lv_answer EQ 1.  "User wants to change
*       Set new Source Type and clear other sources
        IF gs_source_type-table IS NOT INITIAL.
          gv_source_type = 'T'. " Source Type Table
*       View Source Selected
        ELSEIF gs_source_type-view IS NOT INITIAL.
          gv_source_type = 'V'. "Source Type View
*       DDL Source Selected
        ELSEIF gs_source_type-cds IS NOT INITIAL.
          gv_source_type = 'D'. " Source Type DDL
        ENDIF.

*       Free Containers and Controls
        FREE gr_selection_grid.
        FREE gr_selection_tree.
        CALL METHOD gr_selection_cont->free( ).
        FREE gr_selection_cont.

        CLEAR: gt_selection_tree, gt_fieldlist, gt_fieldlist_mark.

*     User doesnot want to change or cancelled
      ELSEIF lv_answer EQ 2
      OR     lv_answer IS INITIAL.
*       Set Source Type prior to change
        CLEAR gs_source_type.
        CASE gv_source_type.
*         Table
          WHEN 'T'.
            gs_source_type-table = abap_true.
*         View
          WHEN 'V'.
            gs_source_type-view = abap_true.
*         DDL Source
          WHEN 'D'.
            gs_source_type-cds = abap_true.
        ENDCASE.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SELECT_ASSOCIATIONS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM select_associations .

* Instantiate Tree
  IF gr_selection_tree IS NOT BOUND.
    TRY.
        CALL METHOD cl_salv_tree=>factory
          EXPORTING
            r_container = gr_selection_cont
          IMPORTING
            r_salv_tree = gr_selection_tree
          CHANGING
            t_table     = gt_selection_tree.
      CATCH cx_salv_error .
    ENDTRY.
  ENDIF.

* Build Header
  DATA(lr_settings) = gr_selection_tree->get_tree_settings( ).
  CALL METHOD lr_settings->set_hierarchy_header( TEXT-006 ).
  CALL METHOD lr_settings->set_hierarchy_tooltip( TEXT-006 ).
  CALL METHOD lr_settings->set_hierarchy_size( 30 ).

* Populate Nodes and Items for Tree
  PERFORM build_tree_nodes_items.

*       Set Functions
  DATA(lr_functions) = gr_selection_tree->get_functions( ).
  CALL METHOD lr_functions->set_all( abap_true ).

* Optimize Columns
  DATA(lr_columns) = gr_selection_tree->get_columns( ).
  lr_columns->set_optimize( abap_true ).

* Set Node Key as Invisible
  DATA(lr_column) = CAST cl_salv_column_tree( lr_columns->get_column( 'NODE_KEY' ) ).
  lr_column->set_technical( abap_true ).
* Set Select as invisible
  lr_column = CAST cl_salv_column_tree( lr_columns->get_column( 'SELECT' ) ).
  lr_column->set_technical( abap_true ).

* Set Event Handler
  DATA(lr_events) = gr_selection_tree->get_event( ).
  CREATE OBJECT gr_grid_events.
  SET HANDLER gr_grid_events->on_expand_empty_folder FOR lr_events.
  SET HANDLER gr_grid_events->on_checkbox_change     FOR lr_events.

* Display Tree
  CALL METHOD gr_selection_tree->display( ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form BUILD_TREE_NODES_ITEMS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_tree_nodes_items .

* For Core CDS Entity, Associations and Joins wherein DDL
* is source, it should be possible to choose from path expressions
* and relevant elements as field to be exposed within the CDS View
* Also it should be possible to choose multiple at entities at one time

  DATA: ls_assoc_selection TYPE zcds_assoc_selection.

  CHECK gs_data_source-ddl_source IS NOT INITIAL.

** Add the Source DDL as the first node.
*  DATA(lr_nodes) = gr_selection_tree->get_nodes( ).
*  DATA(lr_node) = lr_nodes->add_node( related_node = iv_parent_node
*                                      data_row     = ls_assoc_selection
*                                      text         = 'Associations'
*                                      relationship = cl_gui_column_tree=>relat_last_child ).
*  lr_node->set_expander( abap_true ).
*  DATA(lv_node_key) = lr_node->get_key( ).

* Add Elements of the DDL Source
  ls_assoc_selection-target = gs_data_source-ddl_source.
  IF gv_display_elements EQ abap_true.
    PERFORM add_association_elements USING ls_assoc_selection.
  ENDIF.

* Add Associations of the DDL Source
  IF gv_display_assoc EQ abap_true.
    PERFORM add_associations USING gs_data_source-ddl_source
                                   space.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ADD_ASSOCIATIONS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*      -->P_GS_DATA_SOURCE_DDL_SOURCE  text
*&---------------------------------------------------------------------*
FORM add_associations  USING iv_ddl_source  TYPE ddlname
                             iv_parent_node TYPE salv_de_node_key.

  DATA:
    lv_text            TYPE lvc_value,
    ls_assoc_selection TYPE zcds_assoc_selection.

* Get DDL Metadata
  DATA(lv_ddl_source) = iv_ddl_source.
  TRANSLATE lv_ddl_source TO UPPER CASE.
  DATA(ls_metadata) = cl_sodps_abap_cds_analyzer=>analyze_cds_view( lv_ddl_source ).

  CHECK ls_metadata-tx_association IS NOT INITIAL.

* Add Dummy Node for Association
  DATA(lr_nodes) = gr_selection_tree->get_nodes( ).
  DATA(lr_node) = lr_nodes->add_node( related_node = iv_parent_node
                                      data_row     = ls_assoc_selection
                                      text         = 'Associations'
                                      relationship = cl_gui_column_tree=>relat_last_child ).
  lr_node->set_expander( abap_true ).
  DATA(lv_node_key) = lr_node->get_key( ).

  LOOP AT ls_metadata-tx_association INTO DATA(ls_association).

*   Set table outline
    CLEAR ls_assoc_selection.
    ls_assoc_selection-assoc_name   = ls_association-name.
    ls_assoc_selection-target       = ls_association-target.
    ls_assoc_selection-element_type = Zcl_cds_modeller=>mc_element_type_path. "Path Expressions

*   Add Node
    lr_nodes = gr_selection_tree->get_nodes( ).

    lv_text = ls_assoc_selection-assoc_name.
    lr_node = lr_nodes->add_node( related_node = lv_node_key
                                  data_row     = ls_assoc_selection
                                  text         = lv_text
                                  relationship = cl_gui_column_tree=>relat_last_child ).
    lr_node->set_expander( abap_true ).


*   Check if Selecting Associations is allowed
*   For example with Inserting Elements and Joins Associations
*   are not required: Just select the fields
    IF  gv_select_assoc EQ abap_true.
*     Set Item Checkbox
      DATA(lr_item) = lr_node->get_hierarchy_item( ).
      lr_item->set_type( if_salv_c_item_type=>checkbox ).
      lr_item->set_editable( abap_true ).
    ENDIF.

*   Get Node Key
    ls_assoc_selection-node_key = lr_node->get_key( ).
    APPEND ls_assoc_selection TO gt_selection_tree.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ADD_ASSOCIATION_ELEMENTS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*      -->P_LS_ASSOC_SELECTION  text
*&---------------------------------------------------------------------*
FORM add_association_elements  USING  is_assoc_selection TYPE zcds_assoc_selection.

  DATA:
    lv_text            TYPE lvc_value,
    ls_assoc_selection TYPE zcds_assoc_selection.

  CHECK is_assoc_selection-target IS NOT INITIAL.

* Get DDL Metadata
  DATA(lv_ddl_source) = is_assoc_selection-target.
  TRANSLATE lv_ddl_source TO UPPER CASE.
  DATA(ls_metadata) = cl_sodps_abap_cds_analyzer=>analyze_cds_view( lv_ddl_source ).

  CHECK ls_metadata-tx_field IS NOT INITIAL.

* Set Dummy Element Node
  DATA(lr_nodes) = gr_selection_tree->get_nodes( ).
  DATA(lr_node) = lr_nodes->add_node( related_node = is_assoc_selection-node_key
                                      data_row     = ls_assoc_selection
                                      text         = 'Elements'
                                      relationship = cl_gui_column_tree=>relat_last_child ).
  lr_node->set_expander( abap_true ).
  DATA(lv_node_key) = lr_node->get_key( ).

* Add Inidividual Fields
  LOOP AT ls_metadata-tx_field INTO DATA(ls_field).
*   Set table outline
    CLEAR ls_assoc_selection.
    ls_assoc_selection-fieldname    = ls_field-name.
    ls_assoc_selection-element_type = zcl_cds_modeller=>mc_element_type_field. "Fields
*   Add Node
    lr_nodes = gr_selection_tree->get_nodes( ).
    lv_text  = ls_assoc_selection-fieldname.
    lr_node  = lr_nodes->add_node( related_node = lv_node_key
                                   data_row     = ls_assoc_selection
                                   text         = lv_text
                                   relationship = cl_gui_column_tree=>relat_last_child ).

*   Set Item Checkbox
    IF gv_select_elements EQ abap_true.
      DATA(lr_item) = lr_node->get_hierarchy_item( ).
      lr_item->set_type( if_salv_c_item_type=>checkbox ).
      lr_item->set_editable( abap_true ).
    ENDIF.

    ls_assoc_selection-assoc_name = is_assoc_selection-assoc_name.
    ls_assoc_selection-target     = is_assoc_selection-target.

*   Get Node Key
    ls_assoc_selection-node_key = lr_node->get_key( ).
    APPEND ls_assoc_selection TO gt_selection_tree.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_SELECTION_CONTEXT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_selection_context .

* Set Display and Selection Context for individual node types
  CASE gv_req_node_type.
*   Main View Node
    WHEN zcl_cds_modeller=>mc_node_type_v.
      gv_display_assoc    = abap_true.
      gv_display_elements = abap_true.
      gv_select_assoc     = abap_true.
      gv_select_elements  = abap_true.
*   Element Node
    WHEN zcl_cds_modeller=>mc_node_type_e.
      gv_display_assoc    = abap_true.
      gv_display_elements = abap_true.
      gv_select_assoc     = abap_true.
      gv_select_elements  = abap_true.
*   Association Node
    WHEN zcl_cds_modeller=>mc_node_type_a.
      gv_no_details = abap_true.
*      gv_display_assoc    = abap_true.
*      gv_display_elements = abap_false.
*      gv_select_assoc     = abap_true.
*      gv_select_elements  = abap_false.
*   Join Node
    WHEN zcl_cds_modeller=>mc_node_type_j.
      gv_no_details = abap_true.
*      gv_display_assoc    = abap_true.
*      gv_display_elements = abap_false.
*      gv_select_assoc     = abap_true.
*      gv_select_elements  = abap_false.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_all .

  CLEAR: gv_display_assoc, gv_display_elements,
         gv_select_assoc,  gv_select_elements, gv_no_details.

  CLEAR: gv_event,       gv_cancelled,      gv_req_node_type,
         gv_source_type, gs_ddddlsource,    gs_data_source,
         gt_fieldlist,   gt_fieldlist_mark, gt_selection_tree.


  FREE: gr_grid_events, gr_selection_grid, gr_selection_tree.
* Free Container
  IF gr_selection_cont IS BOUND.
    gr_selection_cont->free( ).
    FREE gr_selection_cont.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_UPDATES
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_updates CHANGING cv_return TYPE abap_bool.

* Check if details are required
  CHECK gv_no_details IS INITIAL.

* Check and update selected fields for Tables and View Sources
  IF ( gs_data_source-tbma_val   IS NOT INITIAL OR
       gs_data_source-vima_val   IS NOT INITIAL ).
*   Check if elments have been selected
    READ TABLE gt_fieldlist_mark TRANSPORTING NO FIELDS
                                 WITH KEY mark = abap_true.
    IF sy-subrc NE 0.
      MESSAGE i004(zcds_messages) WITH 'Please select relevant details to include into CDS View'.
      cv_return = abap_true.
    ELSE.
      LOOP AT gt_fieldlist_mark INTO DATA(ls_fieldlist_mark)
                                WHERE mark IS NOT INITIAL.
        INSERT ls_fieldlist_mark-fieldname INTO TABLE gs_data_source-fieldlist .
      ENDLOOP.
    ENDIF.
  ENDIF.

* Check and Update fields and associations from DDL Sources
  IF gs_data_source-ddl_source IS NOT INITIAL.
    READ TABLE gt_selection_tree TRANSPORTING NO FIELDS
         WITH KEY select = abap_true.
    IF sy-subrc NE 0.
      MESSAGE i004(zcds_messages) WITH 'Please select relevant details to include into CDS View'.
      cv_return = abap_true.
    ELSE.
      LOOP AT gt_selection_tree INTO DATA(ls_selection_tree)
                                WHERE select IS NOT INITIAL.
        APPEND ls_selection_tree TO gs_data_source-assoc.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDFORM.
