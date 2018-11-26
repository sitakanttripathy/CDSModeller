class ZCL_CDS_MODELLER definition
  public
  final
  create public .

public section.

  constants MC_NODE_TYPE_P type Z_DE_NODE_TYPE value 'P' ##NO_TEXT.
  constants MC_NODE_TYPE_V type Z_DE_NODE_TYPE value 'V' ##NO_TEXT.
  constants MC_NODE_TYPE_A type Z_DE_NODE_TYPE value 'A' ##NO_TEXT.
  constants MC_NODE_TYPE_J type Z_DE_NODE_TYPE value 'J' ##NO_TEXT.
  constants MC_NODE_TYPE_E type Z_DE_NODE_TYPE value 'E' ##NO_TEXT.
  constants MC_NODE_TYPE_R type Z_DE_NODE_TYPE value 'R' ##NO_TEXT.
  constants MC_NODE_TYPE_S type Z_DE_NODE_TYPE value 'S' ##NO_TEXT.
  constants MC_MODE_CHANGE type E_MODE value '2' ##NO_TEXT.
  constants MC_MODE_DISPLAY type E_MODE value '1' ##NO_TEXT.
  constants MC_SEL_SOURCE_TABLE type Z_DE_SEL_SOURCE_TYPE value 'TABLE' ##NO_TEXT.
  constants MC_SEL_SOURCE_VIEW type Z_DE_SEL_SOURCE_TYPE value 'VIEW' ##NO_TEXT.
  constants MC_SEL_SOURCE_DDL type Z_DE_SEL_SOURCE_TYPE value 'DDL' ##NO_TEXT.
  constants MC_ELEMENT_TYPE_FIELD type Z_DE_ELEMENT_TYPE value 'FIELD' ##NO_TEXT.
  constants MC_ELEMENT_TYPE_PATH type Z_DE_ELEMENT_TYPE value 'PATH' ##NO_TEXT.

  methods CONSTRUCTOR
    importing
      !IR_VIEW_BUILDER type ref to ZCL_CDS_VIEW_BUILDER_TREE .
  class-methods GET_INSTANCE
    importing
      !IR_VIEW_BUILDER type ref to ZCL_CDS_VIEW_BUILDER_TREE
    returning
      value(ER_MODELLER) type ref to ZCL_CDS_MODELLER .
  methods HANDLE_EVENTS
    importing
      !IV_EVENT type SY-UCOMM .
  methods GET_MODEL_DATA
    returning
      value(ES_CDS_MODEL) type ZCDS_MODELLING_MODEL .
  methods GET_MODEL_DATA_REF
    returning
      value(ER_CDS_MODEL) type ref to DATA .
  methods GET_MODE
    returning
      value(EV_MODE) type E_MODE .
  methods SET_MODE
    importing
      !IV_MODE type E_MODE .
  methods GET_COMP_TO_NODE_TYPE
    importing
      !IV_COMP_NAME type NAME_KOMP
    returning
      value(EV_NODE_TYPE) type Z_DE_NODE_TYPE .
  class-methods GET_DDL_METADATA
    importing
      !IV_DDL_SOURCE type DDLNAME
    returning
      value(ES_DDL_METADATA) type CL_SODPS_ABAP_CDS_ANALYZER=>TN_SX_VIEW .
  methods VALIDATE_MODEL
    importing
      !IV_NODE_KEY type TV_NODEKEY optional .
PROTECTED SECTION.

  CLASS-DATA mr_modeller TYPE REF TO zcl_cds_modeller .
  DATA mv_ddl_name TYPE cdsview_source .
  DATA mr_view_builder TYPE REF TO zcl_cds_view_builder_tree .
private section.

  data MS_DDL_DETAILS type DDDDLSRC .
  data MS_ENTITY_MODEL_OLD type ZCDS_MODELLING_MODEL .
  data MS_ENTITY_MODEL_NEW type ZCDS_MODELLING_MODEL .
  data MR_ANNOT_BIBLE type ref to ZCL_CDS_ANNOT_BIBLE .
  data MV_MODE type E_MODE .

  methods CHECK_ALIAS_EXISTS
    importing
      !IV_ALIAS type Z_DE_ALIAS
    returning
      value(EV_ALIAS_EXISTS) type ABAP_BOOL .
  methods HANDLE_VB_NODE_INSERT .
  methods HANDLE_VB_OPEN .
  methods HANDLE_VB_SAVE .
  methods HANDLE_VB_GENERATE .
  methods INITIALIZE_ENTITY .
  methods GET_STRUCTURE_NAME
    importing
      !IV_NODE_TYPE type Z_DE_NODE_TYPE
    returning
      value(EV_STRUCT_NAME) type STRUKNAME .
  methods HANDLE_INSERT_ELEMENTS
    importing
      !IV_NODE_KEY type TV_NODEKEY .
  methods HANDLE_INSERT_ASSOCIATIONS
    importing
      !IV_NODE_KEY type TV_NODEKEY .
  methods HANDLE_INSERT_JOINS
    importing
      !IV_NODE_KEY type TV_NODEKEY .
  methods HANDLE_INSERT_REFCONSTRAINTS
    importing
      !IV_NODE_KEY type TV_NODEKEY .
  methods HANDLE_INSERT_SELCONSTRAINTS
    importing
      !IV_NODE_KEY type TV_NODEKEY .
  methods GET_DATA_SOURCE_AND_ELEMENTS
    importing
      !IV_NODE_TYPE type Z_DE_NODE_TYPE
    exporting
      value(EV_CANCELLED) type ABAP_BOOL
    changing
      !CS_DATA_SOURCE type ZCDS_DATA_SOURCE_CAPTURE optional .
  methods GET_ELEMENTS
    importing
      !IV_TABLE type TABNAME16
      !IV_VIEW type VIEWNAME16
      !IV_DDL_SOURCE type DDLSOURCENAME
    returning
      value(ET_FIELDLIST) type DDFIELDS .
  methods HANDLE_VB_CREATE .
  methods UPDATE_MODEL_FROM_SELECTION
    importing
      !IV_NODE_TYPE type Z_DE_NODE_TYPE
      !IV_NODE_KEY type TV_NODEKEY optional
      !IS_DATA_SOURCE type ZCDS_DATA_SOURCE_CAPTURE .
  methods VALIDATE_ENTITY
    importing
      !IV_NODE_KEY type TV_NODEKEY optional .
  methods VALIDATE_ASSOCIATIONS
    importing
      !IV_NODE_KEY type TV_NODEKEY optional .
  methods VALIDATE_JOINS
    importing
      !IV_NODE_KEY type TV_NODEKEY optional .
  methods VALIDATE_ELEMENTS
    importing
      !IV_NODE_KEY type TV_NODEKEY optional .
  methods VALIDATE_PARAMETERS
    importing
      !IV_NODE_KEY type TV_NODEKEY optional .
  methods VALIDATE_REF_CONSTRAINTS
    importing
      !IV_NODE_KEY type TV_NODEKEY optional .
  methods VALIDATE_SEL_CONSTRAINTS
    importing
      !IV_NODE_KEY type TV_NODEKEY .
ENDCLASS.



CLASS ZCL_CDS_MODELLER IMPLEMENTATION.


  METHOD check_alias_exists.



  ENDMETHOD.


  METHOD constructor.
*   Instantiate the annotation modeller
    mr_view_builder = ir_view_builder.
    mr_annot_bible  = zcl_cds_annot_bible=>get_instance( ).
  ENDMETHOD.


  METHOD get_comp_to_node_type.
    CASE iv_comp_name.
*     Set View Node Type
      WHEN 'ENTITY'.
        ev_node_type = mc_node_type_v.
*     Set Elements Node Type
      WHEN 'ELEMENTS'.
        ev_node_type = mc_node_type_e.
*     Set Associations Node Type
      WHEN 'ASSOC'.
        ev_node_type = mc_node_type_a.
*     Set Join Node Type
      WHEN 'JOIN'.
        ev_node_type = mc_node_type_j.
*     Set Referential Constraints Node Type
      WHEN 'REF_CONSTRAINTS'.
        ev_node_type = mc_node_type_r.
*     Set Selection Constraints Node Type
      WHEN 'SEL_CONSTRAINTS'.
        ev_node_type = mc_node_type_s.
*     Set Parameter Node Type
      WHEN 'PARAMETERS'.
        ev_node_type = mc_node_type_p.
    ENDCASE.
  ENDMETHOD.


  METHOD get_data_source_and_elements.

    DATA:
      lv_data_source   TYPE string,
      lv_parent_prefix TYPE string,
      ls_fieldlist     TYPE dfies.

*   Get Data Source for the view
    CALL METHOD mr_view_builder->get_user_input(
      EXPORTING
        iv_call_type     = 'SOURCE'
        IV_REQ_NODE_TYPE = iv_node_type
      IMPORTING
        ev_cancelled     = ev_cancelled
      changing
        cs_data_source   = cs_data_source ).

    CHECK ev_cancelled IS INITIAL.

**   Get Elements of the Data Source
*    DATA(lt_fieldlist) = get_elements( EXPORTING iv_table      = ls_data_source-tbma_val
*                                                 iv_view       = ls_data_source-vima_val
*                                                 iv_ddl_source = ls_data_source-ddl_source ).
*
*    CHECK lt_fieldlist IS NOT INITIAL.
*
**   Set Primary Data Source
*    IF ls_data_source-tbma_val IS NOT INITIAL.
*      lv_data_source = ls_data_source-tbma_val.
*    ELSEIF ls_data_source-vima_val IS NOT INITIAL.
*      lv_data_source = ls_data_source-vima_val.
*    ELSEIF ls_data_source-ddl_source IS NOT INITIAL.
*      lv_data_source = ls_data_source-ddl_source.
*    ENDIF.
*
**   Handle Data Source for View Node
*    IF iv_node_type = mc_node_type_v.
**     Set View Data Source
*      ms_entity_model_new-entity-node-sel_source = lv_data_source.
**     Set elements of data source
*      LOOP AT lt_fieldlist INTO ls_fieldlist.
*        APPEND INITIAL LINE TO ms_entity_model_new-entity-elements
*                       ASSIGNING FIELD-SYMBOL(<fs_view_element>).
*        <fs_view_element>-node-element = ls_fieldlist-fieldname.
*      ENDLOOP.
*
**     Add dependent Associations
*      lv_parent_prefix = ms_entity_model_new-entity-node-sel_source.
*      CALL METHOD add_dependent_assoc(
*        EXPORTING
*          iv_ddl_source    = ls_data_source-ddl_source
*          iv_node_type     = iv_node_type
*          iv_parent_prefix = lv_parent_prefix ).
*
**   Handle Data Source for Associations
*    ELSEIF iv_node_type = mc_node_type_a.
**     Set Associations for View
*      APPEND INITIAL LINE TO ms_entity_model_new-entity-assoc
*             ASSIGNING FIELD-SYMBOL(<fs_assoc>).
*      <fs_assoc>-node-target = lv_data_source.
**     Set elements of association data source
*      LOOP AT lt_fieldlist INTO ls_fieldlist.
*        APPEND INITIAL LINE TO <fs_assoc>-elements
*                       ASSIGNING FIELD-SYMBOL(<fs_assoc_element>).
*        <fs_assoc_element>-node-element = ls_fieldlist-fieldname.
*      ENDLOOP.
*
**   Handle Data Source for Joins
*    ELSEIF iv_node_type = mc_node_type_j.
**     Set joins for View
*      APPEND INITIAL LINE TO ms_entity_model_new-entity-join
*             ASSIGNING FIELD-SYMBOL(<fs_join>).
*      <fs_join>-node-target = lv_data_source.
**     Set elements of join data source
*      LOOP AT lt_fieldlist INTO ls_fieldlist.
*        APPEND INITIAL LINE TO <fs_join>-elements
*                       ASSIGNING FIELD-SYMBOL(<fs_join_element>).
*        <fs_join_element>-node-element = ls_fieldlist-fieldname.
*      ENDLOOP.
*    ENDIF.
  ENDMETHOD.


  METHOD get_ddl_metadata.
*   Get all the DDL metadata
    es_ddl_metadata = cl_sodps_abap_cds_analyzer=>analyze_cds_view( iv_ddl_source ).
  ENDMETHOD.


  METHOD get_elements.

    DATA:
      lv_obj_name     TYPE string,
      ls_fieldlist    TYPE dfies,
      lr_struct_descr TYPE REF TO cl_abap_structdescr.

*   Tables as source
    IF iv_table IS NOT INITIAL.
      lv_obj_name = iv_table.
      DATA(lr_abap_descr) = cl_abap_structdescr=>describe_by_name( lv_obj_name ).
      lr_struct_descr ?= lr_abap_descr.

      et_fieldlist = lr_struct_descr->get_ddic_field_list( ).

*   Conventional Views as source
    ELSEIF iv_view IS NOT INITIAL.
      lv_obj_name = iv_table.
      lr_abap_descr = cl_abap_structdescr=>describe_by_name( lv_obj_name ).
      lr_struct_descr ?= lr_abap_descr.

      et_fieldlist = lr_struct_descr->get_ddic_field_list( ).

*   CDS as source
    ELSEIF iv_ddl_source IS NOT INITIAL.

      DATA(ls_metadata) = get_ddl_metadata( iv_ddl_source ).
*     Add all published elements of the CDS
      LOOP AT ls_metadata-tx_field INTO DATA(ls_fields).
        ls_fieldlist-fieldname = ls_fields-fieldname.
        APPEND ls_fieldlist TO et_fieldlist.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD get_instance.
*   Create and Store Instance
    IF mr_modeller IS INITIAL.
      mr_modeller = NEW zcl_cds_modeller( ir_view_builder ).
    ENDIF.

    er_modeller = mr_modeller.
  ENDMETHOD.


  METHOD get_mode.
    ev_mode = mv_mode.
  ENDMETHOD.


  METHOD get_model_data.
*   Pass current modelling data
    es_cds_model = ms_entity_model_new.
  ENDMETHOD.


  METHOD get_model_data_ref.
    GET REFERENCE OF ms_entity_model_new INTO er_cds_model.
  ENDMETHOD.


  METHOD get_structure_name.
    CASE iv_node_type.
*     Views
      WHEN mc_node_type_v.
        ev_struct_name = 'ZCDS_VIEW_ENTITY'.
*     Associations
      WHEN mc_node_type_a.
        ev_struct_name = 'ZCDS_VIEW_ASSOCIATIONS'.
*     Joins
      WHEN mc_node_type_j.
        ev_struct_name = 'ZCDS_VIEW_JOINS'.
*     Elements
      WHEN mc_node_type_e.
        ev_struct_name = 'ZCDS_VIEW_ELEMENTS'.
*     Referential Constraints
      WHEN mc_node_type_r.
        ev_struct_name = 'ZCDS_VIEW_REF_CONSTRAINTS'.
*     Selection Constraints
      WHEN mc_node_type_s.
        ev_struct_name = 'ZCDS_VIEW_SEL_CONSTRAINTS'.
    ENDCASE.
  ENDMETHOD.


  METHOD handle_events.
    CASE iv_event.
*     Handle CDS View Create
      WHEN 'CREATE'.
        CALL METHOD handle_vb_create.
*     Handle Node Artifacts Create
      WHEN 'INSERT'.
        CALL METHOD handle_vb_node_insert.
*     Open CDS View Defnitions
      WHEN 'OPEN'.
        CALL METHOD handle_vb_open.
*     Change CDS View Definitions
      WHEN 'CHANGE'.
        CALL METHOD handle_vb_open.
*     Save CDS View Definitions
      WHEN 'SAVE'.
        CALL METHOD handle_vb_save.
*     Generate CDS DDL based on view definitions
      WHEN 'GENERATE'.
        CALL METHOD handle_vb_generate.
    ENDCASE.
  ENDMETHOD.


  METHOD handle_insert_associations.

    DATA:
      lv_sel_source      TYPE z_de_sel_source,
      lv_sel_source_type TYPE z_de_sel_source_type,
      ls_data_source     TYPE zcds_data_source_capture.

*   Get Data Source and releant elements
    CALL METHOD get_data_source_and_elements(
      EXPORTING
        iv_node_type   = mc_node_type_a
      IMPORTING
        ev_cancelled   = DATA(lv_cancelled)
      CHANGING
        cs_data_source = ls_data_source ).

    CHECK lv_cancelled IS INITIAL.
    CHECK ls_data_source IS NOT INITIAL.

*   Check Source and Type
    IF ls_data_source-tbma_val IS NOT INITIAL.
      lv_sel_source      = ls_data_source-tbma_val.
      lv_sel_source_type = mc_sel_source_table.
    ELSEIF ls_data_source-vima_val IS NOT INITIAL.
      lv_sel_source      = ls_data_source-vima_val.
      lv_sel_source_type = mc_sel_source_view.
    ELSEIF ls_data_source-ddl_source IS NOT INITIAL.
      lv_sel_source      = ls_data_source-ddl_source.
      lv_sel_source_type = mc_sel_source_ddl.
    ENDIF.

*   Update model with new association details
    APPEND INITIAL LINE TO ms_entity_model_new-entity-assoc
                   ASSIGNING FIELD-SYMBOL(<fs_assoc>).
    <fs_assoc>-node-sel_source = lv_sel_source.
    <fs_assoc>-node-sel_source_type = lv_sel_source_type.
  ENDMETHOD.


  METHOD handle_insert_elements.

    DATA:
      ls_data_source TYPE zcds_data_source_capture.

    FIELD-SYMBOLS:
      <fs_data_view>  TYPE zcds_view_entity,
      <fs_view_assoc> TYPE zcds_view_associations,
      <fs_view_join>  TYPE zcds_view_joins.

    BREAK-POINT.

*   Get the Node for which the elements need to be added
    CALL METHOD mr_view_builder->get_node_details(
      EXPORTING
        iv_node_key     = iv_node_key
      IMPORTING
        es_node_details = DATA(ls_node_details) ).

*   Get the data reference of the parent node
    CALL METHOD mr_view_builder->get_node_details(
      EXPORTING
        iv_node_key     = ls_node_details-relatkey
      IMPORTING
        es_node_details = DATA(ls_parent_node_details)
        es_node_dataref = DATA(ls_parent_dataref) ).

    ASSIGN ls_parent_dataref-dataref->* TO <fs_data_view>.
*      lv_obj_name = <fs_data_view>-sel_source.

    IF <fs_data_view>-sel_source IS INITIAL.
      MESSAGE i398(00) WITH 'Please provde the primary source for CDS View'.
      RETURN.
    ENDIF.

*   Get User input for field selection
    CASE <fs_data_view>-sel_source_type.
*     Source Type Table
      WHEN mc_sel_source_table.
        ls_data_source-tbma_val = <fs_data_view>-sel_source.
*     Source Type View
      WHEN mc_sel_source_view.
        ls_data_source-vima_val = <fs_data_view>-sel_source.
*     Source Type DDL
      WHEN mc_sel_source_ddl.
        ls_data_source-ddl_source = <fs_data_view>-sel_source.
    ENDCASE.

*   Get Usr input for Source and Elements
    CALL METHOD get_data_source_and_elements(
      EXPORTING
        iv_node_type   = mc_node_type_e
      IMPORTING
        ev_cancelled   = DATA(lv_cancelled)
      CHANGING
        cs_data_source = ls_data_source ).

*   Check relevant details provided
    CHECK lv_cancelled IS INITIAL.
    CHECK ls_data_source IS NOT INITIAL.

*   Update Model from selection
    CALL METHOD update_model_from_selection(
      EXPORTING
        iv_node_type   = mc_node_type_e
        iv_node_key    = iv_node_key
        is_data_source = ls_data_source ).

  ENDMETHOD.


  METHOD handle_insert_joins.
    DATA:
      lv_sel_source      TYPE z_de_sel_source,
      lv_sel_source_type TYPE z_de_sel_source_type,
      ls_data_source     TYPE zcds_data_source_capture.

*   Get Data Source and releant elements
    CALL METHOD get_data_source_and_elements(
      EXPORTING
        iv_node_type   = mc_node_type_a
      IMPORTING
        ev_cancelled   = DATA(lv_cancelled)
      CHANGING
        cs_data_source = ls_data_source ).

    CHECK lv_cancelled IS INITIAL.
    CHECK ls_data_source IS NOT INITIAL.

*   Check Source and Type
    IF ls_data_source-tbma_val IS NOT INITIAL.
      lv_sel_source      = ls_data_source-tbma_val.
      lv_sel_source_type = mc_sel_source_table.
    ELSEIF ls_data_source-vima_val IS NOT INITIAL.
      lv_sel_source      = ls_data_source-vima_val.
      lv_sel_source_type = mc_sel_source_view.
    ELSEIF ls_data_source-ddl_source IS NOT INITIAL.
      lv_sel_source      = ls_data_source-ddl_source.
      lv_sel_source_type = mc_sel_source_ddl.
    ENDIF.

*   Update model with new association details
    APPEND INITIAL LINE TO ms_entity_model_new-entity-join
                   ASSIGNING FIELD-SYMBOL(<fs_join>).
    <fs_join>-node-sel_source = lv_sel_source.
    <fs_join>-node-sel_source_type = lv_sel_source_type.
  ENDMETHOD.


  method HANDLE_INSERT_REFCONSTRAINTS.
  endmethod.


  method HANDLE_INSERT_SELCONSTRAINTS.
  endmethod.


  METHOD handle_vb_create.

    DATA:
     ls_data_source TYPE zcds_data_source_capture.

*   Query CDS Name and Type
    CALL METHOD mr_view_builder->get_user_input(
      EXPORTING
        iv_call_type   = 'VIEW'
      IMPORTING
        es_ddl_details = ms_ddl_details
        ev_cancelled   = DATA(lv_cancelled) ).

*   Check Operation Cancelled: No updates made
    CHECK lv_cancelled IS INITIAL.
*   Check for user entry provided.
    CHECK ms_ddl_details IS NOT INITIAL.

*   Set Change Mode
    CALL METHOD set_mode( mc_mode_change ).

*   Get Data Source and releant Elements
    CALL METHOD get_data_source_and_elements(
      EXPORTING
        iv_node_type   = mc_node_type_v
      IMPORTING
        ev_cancelled   = lv_cancelled
      CHANGING
        cs_data_source = ls_data_source ).

    CHECK lv_cancelled IS INITIAL.

*   Initialize View Entity
    CALL METHOD initialize_entity.

*   Add Elements from Source
    CALL METHOD update_model_from_selection(
      EXPORTING
        iv_node_type   = mc_node_type_v
        is_data_source = ls_data_source ).

  ENDMETHOD.


  method HANDLE_VB_GENERATE.
* Generate the DDL source for abap backend based on the
* CDS View definitions
  endmethod.


  METHOD handle_vb_node_insert.

*   Get Selected Node Key
    CHECK mr_view_builder IS BOUND.
    CALL METHOD mr_view_builder->mr_tree->get_selected_node(
      IMPORTING
        node_key = DATA(lv_node_key) ).

*   Check if Item was Selected
    IF lv_node_key IS INITIAL.
      CALL METHOD mr_view_builder->mr_tree->get_selected_item(
        IMPORTING
          node_key = lv_node_key ).
    ENDIF.

*   Check Node Selected
    IF lv_node_key IS INITIAL.
      MESSAGE i005(zcds_messages).
      RETURN.
    ENDIF.

*   Get Node Details
    CALL METHOD mr_view_builder->get_node_details(
      EXPORTING
        iv_node_key     = lv_node_key
      IMPORTING
        es_node_details = DATA(ls_node_details) ).

*   Node View/Join Elements
    IF ls_node_details-node_type = mc_node_type_e.
      CALL METHOD handle_insert_elements( lv_node_key ).
*   Node View Associations
    ELSEIF ls_node_details-node_type = mc_node_type_a.
      CALL METHOD handle_insert_associations( lv_node_key ).
*   Node View Joins
    ELSEIF ls_node_details-node_type = mc_node_type_j.
      CALL METHOD handle_insert_joins( lv_node_key ).
*   Node Referential Constraints
    ELSEIF ls_node_details-node_type = mc_node_type_r.
      CALL METHOD handle_insert_refconstraints( lv_node_key ).
*   Node Selection Constraints
    ELSEIF ls_node_details-node_type = mc_node_type_s.
      CALL METHOD handle_insert_selconstraints( lv_node_key ).
*   For Anything Else
    ELSE.
      MESSAGE i398(00) WITH 'Entries not allowed for this node.'.
      RETURN.
    ENDIF.
  ENDMETHOD.


  method HANDLE_VB_OPEN.
*  Option for selecting the CDS view to be opened
  endmethod.


  METHOD handle_vb_save.

    DATA(gr_xml_document) = NEW cl_xml_document( ).
    DATA(rc) = gr_xml_document->set_data( name       = 'TEST'
                                          dataobject = ms_entity_model_new  ).

    gr_xml_document->render_2_string( IMPORTING stream = DATA(ls_stream) ).
    gr_xml_document->get_data( CHANGING dataobject = ms_entity_model_old ).

  ENDMETHOD.


  METHOD initialize_entity.
*   Intialize View Entity
    ms_entity_model_new-entity-node-ddl_name     = ms_ddl_details-ddlname.
    ms_entity_model_new-entity-node-source_type  = ms_ddl_details-source_type.
    ms_entity_model_new-entity-node-parent_name  = ms_ddl_details-parentname.

  ENDMETHOD.


  METHOD set_mode.
    mv_mode = iv_mode.
  ENDMETHOD.


  METHOD update_model_from_selection.

    DATA:
      lv_sel_source      TYPE z_de_sel_source,
      lv_sel_source_type TYPE z_de_sel_source_type,
      ls_fieldlist       TYPE dfies,
      ls_assoc_selection TYPE zcds_assoc_selection.

    FIELD-SYMBOLS:
      <fv_sel_source> TYPE z_de_sel_source,
      <ft_elements>   TYPE zcds_tt_view_element_model,
      <fs_elements>   TYPE zcds_view_element_model.

    BREAK-POINT.

*   Check Source and Type
    IF is_data_source-tbma_val IS NOT INITIAL.
      lv_sel_source      = is_data_source-tbma_val.
      lv_sel_source_type = mc_sel_source_table.
    ELSEIF is_data_source-vima_val IS NOT INITIAL.
      lv_sel_source      = is_data_source-vima_val.
      lv_sel_source_type = mc_sel_source_view.
    ELSEIF is_data_source-ddl_source IS NOT INITIAL.
      lv_sel_source      = is_data_source-ddl_source.
      lv_sel_source_type = mc_sel_source_ddl.
    ENDIF.

*   Set Selected elements for View Node
    IF iv_node_type EQ mc_node_type_v.
*     Set Selection Source
      ms_entity_model_new-entity-node-sel_source      = lv_sel_source.
      ms_entity_model_new-entity-node-sel_source_type = lv_sel_source_type.

*     Set FieldList
      LOOP AT is_data_source-fieldlist INTO ls_fieldlist.
        APPEND INITIAL LINE TO ms_entity_model_new-entity-elements
                       ASSIGNING FIELD-SYMBOL(<fs_view_element>).
        <fs_view_element>-node-element = ls_fieldlist.
        <fs_view_element>-node-element_type = mc_element_type_field.
      ENDLOOP.

*     Identify selected elements for the CDS type source
      LOOP AT is_data_source-assoc INTO ls_assoc_selection.
        APPEND INITIAL LINE TO ms_entity_model_new-entity-elements
                       ASSIGNING <fs_view_element>.
        <fs_view_element>-node-element      = ls_assoc_selection-fieldname.
        <fs_view_element>-node-element_type = ls_assoc_selection-element_type.
      ENDLOOP.

*   Set Selected Elements
    ELSEIF iv_node_type EQ mc_node_type_e.

**     Get Parnt Node Details
**     This is to understand where do elements need to go
*      CHECK iv_node_key IS NOT INITIAL.
*      CALL METHOD mr_view_builder->get_node_details(
*        EXPORTING
*          iv_node_key     = iv_node_key
*        IMPORTING
*          es_node_details = DATA(ls_node_details)
*          es_node_dataref = DATA(ls_node_dataref) ).
*
*      ASSIGN ls_node_dataref-dataref->* TO <ft_elements>.
*      CHECK <ft_elements> IS ASSIGNED.
*
**     Process Fieldlist
*      LOOP AT is_data_source-fieldlist INTO ls_fieldlist.
**       Do not process the field if it already exists
*        READ TABLE <ft_elements> ASSIGNING <fs_elements>
*             WITH KEY node-element = ls_fieldlist.
*        CHECK sy-subrc NE 0.
*
*        APPEND INITIAL LINE TO <ft_elements> ASSIGNING <fs_elements>.
*        <fs_elements>-node-element = ls_fieldlist.
*      ENDLOOP.
*
**     Process Fieldlist from CDS DDL
*      LOOP AT is_data_source-assoc INTO ls_assoc_selection
*                                   WHERE record_type = 'F'. "Fields
**       Do not process the field if it already exists
*        READ TABLE <ft_elements> ASSIGNING <fs_elements>
*             WITH KEY node-element = ls_fieldlist.
*        CHECK sy-subrc NE 0.
*
*        APPEND INITIAL LINE TO <ft_elements> ASSIGNING <fs_elements>.
*        <fs_elements>-node-element = ls_assoc_selection-fieldname.
*      ENDLOOP.

*   Set Selected elements from Association Node
    ELSEIF iv_node_type EQ mc_node_type_a.

*   Set Selected elements from Join Node
    ELSEIF  iv_node_type EQ mc_node_type_j.


    ENDIF.
  ENDMETHOD.


  METHOD validate_associations.

    FIELD-SYMBOLS:
      <ft_assoc> TYPE zcds_tt_view_assoc_model,
      <fs_assoc> TYPE zcds_view_assoc_model.

*   Check for validation call stack
    IF iv_node_key IS SUPPLIED.
*     Get Validating Node Details
      CALL METHOD mr_view_builder->get_node_details(
        EXPORTING
          iv_node_key     = iv_node_key
        IMPORTING
          es_node_dataref = DATA(ls_node_dataref) ).

      ASSIGN ls_node_dataref-dataref->* TO <ft_assoc>.
    ELSE.
*     Set Information from available model
      ASSIGN ms_entity_model_new-entity-assoc TO <ft_assoc>.
    ENDIF.

    LOOP AT <ft_assoc> ASSIGNING <fs_assoc>.

*     Check for Alias
      IF <fs_assoc>-node-alias IS INITIAL.
        MESSAGE i398(00) WITH 'Alias is mandatory for Associations.'.
      ELSE.
*       Check Alias already used
        DATA(lv_alias_exists) = check_alias_exists( <fs_assoc>-node-alias ).
      ENDIF.

*     Check for Cardinality
      IF <fs_assoc>-node-cardinality IS INITIAL.
        MESSAGE i398(00) WITH 'Cardinality is mandatory for Associations.'.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate_elements.

    FIELD-SYMBOLS:
      <ft_elements> TYPE zcds_tt_view_element_model,
      <fs_elements> TYPE zcds_view_element_model.

*   Check for validation call stack
    IF iv_node_key IS SUPPLIED.
*     Get Validating Node Details
      CALL METHOD mr_view_builder->get_node_details(
        EXPORTING
          iv_node_key     = iv_node_key
        IMPORTING
          es_node_dataref = DATA(ls_node_dataref) ).

      ASSIGN ls_node_dataref-dataref->* TO <ft_elements>.
    ELSE.
*     Set Information from available model
      ASSIGN ms_entity_model_new-entity-elements TO <ft_elements>.
    ENDIF.

    LOOP AT <ft_elements> ASSIGNING <fs_elements>.

*     Check for Alias
      IF <fs_elements>-node-alias IS NOT INITIAL.
*       Check Alias already used
        DATA(lv_alias_exists) = check_alias_exists( <fs_elements>-node-alias ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate_entity.

    FIELD-SYMBOLS:
      <fs_entity> TYPE zcds_view_entity.

*   Check for validation call stack
    IF iv_node_key IS SUPPLIED.
*     Get Validating Node Details
      CALL METHOD mr_view_builder->get_node_details(
        EXPORTING
          iv_node_key     = iv_node_key
        IMPORTING
          es_node_dataref = DATA(ls_node_dataref) ).

      ASSIGN ls_node_dataref-dataref->* TO <fs_entity>.
    ELSE.
*     Set Information from available model
      ASSIGN ms_entity_model_new-entity-node TO <fs_entity>.
    ENDIF.

*   Check Entity Name
    IF <fs_entity>-entity IS INITIAL.
      MESSAGE i398(00) WITH 'Entity Name is mandatory.' .
    ENDIF.

*   Check Source Type and Parent DDL combination
    IF  <fs_entity>-source_type EQ 'E'
    AND <fs_entity>-parent_name IS NOT INITIAL.
      MESSAGE i398(00) WITH 'Parent DDL Name mandaotry for view extensions'.
    ENDIF.

*   Check Source Type and AMDP Functions
    IF  <fs_entity>-source_type EQ 'F'
    AND <fs_entity>-amdp_name IS NOT INITIAL.
      MESSAGE i398(00) WITH 'AMDP is mandatory for Table Functions'.
    ENDIF.

*   Check Alias: To be Done
    IF  <fs_entity>-alias IS NOT INITIAL.
      DATA(lv_alias_exists) = check_alias_exists( <fs_entity>-alias ).
    ENDIF.
  ENDMETHOD.


  METHOD validate_joins.

    FIELD-SYMBOLS:
      <ft_join> TYPE zcds_tt_view_join_model,
      <fs_join> TYPE zcds_view_join_model.

*   Check for validation call stack
    IF iv_node_key IS SUPPLIED.
*     Get Validating Node Details
      CALL METHOD mr_view_builder->get_node_details(
        EXPORTING
          iv_node_key     = iv_node_key
        IMPORTING
          es_node_dataref = DATA(ls_node_dataref) ).

      ASSIGN ls_node_dataref-dataref->* TO <ft_join>.
    ELSE.
*     Set Information from available model
      ASSIGN ms_entity_model_new-entity-join TO <ft_join>.
    ENDIF.

    LOOP AT <ft_join> ASSIGNING <fs_join>.

*     Check for Alias
      IF <fs_join>-node-alias IS INITIAL.
        MESSAGE i398(00) WITH 'Alias is mandatory for Joins.'.
      ELSE.
*       Check Alias already used
        DATA(lv_alias_exists) = check_alias_exists( <fs_join>-node-alias ).
      ENDIF.

*     Check for Cardinality
      IF <fs_join>-node-JOIN_TYPE IS INITIAL.
        MESSAGE i398(00) WITH 'Join Type is mandatory for joins.'.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD validate_model.

    DATA:
      lv_validate_all TYPE abap_bool.

    BREAK-POINT.

*   Check if a particular node is to be validated
*   or the entire model is to be validated
    IF  iv_node_key IS SUPPLIED
    AND iv_node_key IS NOT INITIAL.
*     Get Node Details
      CALL METHOD mr_view_builder->get_node_details(
        EXPORTING
          iv_node_key     = iv_node_key
        IMPORTING
          es_node_details = DATA(ls_node_details) ).
    ELSE.
      lv_validate_all = abap_true.
    ENDIF.

    IF lv_validate_all IS INITIAL.
*     Validate Entities
      IF ls_node_details-node_type = mc_node_type_v.
        CALL METHOD validate_entity( iv_node_key ).
*     Validate Elements
      ELSEIF ls_node_details-node_type = mc_node_type_e.
        CALL METHOD validate_elements( iv_node_key ).
*     Validate Associations
      ELSEIF ls_node_details-node_type = mc_node_type_a.
        CALL METHOD validate_associations( iv_node_key ).
*     Validate Joins
      ELSEIF ls_node_details-node_type = mc_node_type_j.
        CALL METHOD validate_joins( iv_node_key ).
*     Validate Referential Constraints
      ELSEIF ls_node_details-node_type = mc_node_type_r.
        CALL METHOD validate_ref_constraints( iv_node_key ).
*     Validate Selection Constraints
      ELSEIF ls_node_details-node_type = mc_node_type_s.
        CALL METHOD validate_sel_constraints( iv_node_key ).
*     Validate Parameters
      ELSEIF ls_node_details-node_type = mc_node_type_s.
        CALL METHOD validate_parameters( iv_node_key ).
      ENDIF.
    ELSE.
*     Validate Entities
      CALL METHOD validate_entity( iv_node_key ).
*     Validate Elements
      CALL METHOD validate_elements( iv_node_key ).
*     Validate Associations
      CALL METHOD validate_associations( iv_node_key ).
*     Validate Joins
      CALL METHOD validate_joins( iv_node_key ).
*     Validate Referential Constraints
      CALL METHOD validate_ref_constraints( iv_node_key ).
*     Validate Selection Constraints
      CALL METHOD validate_sel_constraints( iv_node_key ).
*     Validate Parameters
      CALL METHOD validate_parameters( iv_node_key ).
    ENDIF.
  ENDMETHOD.


  method VALIDATE_PARAMETERS.
  endmethod.


  method VALIDATE_REF_CONSTRAINTS.
  endmethod.


  method VALIDATE_SEL_CONSTRAINTS.
  endmethod.
ENDCLASS.
