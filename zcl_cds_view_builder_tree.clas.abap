class ZCL_CDS_VIEW_BUILDER_TREE definition
  public
  final
  create public

  global friends ZCL_CDS_MODELLER .

public section.

  types:
    BEGIN OF ty_node_dataref,
        node_key TYPE tv_nodekey,
        dataref  TYPE REF TO data,
      END OF ty_node_dataref .
  types:
    tt_node_dataref TYPE TABLE OF ty_node_dataref WITH KEY node_key .

  class-data MR_TREE type ref to CL_GUI_LIST_TREE .
  class-data MR_CONTAINER type ref to CL_GUI_CUSTOM_CONTAINER .
  class-data MV_CONT_NAME type CHAR30 .
  class-data MR_STRUCT_REF type ref to CL_ABAP_STRUCTDESCR .
  data MT_NODE_DATAREF type TT_NODE_DATAREF .

  methods CONSTRUCTOR
    importing
      !IV_CONT_NAME type CHAR30 .
  class-methods GET_INSTANCE
    importing
      !IV_CONT_NAME type CHAR30
    returning
      value(ER_VIEW_BUILDER) type ref to ZCL_CDS_VIEW_BUILDER_TREE .
  methods DISPLAY_TREE .
  methods HANDLE_EVENTS
    importing
      !IV_EVENT type SY-UCOMM .
  methods GET_NODE_DETAILS
    importing
      !IV_NODE_KEY type TV_NODEKEY
    exporting
      value(ES_NODE_DETAILS) type ZCDS_VIEW_TREE_NODES
      value(ES_ITEM_DETAILS) type MTREEITM
      !ES_NODE_DATAREF type TY_NODE_DATAREF .
  methods GET_USER_INPUT
    importing
      !IV_CALL_TYPE type SY-UCOMM
      !IV_REQ_NODE_TYPE type Z_DE_NODE_TYPE optional
    exporting
      !ES_DDL_DETAILS type DDDDLSRC
      !EV_CANCELLED type ABAP_BOOL
    changing
      !CS_DATA_SOURCE type ZCDS_DATA_SOURCE_CAPTURE optional .
  methods GET_CURRENT_NODE
    returning
      value(EV_NODE_KEY) type TV_NODEKEY .
  methods GET_MODE
    returning
      value(EV_MODE) type E_MODE .
protected section.
private section.

  data MT_NODES type TREEV_NTAB .
  data MT_ITEMS type IWB_MTREEITM .
  data MT_NODES_NODE_TYPES type ZCDS_TT_VIEW_TREE_NODES .
  class-data MR_VIEW_BUILDER type ref to ZCL_CDS_VIEW_BUILDER_TREE .
  data MV_NODE_INDEX type SY-INDEX .
  data MR_CDS_MODELLER type ref to ZCL_CDS_MODELLER .
  data MR_VIEW_BUILDER_GRID type ref to ZCL_CDS_VIEW_BUILDER_GRID .
  data MV_CURRENT_NODE type TV_NODEKEY .
  data MR_CDS_MODEL type ref to DATA .
  data MT_EXPANDED_NODES type TREEV_NKS .

  methods PUBLISH_NODES_FROM_DATA .
  methods ADD_COMP_NODE
    importing
      !IV_NODE_TYPE type Z_DE_NODE_TYPE
      !IV_PARENT_NODE type TV_NODEKEY
      !IR_NODE_DATA type ref to DATA
    returning
      value(EV_NODE_KEY) type TV_NODEKEY .
  methods ADD_ITEM_NODE
    importing
      !IV_PARENT_NODE type TV_NODEKEY
      !IR_ITEM_DATA type ref to DATA
    exporting
      !EV_NODE_KEY type TV_NODEKEY .
  methods REBUILD_NODES_ITEMS .
  methods REGISTER_EVENTS .
  methods ADD_NODES .
  methods BUILD_NODES_ITEMS .
  methods GET_DEPENDENT_NODE_TYPES
    importing
      !IV_NODE_TYPE type Z_DE_NODE_TYPE
    returning
      value(ET_NODE_TYPE) type ZCDS_TT_CDS_VIEW_NODE_TYPE .
  methods GET_NODE_TYPE_DESCR
    importing
      !IV_NODE_TYPE type Z_DE_NODE_TYPE
    returning
      value(EV_NODE_TYPE_DESCR) type VAL_TEXT .
  methods GET_COMP_TO_NODE_TYPE
    importing
      !IV_COMP_NAME type STRING
    returning
      value(EV_NODE_TYPE) type Z_DE_NODE_TYPE .
  methods PUBLISH_IND_COMP
    importing
      !IR_DATA type ref to DATA
      !IS_COMP_DETAILS type ABAP_COMPONENTDESCR
      !IV_PARENT_NODE type TV_NODEKEY optional
    exporting
      !EV_NODE_KEY type TV_NODEKEY .
  methods HANDLE_NODE_DOUBLE_CLICK
    for event NODE_DOUBLE_CLICK of CL_GUI_LIST_TREE
    importing
      !NODE_KEY .
  methods HANDLE_ITEM_DOUBLE_CLICK
    for event ITEM_DOUBLE_CLICK of CL_GUI_LIST_TREE
    importing
      !NODE_KEY
      !ITEM_NAME .
  methods VALIDATE_MODEL .
ENDCLASS.



CLASS ZCL_CDS_VIEW_BUILDER_TREE IMPLEMENTATION.


  METHOD add_comp_node.
    DATA: ls_node           TYPE treev_node,
          ls_item           TYPE mtreeitm,
          lv_node_type      TYPE z_de_node_type,
          ls_node_dataref   TYPE ty_node_dataref,
          ls_node_node_type TYPE zcds_view_tree_nodes.

*   Set Node Key Details
    CLEAR ls_node.
    ev_node_key = ls_node-node_key  = mv_node_index = mv_node_index + 1.
    ls_node-relatkey  = iv_parent_node.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-isfolder  = 'X'.
    APPEND ls_node TO mt_nodes.

*   For Dummy nodes set the type of the node
*   this will be used later to derive the kind of annotations
*   to be modelled
    CLEAR ls_node_node_type.
    ls_node_node_type-node        = ls_node.
    ls_node_node_type-node_type   = iv_node_type.
    ls_node_node_type-dummy_node  = abap_true.
    APPEND ls_node_node_type TO mt_nodes_node_types.

*   Set the Node and relevant node data reference
*   this will be used to show the details and will
*   be synchronised for every PAI/PBO iteration. Will ease up stuff later
    CLEAR ls_node_dataref.
    READ TABLE mt_node_dataref ASSIGNING FIELD-SYMBOL(<fs_node_dataref>)
                                   WITH KEY node_key = ls_node-node_key.
    IF sy-subrc EQ 0.
      <fs_node_dataref>-dataref  = ir_node_data.
    ELSE.
      ls_node_dataref-node_key = ls_node-node_key.
      ls_node_dataref-dataref  = ir_node_data.
      APPEND ls_node_dataref TO mt_node_dataref.
    ENDIF.


*   Set the Node Item Details
    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = 1.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = get_node_type_descr( iv_node_type ). "Node Type Description
    APPEND ls_item TO mt_items.
  ENDMETHOD.


  METHOD add_item_node.

    DATA: ls_node           TYPE treev_node,
          ls_item           TYPE mtreeitm,
          lv_node_type      TYPE z_de_node_type,
          lv_item_text      TYPE string,
          ls_node_dataref   TYPE ty_node_dataref,
          ls_node_node_type TYPE zcds_view_tree_nodes.

    FIELD-SYMBOLS:
      <fv_item_text>        TYPE any.

    ASSIGN ir_item_data->* TO FIELD-SYMBOL(<fs_item_data>).

    CLEAR ls_node.
    ev_node_key = ls_node-node_key  = mv_node_index = mv_node_index + 1.
    ls_node-relatkey  = iv_parent_node.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-isfolder  = 'X'.

*   Get Parent Node Type
    READ TABLE mt_nodes_node_types INTO DATA(ls_node_types)
         WITH KEY node_key = iv_parent_node.
    IF sy-subrc EQ 0.
      CASE ls_node_types-node_type.
*       Node Type View
        WHEN zcl_cds_modeller=>mc_node_type_v.
          ls_node-n_image   = icon_read_file.
          ls_node-exp_image = icon_read_file.
*          ls_node-style = cl_gui_simple_tree=>style_emphasized_c.
*         Set Node Name to be Displayed
          ASSIGN COMPONENT 'DDL_NAME' OF STRUCTURE <fs_item_data>
                                       TO <fv_item_text>.
*       Node Type Association
        WHEN zcl_cds_modeller=>mc_node_type_a.
          ls_node-n_image   = icon_reference_list.
          ls_node-exp_image = icon_reference_list.
*          ls_node-style = cl_gui_simple_tree=>style_emphasized_c.
*         Set Node Name to be Displayed
          ASSIGN COMPONENT 'SEL_SOURCE' OF STRUCTURE <fs_item_data>
                                        TO <fv_item_text>.
*       Node Type
        WHEN zcl_cds_modeller=>mc_node_type_j.
          ls_node-n_image   = icon_wd_navigation_link.
          ls_node-exp_image = icon_wd_navigation_link.
*          ls_node-style = cl_gui_simple_tree=>style_emphasized_c.
*         Set Node Name to be Displayed
          ASSIGN COMPONENT 'SEL_SOURCE' OF STRUCTURE <fs_item_data>
                                        TO <fv_item_text>.
*       Node Type Element
        WHEN zcl_cds_modeller=>mc_node_type_e.
          ls_node-n_image   = icon_element.
          ls_node-exp_image = icon_element.
*         How Item text as MixedCase
          DATA(lv_mixed) = abap_true.

*         Set Node Name to be Displayed
          ASSIGN COMPONENT 'ELEMENT' OF STRUCTURE <fs_item_data>
                                       TO <fv_item_text>.
*       Node Type Referential Constraint
        WHEN zcl_cds_modeller=>mc_node_type_r.
          ls_node-n_image   = icon_routing_ref_operation.
          ls_node-exp_image = icon_routing_ref_operation.
*         Set Node Name to be Displayed
          ASSIGN COMPONENT 'DEPENDENT_PROPERTY_REF' OF STRUCTURE <fs_item_data>
                                                    TO <fv_item_text>.
*       Node Type Selection Constraint
        WHEN zcl_cds_modeller=>mc_node_type_s.
          ls_node-n_image   = icon_select_with_condition.
          ls_node-exp_image = icon_select_with_condition.
*         Set Node Name to be Displayed
          ASSIGN COMPONENT 'ELEMENT' OF STRUCTURE <fs_item_data>
                                       TO <fv_item_text>.
*       Node Type View Parameters
        WHEN zcl_cds_modeller=>mc_node_type_p.
          ls_node-n_image   = icon_parameter_import.
          ls_node-exp_image = icon_parameter_import.
*         Set Node Name to be Displayed
          ASSIGN COMPONENT 'NAME' OF STRUCTURE <fs_item_data>
                                  TO <fv_item_text>.
      ENDCASE.
    ENDIF.
    APPEND ls_node TO mt_nodes.

*   Set Node Item Details
    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = 1.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    IF <fv_item_text> IS ASSIGNED
    AND lv_mixed      IS NOT INITIAL.
      lv_item_text    = <fv_item_text>.
      ls_item-text    = to_mixed( val  = lv_item_text
                                  sep  = '/' ).
    ELSEIF <fv_item_text> IS ASSIGNED.
      ls_item-text    = <fv_item_text>.
    ENDIF.
    APPEND ls_item TO mt_items.

*   Set the Node and relevant node data reference
*   this will be used to show the details and will
*   be synchronised for every PAI/PBO iteration. Will ease up stff later
    CLEAR ls_node_dataref.
    READ TABLE mt_node_dataref ASSIGNING FIELD-SYMBOL(<fs_node_dataref>)
                                   WITH KEY node_key = ls_node-node_key.
    IF sy-subrc EQ 0.
      <fs_node_dataref>-dataref  = ir_item_data.
    ELSE.
      ls_node_dataref-node_key = ls_node-node_key.
      ls_node_dataref-dataref  = ir_item_data.
      APPEND ls_node_dataref TO mt_node_dataref.
    ENDIF.
  ENDMETHOD.


  method ADD_NODES.
  endmethod.


  METHOD build_nodes_items.

    DATA: ls_node           TYPE treev_node,
          ls_item           TYPE mtreeitm,
          lv_node_type      TYPE z_de_node_type,
          lv_root_node_key  TYPE tv_nodekey,
          ls_node_node_type TYPE zcds_view_tree_nodes.

*   Get CDS Modelling Data
    mr_cds_model = mr_cds_modeller->get_model_data_ref( ).

*   Clean up Nodes and Items tables, needs to be built for every PBO from scratch
    REFRESH: mt_nodes, mt_items,mt_nodes_node_types.
    CLEAR mv_node_index.

*   If CDS Model is blank then we would need to show the udmmy node
    ASSIGN mr_cds_model->* TO FIELD-SYMBOL(<fs_cds_model>).

    IF <fs_cds_model> IS INITIAL.

      REFRESH: mt_nodes, mt_items.

      CLEAR ls_node.
      CLEAR ls_item.

*     Create Root Node and Item
      ls_node-node_key  = lv_root_node_key = mv_node_index = mv_node_index + 1.
      ls_node-isfolder = 'X'.
      APPEND ls_node TO mt_nodes.

      CLEAR ls_node_node_type.
      ls_node_node_type-node = ls_node.
      lv_node_type = ls_node_node_type-node_type = 'V'. "Start with View Entity
      APPEND ls_node_node_type TO mt_nodes_node_types.

      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 1.
      ls_item-class     = cl_gui_list_tree=>item_class_text.
      ls_item-alignment = cl_gui_list_tree=>align_auto.
      ls_item-font      = cl_gui_list_tree=>item_font_prop.
      ls_item-text      = get_node_type_descr( lv_node_type ).
      APPEND ls_item TO mt_items.
    ELSE.
*     Prepare nodes from CDS Model Structure and data
      CALL METHOD publish_nodes_from_data( ).
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
*   Set Cntainer Name
    mv_cont_name = iv_cont_name.
*   Instantiate the Modeller Manager Class
    mr_cds_modeller = NEW zcl_cds_modeller( me ).

*   Describe the Entity Model Metedata
    CALL METHOD cl_abap_structdescr=>describe_by_name
      EXPORTING
        p_name         = 'ZCDS_MODELLING_MODEL'
      RECEIVING
        p_descr_ref    = DATA(lr_abap_typeref)
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ELSE.
      mr_struct_ref ?= lr_abap_typeref.
    ENDIF.
  ENDMETHOD.


  METHOD display_tree.

    DATA:
      lt_outtab         TYPE STANDARD TABLE OF line,
      lt_expanded_nodes TYPE treev_nks.

    " Instantiate Container
    IF mr_container IS NOT BOUND.
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

      ENDIF.
    ENDIF.

    " Instantiate Tree Control
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

      ENDIF.

      " Register Events
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
*     Get expanded nodes
      CALL METHOD mr_tree->get_expanded_nodes
        CHANGING
          node_key_table    = lt_expanded_nodes
        EXCEPTIONS
          cntl_system_error = 1
          dp_error          = 2
          failed            = 3
          OTHERS            = 4.
      IF sy-subrc <> 0.
*     Implement suitable error handling here
      ENDIF.

*     Set expanded nodes if required
      IF lt_expanded_nodes IS INITIAL.
        APPEND INITIAL LINE TO  mt_expanded_nodes
               ASSIGNING FIELD-SYMBOL(<fv_expanded_node>).
        <fv_expanded_node> = mv_current_node.
      ENDIF.
*     Build Nodes and Items
      CALL METHOD me->build_nodes_items.
    ENDIF.
  ENDMETHOD.


  METHOD get_comp_to_node_type.
    CASE iv_comp_name.
*     Set View Node Type
      WHEN 'ENTITY'.
        ev_node_type = zcl_cds_modeller=>mc_node_type_v.
*     Set Elements Node Type
      WHEN 'ELEMENTS'.
        ev_node_type = zcl_cds_modeller=>mc_node_type_e.
*     Set Associations Node Type
      WHEN 'ASSOC'.
        ev_node_type = zcl_cds_modeller=>mc_node_type_a.
*     Set Join Node Type
      WHEN 'JOIN'.
        ev_node_type = zcl_cds_modeller=>mc_node_type_j.
*     Set Referential Constraints Node Type
      WHEN 'REF_CONSTRAINTS'.
        ev_node_type = zcl_cds_modeller=>mc_node_type_r.
*     Set Selection Constraints Node Type
      WHEN 'SEL_CONSTRAINTS'.
        ev_node_type = zcl_cds_modeller=>mc_node_type_s.
*     Set Selection Constraints Node Type
      WHEN 'PARAMETERS'.
        ev_node_type = zcl_cds_modeller=>mc_node_type_p.
    ENDCASE.

  ENDMETHOD.


  METHOD get_current_node.
*   Pass current node
    ev_node_key = mv_current_node.
  ENDMETHOD.


  METHOD get_dependent_node_types.
*   Provide allowed child nodes for a given node type
    CASE iv_node_type.
      WHEN zcl_cds_modeller=>mc_node_type_v.  "View Entity
        APPEND zcl_cds_modeller=>mc_node_type_e TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_a TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_j TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_p TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_s TO et_node_type.
      WHEN zcl_cds_modeller=>mc_node_type_a.  "Associations
        APPEND zcl_cds_modeller=>mc_node_type_a TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_j TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_r TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_s TO et_node_type.
      WHEN zcl_cds_modeller=>mc_node_type_j.  "Joins
        APPEND zcl_cds_modeller=>mc_node_type_r TO et_node_type.
        APPEND zcl_cds_modeller=>mc_node_type_s TO et_node_type.
      WHEN 'R'.	"Referential Constraints
        "No Child Nodes
      WHEN 'S'.	"Selection Constraints
        "No Child Nodes
      WHEN 'E'.	"Elements
        "No Child Nodes
    ENDCASE.
  ENDMETHOD.


  METHOD GET_INSTANCE.

    IF mr_view_builder IS INITIAL.
      mr_view_builder = NEW zcl_cds_view_builder_tree( iv_cont_name ).
    ENDIF.

    er_view_builder = mr_view_builder.

  ENDMETHOD.


  METHOD get_mode.
*   Pass Mode from the CDS Modeller
    ev_mode = mr_cds_modeller->get_mode( ).
  ENDMETHOD.


  METHOD get_node_details.

    DATA: lv_parent_node TYPE tv_nodekey.

*   Pass back the node details
    READ TABLE mt_nodes_node_types INTO es_node_details
         WITH KEY node_key = iv_node_key.
    IF sy-subrc NE 0.
*     Get Node data from core node table
      READ TABLE mt_nodes INTO es_node_details
           WITH KEY node_key = iv_node_key.

*     This is an item leaf node and will not have a node type
*     Hence find out the node type of the immediate parent and
      lv_parent_node = es_node_details-relatkey.

      DO.
*       Get Node Type of the parent Node
        READ TABLE mt_nodes_node_types INTO DATA(ls_node_type_details)
             WITH KEY node_key = lv_parent_node.
*       If Parent Node Not Found: Should Never be for the leaf node
        IF  sy-subrc NE 0.
          EXIT.
        ENDIF.

*       Parent node also does not have a node type. Recurse top
        IF ls_node_type_details-node_type IS INITIAL.
          READ TABLE mt_nodes INTO DATA(ls_nodes)
               WITH KEY node_key = lv_parent_node.
          IF sy-subrc EQ 0.
            lv_parent_node = ls_nodes-node_key.
          ENDIF.
          CONTINUE.
        ENDIF.

        es_node_details-node_type = ls_node_type_details-node_type.
        EXIT.
      ENDDO.
    ENDIF.

*   Pass back the items details
    READ TABLE mt_items INTO es_item_details
         WITH KEY node_key = iv_node_key.

*   Pass back the node data references
    READ TABLE mt_node_dataref INTO es_node_dataref
         WITH KEY node_key = iv_node_key.

  ENDMETHOD.


  METHOD GET_NODE_TYPE_DESCR.

    DATA: lt_dom_values TYPE STANDARD TABLE OF dd07v,
          ls_dom_values TYPE dd07v.

    " Read Node Types
    CALL FUNCTION 'GET_DOMAIN_VALUES'
      EXPORTING
        domname         = 'Z_DM_NODE_TYPE'
      TABLES
        values_tab      = lt_dom_values
      EXCEPTIONS
        no_values_found = 1
        OTHERS          = 2.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ELSE.
      READ TABLE lt_dom_values INTO ls_dom_values
                               WITH KEY domvalue_l = iv_node_type.
      ev_node_type_descr = ls_dom_values-ddtext.
    ENDIF.

  ENDMETHOD.


  METHOD get_user_input.
*   Invoke User input screen
    CALL FUNCTION 'ZFM_GET_USER_INPUT'
      EXPORTING
        iv_call_type     = iv_call_type
        iv_req_node_type = iv_req_node_type
      IMPORTING
        es_ddl_details   = es_ddl_details
        ev_cancelled     = ev_cancelled
      CHANGING
        cs_data_source   = cs_data_source.
  ENDMETHOD.


  METHOD handle_events.

*   Get Expanded Node
    CALL METHOD mr_tree->get_expanded_nodes(
      EXPORTING
        no_hidden_nodes = abap_true
      CHANGING
        node_key_table  = mt_expanded_nodes ).

*   Get Current node key
    CALL METHOD mr_tree->get_selected_item
      IMPORTING
        node_key          = mv_current_node
      EXCEPTIONS
        failed            = 1
        cntl_system_error = 2
        no_item_selection = 3
        OTHERS            = 4.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.


*   Propagate handling to modeller manager
    CALL METHOD mr_cds_modeller->handle_events( iv_event ).
  ENDMETHOD.


  METHOD handle_item_double_click.

*   Validate Model before moving to the next node
    CALL METHOD validate_model.
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

*   Validate Model before moving to the next node
    CALL METHOD validate_model.
*   Set event node
    mv_current_node = node_key.
*   Get Expanded Node
    CALL METHOD mr_tree->get_expanded_nodes(
      EXPORTING
        no_hidden_nodes = abap_true
      CHANGING
        node_key_table  = mt_expanded_nodes ).
  ENDMETHOD.


  METHOD publish_ind_comp.

    DATA:
      lv_index           TYPE sy-tabix,
      lv_parent_node     TYPE tv_nodekey,
      lv_first_comp_node TYPE tv_nodekey,
      lv_object_node_key TYPE tv_nodekey,
      lr_struct_descr    TYPE REF TO cl_abap_structdescr,
      lr_table_descr     TYPE REF TO cl_abap_tabledescr,
      lr_item_node_data  TYPE REF TO data.

    FIELD-SYMBOLS: <fs_data>            TYPE any,
                   <ft_data>            TYPE table,
                   <fs_table_line_data> TYPE any.

*   Annotations need not be published in this node hierarchy
    CHECK is_comp_details-name NE 'ANNOT'.

*   Check if the component is to be published as a node
    DATA(lv_node_type) = get_comp_to_node_type( is_comp_details-name ).

    IF lv_node_type IS NOT INITIAL.
*     Add dummy node for the component
      DATA(lv_comp_node_key) = add_comp_node( EXPORTING iv_node_type   = lv_node_type
                                                        iv_parent_node = iv_parent_node
                                                        ir_node_data   = ir_data ).
    ENDIF.

*   Handle Nested Structure components
    IF is_comp_details-type->type_kind = cl_abap_structdescr=>typekind_struct2.

*     Get Further components of this component
      lr_struct_descr ?= is_comp_details-type.
      DATA(lt_components) = lr_struct_descr->get_components( ).

*     Process the individual components one by one
      LOOP AT lt_components INTO DATA(ls_comp_details).

        lv_index = sy-tabix.

*       Get Reference of data relevant to the current component
        ASSIGN ir_data->* TO <fs_data>.
        ASSIGN COMPONENT ls_comp_details-name
               OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fs_comp_data>).
        GET REFERENCE OF <fs_comp_data> INTO DATA(lr_comp_data).

        DATA(lv_curr_node_key) = lv_comp_node_key.

        CLEAR lv_parent_node.
*       Check if the first component node ic created
        IF lv_first_comp_node IS NOT INITIAL.
          lv_parent_node = lv_first_comp_node.
        ELSE.
*         Parent can be either of the dummy node or the provided parent
          IF lv_comp_node_key IS NOT INITIAL.
            lv_parent_node = lv_comp_node_key.
          ELSE.
            lv_parent_node = iv_parent_node.
          ENDIF.
        ENDIF.

*       Process inidividual component nodes
        CALL METHOD me->publish_ind_comp(
          EXPORTING
            ir_data         = lr_comp_data
            is_comp_details = ls_comp_details
            iv_parent_node  = lv_parent_node
          IMPORTING
            ev_node_key     = lv_object_node_key ).

*       Set the first component node of the complex structure
        IF lv_index EQ 1.
          lv_first_comp_node = lv_object_node_key.
        ENDIF.
      ENDLOOP.

*   Handle Flat Structure Components
    ELSEIF is_comp_details-type->type_kind = cl_abap_structdescr=>kind_struct
    OR     is_comp_details-type->type_kind = cl_abap_structdescr=>typekind_struct1.

*     If this component created a dummy node then that needs to be parent
*     else the parent node available into this method will be parent
      CLEAR lv_parent_node.
      IF lv_comp_node_key IS NOT INITIAL.
        lv_parent_node = lv_comp_node_key.
      ELSE.
        lv_parent_node = iv_parent_node.
      ENDIF.

*     Add Item Detail Node
      CALL METHOD add_item_node(
        EXPORTING
          iv_parent_node = lv_parent_node
          ir_item_data   = ir_data
        IMPORTING
          ev_node_key    = ev_node_key ).

*   Handle Table Type Components
    ELSEIF is_comp_details-type->type_kind = cl_abap_structdescr=>typekind_table.

*     Get Line Type for the table
      lr_table_descr ?= is_comp_details-type.
      DATA(lr_table_line_descr) = lr_table_descr->get_table_line_type( ).

      lr_struct_descr ?= lr_table_line_descr.
      DATA(lt_tab_components) = lr_struct_descr->get_components( ).

      ASSIGN ir_data->* TO <ft_data>.
      CHECK <ft_data> IS ASSIGNED.

      LOOP AT <ft_data> ASSIGNING <fs_table_line_data>.

*       Check if the table only has simple typed elements
        DATA(lt_tab_components_copy) = lt_tab_components.
        DELETE lt_tab_components_copy WHERE type->kind = cl_abap_elemdescr=>kind_elem.

*       If the component tab is now initial that would mean that there are no deep
*       types in here. Add the Items directly
        IF lt_tab_components_copy IS INITIAL.

          CLEAR lv_parent_node.
          IF lv_comp_node_key IS NOT INITIAL.
            lv_parent_node = lv_comp_node_key.
          ELSE.
            lv_parent_node = iv_parent_node.
          ENDIF.

*         Get reference of table line data
          GET REFERENCE OF <fs_table_line_data> INTO lr_item_node_data.

*         Add Item Detail Node
          CALL METHOD add_item_node(
            EXPORTING
              iv_parent_node = lv_parent_node
              ir_item_data   = lr_item_node_data
            IMPORTING
              ev_node_key    = ev_node_key ).

        ELSE.

*         Process the individual components one by one
          CLEAR: lv_first_comp_node, lv_parent_node.
          LOOP AT lt_tab_components INTO DATA(ls_table_comp_details).

            lv_index = sy-tabix.

*           Get Reference of data relevant to the current component
            ASSIGN COMPONENT ls_table_comp_details-name
                   OF STRUCTURE <fs_table_line_data>
                   TO FIELD-SYMBOL(<fs_table_comp_data>).

            GET REFERENCE OF <fs_table_comp_data> INTO DATA(lr_table_comp_data).

            CLEAR lv_parent_node.
*           Check if the first component node ic created
            IF lv_first_comp_node IS NOT INITIAL.
              lv_parent_node = lv_first_comp_node.
            ELSE.
*             Parent can be either of the dummy node or the provided parent
              IF lv_comp_node_key IS NOT INITIAL.
                lv_parent_node = lv_comp_node_key.
              ELSE.
                lv_parent_node = iv_parent_node.
              ENDIF.
            ENDIF.

*           Process inidividual component nodes
            CALL METHOD me->publish_ind_comp(
              EXPORTING
                ir_data         = lr_table_comp_data
                is_comp_details = ls_table_comp_details
                iv_parent_node  = lv_parent_node
              IMPORTING
                ev_node_key     = lv_object_node_key ).

*           Set the first component node of the complex structure
            IF lv_index EQ 1.
              lv_first_comp_node = lv_object_node_key.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


METHOD publish_nodes_from_data.

  IF mr_struct_ref IS BOUND.
    DATA(lt_components) = mr_struct_ref->get_components( ).
  ENDIF.

  ASSIGN mr_cds_model->* TO FIELD-SYMBOL(<fs_cds_model>).

* Prepare Tree Nodes and Items
  LOOP AT lt_components INTO DATA(ls_comp_details).

    ASSIGN COMPONENT ls_comp_details-name OF STRUCTURE <fs_cds_model>
           TO FIELD-SYMBOL(<fs_comp_data>).

    GET REFERENCE OF <fs_comp_data> INTO DATA(lr_data).

*   Process inidividual component nodes
    CALL METHOD me->publish_ind_comp(
      EXPORTING
        ir_data         = lr_data
        is_comp_details = ls_comp_details ).
  ENDLOOP.

* Rebuild All Nodes and Items
  CALL METHOD me->rebuild_nodes_items.
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

*   Set Expanded Nodes
    CALL METHOD mr_tree->expand_nodes( mt_expanded_nodes ).

*   Set Selected Node
    IF mv_current_node IS NOT INITIAL.
      CALL METHOD mr_tree->set_selected_node( mv_current_node ).
    ENDIF.

*    CALL METHOD cl_gui_cfw=>flush
*      EXCEPTIONS
*        cntl_system_error = 1
*        cntl_error        = 2
*        OTHERS            = 3.
*    IF sy-subrc <> 0.
**     Implement suitable error handling here
*    ENDIF.
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


  METHOD validate_model.
*   Validate Model Data
    CHECK mv_current_node IS NOT INITIAL.
    CALL METHOD mr_cds_modeller->validate_model( mv_current_node ).
  ENDMETHOD.
ENDCLASS.
