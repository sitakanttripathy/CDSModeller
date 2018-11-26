*&---------------------------------------------------------------------*
*& Include          LZFG_CDS_MODELLER_UIP01
*&---------------------------------------------------------------------*
CLASS lcl_grid_events IMPLEMENTATION.
  METHOD on_link_click.

    READ TABLE gt_fieldlist_mark ASSIGNING FIELD-SYMBOL(<fs_fieldlist_mark>)
         INDEX row.
    IF <fs_fieldlist_mark> IS ASSIGNED.
*     Not Marked: Mark it
      IF <fs_fieldlist_mark>-mark IS INITIAL.
        <fs_fieldlist_mark>-mark = abap_true.
*     Already Marked: Unmark it
      ELSE.
        CLEAR <fs_fieldlist_mark>-mark.
      ENDIF.
    ENDIF.

*   Refresh ALV Display
    CALL METHOD gr_selection_grid->refresh( ).

  ENDMETHOD.

  METHOD on_checkbox_change.

*   Update Association and Elements Selection
    READ TABLE gt_selection_tree ASSIGNING FIELD-SYMBOL(<fs_selection_tree>)
         WITH KEY node_key = node_key.
    IF sy-subrc EQ 0.
      <fs_selection_tree>-select = checked.
    ENDIF.

  ENDMETHOD.


  METHOD on_expand_empty_folder.

*   Get the association target for the selected node
    CHECK node_key IS NOT INITIAL.
    READ TABLE gt_selection_tree INTO DATA(ls_assoc_selection)
                                 WITH KEY node_key = node_key.

    IF sy-subrc EQ 0.
*     Add Association Elements
      IF gv_display_elements EQ abap_true.
        PERFORM add_association_elements USING ls_assoc_selection.
      ENDIF.

*     Add Child Association and Elements
      IF gv_display_assoc EQ abap_true.
        PERFORM add_associations USING ls_assoc_selection-target
                                       ls_assoc_selection-node_key.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
