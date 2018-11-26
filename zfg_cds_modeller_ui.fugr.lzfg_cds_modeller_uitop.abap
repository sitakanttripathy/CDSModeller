FUNCTION-POOL zfg_cds_modeller_ui.          "MESSAGE-ID ..

* Local Class Definitions and Implementations
CLASS lcl_grid_events DEFINITION.
  PUBLIC SECTION.
    METHODS:
      on_link_click      FOR EVENT link_click OF cl_salv_events_table
        IMPORTING row column,
      on_checkbox_change FOR EVENT checkbox_change OF cl_salv_events_tree
        IMPORTING columnname node_key checked,
      on_expand_empty_folder FOR EVENT expand_empty_folder OF cl_salv_events_tree
        IMPORTING node_key.
ENDCLASS.

TYPES:
  BEGIN OF ty_field_list,
    mark TYPE select.
    INCLUDE STRUCTURE dfies.
TYPES: END OF ty_field_list.

DATA: gv_no_details       TYPE abap_bool,
      gv_display_assoc    TYPE abap_bool,
      gv_display_elements TYPE abap_bool,
      gv_select_assoc     TYPE abap_bool,
      gv_select_elements  TYPE abap_bool.

DATA: gv_event          TYPE sy-ucomm,
      gv_cancelled      TYPE abap_bool,
      gv_req_node_type  TYPE z_de_node_type,
      gv_source_type    TYPE abap_bool VALUE 'T',
      gs_ddddlsource    TYPE ddddlsrc,
      gs_data_source    TYPE zcds_data_source_capture,
      gt_fieldlist      TYPE ddfields,
      gt_fieldlist_mark TYPE STANDARD TABLE OF ty_field_list,
      gt_selection_tree TYPE STANDARD TABLE OF zcds_assoc_selection.

DATA: BEGIN OF gs_source_type,
        table TYPE xflag VALUE 'X',
        view  TYPE xflag,
        cds   TYPE xflag,
      END OF gs_source_type.

DATA: gr_cds_modeller      TYPE REF TO zcl_cds_modeller,
      gr_view_builder      TYPE REF TO zcl_cds_view_builder_tree,
      gr_view_builder_grid TYPE REF TO zcl_cds_view_builder_grid,
      gr_cds_annot_tree    TYPE REF TO zcl_cds_annot_tree,
      gr_cds_annot_grid    TYPE REF TO zcl_cds_annot_grid,
      gr_selection_cont    TYPE REF TO cl_gui_custom_container,
      gr_selection_grid    TYPE REF TO cl_salv_table,
      gr_selection_tree    TYPE REF TO cl_salv_tree,
      gr_grid_events       TYPE REF TO lcl_grid_events.
