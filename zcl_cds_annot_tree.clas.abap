class ZCL_CDS_ANNOT_TREE definition
  public
  final
  create protected .

public section.

  types:
    BEGIN OF ty_node_annot_details,
             node_key    TYPE tv_nodekey,
             is_array    TYPE abap_bool,
             annotations TYPE cl_ddl_annot_def_parser=>tt_annot_def,
           END OF ty_node_annot_details .
  types:
    tt_node_annot_details TYPE STANDARD TABLE OF ty_node_annot_details WITH KEY node_key .

  data MR_ANNOT_BIBLE type ref to ZCL_CDS_ANNOT_BIBLE .
  data MR_VIEW_BUILDER_TREE type ref to ZCL_CDS_VIEW_BUILDER_TREE .

  class-methods GET_INSTANCE
    importing
      !IV_CONT_NAME type CHAR30
      !IR_VIEW_BUILDER_TREE type ref to ZCL_CDS_VIEW_BUILDER_TREE
    returning
      value(ER_ANNOT_TREE) type ref to ZCL_CDS_ANNOT_TREE .
  methods DISPLAY_TREE .
  methods GET_NODE_TO_SCOPE
    returning
      value(EV_ANNOT_SCOPE) type STRING .
  methods GET_SELECTED_NODE
    returning
      value(EV_NODE_KEY) type TV_NODEKEY .
  methods GET_NODE_ANNOTATIONS
    importing
      !IV_NODE_KEY type TV_NODEKEY
    returning
      value(ES_NODE_ANNOTATIONS) type TY_NODE_ANNOT_DETAILS .
protected section.

  class-data MR_CDS_ANNOT_TREE type ref to ZCL_CDS_ANNOT_TREE .

  methods CONSTRUCTOR
    importing
      !IV_CONT_NAME type CHAR30
      !IR_VIEW_BUILDER_TREE type ref to ZCL_CDS_VIEW_BUILDER_TREE optional .
private section.

  data MS_ANNOT_DEFS_SCOPED type ZCL_CDS_ANNOT_BIBLE=>TY_ANNOT_SCOPES .
  class-data MR_TREE type ref to CL_GUI_LIST_TREE .
  class-data MR_CONTAINER type ref to CL_GUI_CUSTOM_CONTAINER .
  class-data MV_CONT_NAME type CHAR30 .
  data MT_NODES type TREEV_NTAB .
  data MT_ITEMS type IWB_MTREEITM .
  data MV_CURRENT_NODE type TV_NODEKEY .
  data MS_VB_NODE_DETAILS type ZCDS_VIEW_TREE_NODES .
  data MS_VB_ITEM_DETAILS type MTREEITM .
  data MS_VB_NODE_DATAREF type ZCL_CDS_VIEW_BUILDER_TREE=>TY_NODE_DATAREF .
  data MV_NODE_INDEX type SY-INDEX .
  data MV_CURRENT_SCOPE type STRING .
  data MT_NODE_ANNOT_DETAILS type TT_NODE_ANNOT_DETAILS .
  data MT_EXPANDED_NODES type TREEV_NKS .

  methods REGISTER_EVENTS .
  methods BUILD_NODES_ITEMS .
  methods HANDLE_NODE_DOUBLE_CLICK
    for event NODE_DOUBLE_CLICK of CL_GUI_LIST_TREE
    importing
      !NODE_KEY .
  methods HANDLE_ITEM_DOUBLE_CLICK
    for event ITEM_DOUBLE_CLICK of CL_GUI_LIST_TREE
    importing
      !NODE_KEY
      !ITEM_NAME .
  methods REBUILD_NODES_ITEMS .
  methods ADD_CHILD_ANNOT_NODES
    importing
      !IV_PARENT_NODE type TV_NODEKEY
      !IV_PARENT_TOKEN type INT4 optional
      !IV_PARENT_ANNOTKEY type STRING
      !IT_ANNOTATIONS type CL_DDL_ANNOT_DEF_PARSER=>TT_ANNOT_DEF .
ENDCLASS.



CLASS ZCL_CDS_ANNOT_TREE IMPLEMENTATION.


  METHOD add_child_annot_nodes.

    DATA:
      ls_node               TYPE treev_node,
      ls_item               TYPE mtreeitm,
      lv_append_node        TYPE xflag,
      lv_parent_node        TYPE tv_nodekey,
      ls_node_annot_details TYPE ty_node_annot_details.

    LOOP AT it_annotations INTO DATA(ls_annotations)
                           WHERE parent_token_index = iv_parent_token
                           AND  ( type IS INITIAL OR is_array IS NOT INITIAL ).
*     Set Node Details
      CLEAR ls_node.
      ls_node-node_key  = mv_node_index = mv_node_index + 1.
      ls_node-relatkey  = iv_parent_node.
      ls_node-relatship = cl_gui_list_tree=>relat_last_child.
*     Check if current token has any child
      READ TABLE it_annotations TRANSPORTING NO FIELDS
           WITH KEY parent_token_index = ls_annotations-token_index.
      IF sy-subrc EQ 0.
        ls_node-isfolder  = abap_true.
      ENDIF.

*     Set Icon for Array Annotation
      IF ls_annotations-is_array IS NOT INITIAL.
        ls_node-n_image   = icon_alv_variants.
        ls_node-exp_image = icon_alv_variants.
      ELSE.
*       Check if this is a dummy node
        LOOP AT it_annotations TRANSPORTING NO FIELDS
                               WHERE parent_token_index = ls_annotations-token_index
                               AND   ( type IS NOT INITIAL AND is_array IS INITIAL ).
          EXIT.
        ENDLOOP.
        IF sy-subrc NE 0 .
          ls_node-n_image   = icon_annotation.
          ls_node-exp_image = icon_annotation.
        ELSE.
          ls_node-n_image   = icon_structure.
          ls_node-exp_image = icon_structure.
        ENDIF.
      ENDIF.
      APPEND ls_node TO mt_nodes.

*     Set Item Details
      CLEAR ls_item.
      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 1.
      ls_item-class     = cl_gui_list_tree=>item_class_text.
      ls_item-alignment = cl_gui_list_tree=>align_auto.
      ls_item-font      = cl_gui_list_tree=>item_font_prop.
      ls_item-text      = ls_annotations-key.
      APPEND ls_item TO mt_items.

*     If this node does not have any child but is still a valid annotation which
*     required a value then this needs to be taken care of
      IF ls_annotations-type IS NOT INITIAL.
        CLEAR ls_node_annot_details.
        ls_node_annot_details-node_key = ls_node-node_key.
        ls_node_annot_details-is_array = ls_annotations-is_array.
        APPEND ls_annotations TO ls_node_annot_details-annotations.
        APPEND ls_node_annot_details TO mt_node_annot_details.
      ENDIF.

*     Set the Child Annotations for this node. This will be used later
*     to display grid details relevant to the node
      DATA(lt_child_annot) = it_annotations.
      DELETE lt_child_annot WHERE parent_token_index NE ls_annotations-token_index.
      DELETE lt_child_annot WHERE type IS INITIAL.

      IF lt_child_annot IS NOT INITIAL.
        CLEAR ls_node_annot_details.
        ls_node_annot_details-node_key  = ls_node-node_key.
        ls_node_annot_details-is_array  = ls_annotations-is_array.
        APPEND LINES OF lt_child_annot TO ls_node_annot_details-annotations.
        APPEND ls_node_annot_details TO mt_node_annot_details.
      ENDIF.
*     Add further child annotations
      CALL METHOD add_child_annot_nodes(
        EXPORTING
          iv_parent_node     = ls_node-node_key
          iv_parent_token    = ls_annotations-token_index
          iv_parent_annotkey = ls_annotations-key
          it_annotations     = it_annotations ).
    ENDLOOP.
  ENDMETHOD.


  METHOD build_nodes_items.

    DATA:
      ls_node TYPE treev_node,
      ls_item TYPE mtreeitm.

    REFRESH: mt_nodes,mt_items,mt_node_annot_details.
    CLEAR mv_node_index.

*   Get Current Node and relevant details
    DATA(lv_current_node) = mr_view_builder_tree->get_current_node( ).
    CALL METHOD mr_view_builder_tree->get_node_details(
      EXPORTING
        iv_node_key     = lv_current_node
      IMPORTING
        es_node_details = ms_vb_node_details
        es_item_details = ms_vb_item_details
        es_node_dataref = ms_vb_node_dataref ).

    CHECK lv_current_node IS NOT INITIAL.

*   Get Annotation Scope
    mv_current_scope = get_node_to_scope( ).

*   Get Annotations relevant to the scope
    ms_annot_defs_scoped = mr_annot_bible->get_scoped_annotations( mv_current_scope ).

    LOOP AT ms_annot_defs_scoped-annot INTO DATA(ls_annot_scoped).

*     Set Node Details
      CLEAR ls_node.
      ls_node-node_key  = mv_node_index = mv_node_index + 1.
      ls_node-relatship = cl_gui_list_tree=>relat_last_child.
      ls_node-n_image   = icon_annotation.
      ls_node-exp_image = icon_annotation.
      IF ls_annot_scoped-linear_defs IS NOT INITIAL.
        ls_node-isfolder  = 'X'.
      ENDIF.

      APPEND ls_node TO mt_nodes.

*     Set Item Details
      CLEAR ls_item.
      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 1.
      ls_item-class     = cl_gui_list_tree=>item_class_text.
      ls_item-alignment = cl_gui_list_tree=>align_auto.
      ls_item-font      = cl_gui_list_tree=>item_font_prop.
      ls_item-text      = ls_annot_scoped-annot-annotation_raw.
      APPEND ls_item TO mt_items.

*     Add child nodes and Items
      CALL METHOD add_child_annot_nodes(
        EXPORTING
          iv_parent_node     = ls_node-node_key
          iv_parent_annotkey = ls_annot_scoped-annot-annotation_raw
          it_annotations     = ls_annot_scoped-linear_defs ).
    ENDLOOP.
  ENDMETHOD.


  METHOD constructor.
    mr_view_builder_tree = ir_view_builder_tree.
    mv_cont_name         = iv_cont_name.

*   Get reference of Annotation Bible
    mr_annot_bible = zcl_cds_annot_bible=>get_instance( ).
  ENDMETHOD.


  METHOD display_tree.
*   Instantiate Container
    IF mr_container IS NOT BOUND..
      CREATE OBJECT mr_container
        EXPORTING
          container_name              = mv_cont_name
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5.
      IF sy-subrc <> 0.
*       Exception Handling
      ENDIF.
    ENDIF.

*   Instantiate Tree Control
    IF mr_tree IS NOT BOUND.
      CREATE OBJECT mr_tree
        EXPORTING
          parent                      = mr_container
          node_selection_mode         = cl_gui_list_tree=>node_sel_mode_single
          item_selection              = 'X'
          with_headers                = ' '
        EXCEPTIONS
          cntl_system_error           = 1
          create_error                = 2
          failed                      = 3
          illegal_node_selection_mode = 4
          lifetime_error              = 5.
      IF sy-subrc <> 0.
*       Exception Handling
      ENDIF.

*     Register Events
      CALL METHOD me->register_events.
*     Build Nodes and Items
      CALL METHOD me->build_nodes_items.
*     Render Nodes and Items
      CALL METHOD mr_tree->add_nodes_and_items
        EXPORTING
          node_table                     = mt_nodes
          item_table                     = mt_items
          item_table_structure_name      = 'MTREEITM'
        EXCEPTIONS
          failed                         = 1
          cntl_system_error              = 3
          error_in_tables                = 4
          dp_error                       = 5
          table_structure_name_not_found = 6.
      IF sy-subrc <> 0.
      ENDIF.
    ELSE.
*     Refresh and build Nodes and Items
      CALL METHOD me->build_nodes_items.
      CALL METHOD me->rebuild_nodes_items.
    ENDIF.

*   Set expanded nodes
    CALL METHOD mr_tree->expand_nodes( mt_expanded_nodes ).
*   Flush Automation Queue
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
*   Instantiate if required
    IF mr_cds_annot_tree IS NOT BOUND.
      CREATE OBJECT mr_cds_annot_tree
        EXPORTING
          iv_cont_name         = iv_cont_name
          ir_view_builder_tree = ir_view_builder_tree.
    ENDIF.
*   Pass reference
    er_annot_tree = mr_cds_annot_tree.
  ENDMETHOD.


  METHOD get_node_annotations.
*   Pass the entire node and annotation details
    READ TABLE mt_node_annot_details INTO es_node_annotations
         WITH KEY node_key = iv_node_key.
  ENDMETHOD.


  METHOD get_node_to_scope.
    FIELD-SYMBOLS:
      <fs_view_node>  TYPE zcds_view_entity.

*   Set Scoped for Nodes Types
    CASE ms_vb_node_details-node_type.
*     Node Type View
      WHEN zcl_cds_modeller=>mc_node_type_v.
*       For the View Node, we need to understand the source type
*       like view/extend view/Table Function
        ASSIGN ms_vb_node_dataref-dataref->* TO <fs_view_node>.
*       Check for Source Type
        CASE <fs_view_node>-source_type.
*         Core View
          WHEN 'V'.
            ev_annot_scope = 'VIEW'.
*         Extend View
          WHEN 'E'.
            ev_annot_scope = 'EXTEND_VIEW'.
*         Table Function
          WHEN 'F'.
            ev_annot_scope = 'TABLE_FUNCTION'.
        ENDCASE.

*     Node Type Element
      WHEN zcl_cds_modeller=>mc_node_type_e.
        ev_annot_scope = 'ELEMENT'.

*     Node Type Parameter
      WHEN zcl_cds_modeller=>mc_node_type_p.
        ev_annot_scope = 'PARAMETER'.

*     Other Node Types
      WHEN zcl_cds_modeller=>mc_node_type_a  "Association
      OR   zcl_cds_modeller=>mc_node_type_j  "Joins
      OR   zcl_cds_modeller=>mc_node_type_r  "Referential Constraints
      OR   zcl_cds_modeller=>mc_node_type_s. "Selection Constraints

*       No Scopes Allowed
    ENDCASE.
  ENDMETHOD.


  METHOD get_selected_node.
    ev_node_key = mv_current_node.
  ENDMETHOD.


  METHOD handle_item_double_click.
*   Set event node
    mv_current_node = node_key.
*   Get Expanded Node
    CALL METHOD mr_tree->get_expanded_nodes(
      EXPORTING
        no_hidden_nodes = abap_true
      CHANGING
        node_key_table  = mt_expanded_nodes ).
  ENDMETHOD.


  METHOD handle_node_double_click.
*   Set event node
    mv_current_node = node_key.
*   Get Expanded Node
    CALL METHOD mr_tree->get_expanded_nodes(
      EXPORTING
        no_hidden_nodes = abap_true
      CHANGING
        node_key_table  = mt_expanded_nodes ).
  ENDMETHOD.


  METHOD rebuild_nodes_items.
*   Update Tree Nodes and Items on Front End
    CALL METHOD mr_tree->delete_all_nodes
      EXCEPTIONS
        failed            = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.

*   Add Nodes and Item Tables
    CALL METHOD mr_tree->add_nodes_and_items
      EXPORTING
        node_table                     = mt_nodes
        item_table                     = mt_items
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 2
        error_in_tables                = 3
        dp_error                       = 4
        table_structure_name_not_found = 5
        OTHERS                         = 6.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.
  ENDMETHOD.


  METHOD register_events.
    DATA: lt_events TYPE cntl_simple_events,
          ls_event  TYPE cntl_simple_event.

    " Node Double Click
    ls_event-eventid = cl_gui_list_tree=>eventid_node_double_click.
    ls_event-appl_event = 'X'.
    APPEND ls_event TO lt_events.

    " Item Double Click
    ls_event-eventid = cl_gui_list_tree=>eventid_item_double_click.
    ls_event-appl_event = 'X'.
    APPEND ls_event TO lt_events.

    " Register events
    CALL METHOD mr_tree->set_registered_events
      EXPORTING
        events                    = lt_events
      EXCEPTIONS
        cntl_error                = 1
        cntl_system_error         = 2
        illegal_event_combination = 3.
    IF sy-subrc <> 0.

    ENDIF.

    SET HANDLER handle_node_double_click FOR mr_tree.
    SET HANDLER handle_item_double_click FOR mr_tree.

  ENDMETHOD.
ENDCLASS.
