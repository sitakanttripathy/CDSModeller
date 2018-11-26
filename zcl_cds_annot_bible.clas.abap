class ZCL_CDS_ANNOT_BIBLE definition
  public
  final
  create private .

public section.

  types:
    BEGIN OF ty_annot_linear,
        annot       TYPE if_dd_ddl_types=>ty_s_annotation_definition,
        linear_defs TYPE cl_ddl_annot_def_parser=>tt_annot_def,
      END   OF ty_annot_linear .
  types:
    tt_annot_linear TYPE STANDARD TABLE OF ty_annot_linear WITH KEY annot-annotation_upper .
  types:
    BEGIN OF ty_annot_scopes,
        scope TYPE string,
*             linear_defs TYPE cl_ddl_annot_def_parser=>tt_annot_def,
        annot TYPE tt_annot_linear,
      END   OF ty_annot_scopes .
  types:
    tt_annot_scopes TYPE STANDARD TABLE OF ty_annot_scopes .

  data MT_PARSED_LINEAR_DDL type TT_ANNOT_LINEAR .
  data MT_PARSED_LINEAR_DCL type TT_ANNOT_LINEAR .

  class-methods GET_INSTANCE
    returning
      value(ER_ANNOT_BIBLE) type ref to ZCL_CDS_ANNOT_BIBLE .
  methods GET_ANNOT_SCOPED
    importing
      !IV_SCOPE type STRING optional
    exporting
      value(ET_ANNOT_DEFS_SCOPED) type TT_ANNOT_SCOPES .
  methods GET_SCOPED_ANNOTATIONS
    importing
      !IV_ANNOT_SCOPE type STRING optional
    returning
      value(ES_ANNOTATIONS) type TY_ANNOT_SCOPES .
protected section.

  data MT_ANNOT_DEFS_DDL type IF_DD_DDL_TYPES=>TY_T_ANNOTATION_DEFINITIONS .
  data MT_ANNOT_DEFS_SCOPED type TT_ANNOT_SCOPES .
  data MT_ANNOT_DEFS_DCL type IF_DD_DDL_TYPES=>TY_T_ANNOTATION_DEFINITIONS .
private section.

  class-data MR_ANNOT_BIBLE type ref to ZCL_CDS_ANNOT_BIBLE .

  methods CONSTRUCTOR .
  methods PARSE_ANNOTATIONS .
  methods LOAD_GENERIC_ANNOT .
  methods LOAD_DCL_ANNOT .
  methods PREPARE_SCOPE .
ENDCLASS.



CLASS ZCL_CDS_ANNOT_BIBLE IMPLEMENTATION.


  METHOD constructor.
*   Instantiate DL Generic Annotaions
    CALL METHOD me->load_generic_annot.
*   Instantiate DCL Annotations
    CALL METHOD me->load_dcl_annot.
*   Call the Annotation Parser to simplify annotation attributes
    CALL METHOD me->parse_annotations.

    CALL METHOD me->prepare_scope.
  ENDMETHOD.


  METHOD get_annot_scoped.
*   Identify annotations based on scope and pass them back
    IF iv_scope IS NOT INITIAL.
      APPEND INITIAL LINE TO et_annot_defs_scoped ASSIGNING FIELD-SYMBOL(<fs_annot_scoped>).
*     Check for scoped annotations
      READ TABLE mt_annot_defs_scoped INTO DATA(ls_annot_defs_scoped)
           WITH KEY scope = iv_scope.

      CHECK sy-subrc EQ 0.
      <fs_annot_scoped> = ls_annot_defs_scoped.
    ELSE.
*     Pass everythign back
      APPEND LINES OF mt_annot_defs_scoped TO et_annot_defs_scoped.
    ENDIF.
  ENDMETHOD.


  METHOD get_instance.
*   Instantiate and store referece if required
    IF mr_annot_bible IS INITIAL.
      mr_annot_bible = NEW zcl_cds_annot_bible( ).
    ENDIF.
    er_annot_bible = mr_annot_bible.
  ENDMETHOD.


  METHOD get_scoped_annotations.
*   Pass annotations relevant to the scope
    READ TABLE mt_annot_defs_scoped INTO es_annotations
         WITH KEY scope = iv_annot_scope.
  ENDMETHOD.


  METHOD LOAD_DCL_ANNOT.
*   Instantiate and load DCL Annotations
    DATA(lr_dcl_annotations) = NEW cl_acm_dcl_annotations( ).

    lr_dcl_annotations->get_annotation_definitions(
                      EXPORTING i_type   = if_dd_annotation_types=>co_annotation_type-any
                      IMPORTING e_result = DATA(lt_dcl_defs) ).

    APPEND LINES OF lt_dcl_defs TO mt_annot_defs_dcl.
  ENDMETHOD.


  METHOD LOAD_GENERIC_ANNOT.
*  Instantiate and load the generic annotations
    TRY.
        DATA(l_generic_annotations) = NEW cl_dd_ddl_generic_annotations( ).

        CALL METHOD l_generic_annotations->('GET_ANNOTATION_DEFINITIONS')
          EXPORTING
            i_type   = `ANY`
          IMPORTING
            e_result = mt_annot_defs_ddl.
      CATCH cx_sy_dyn_call_error.

        DATA(l_ddl_handler) = cl_dd_ddl_handler_factory=>create( ).
        l_ddl_handler->get_annotations( IMPORTING annotations = DATA(lt_annotations)
                                                  annotation_definitions = mt_annot_defs_ddl ).
    ENDTRY.

  ENDMETHOD.


  METHOD parse_annotations.

    DATA: ls_annot_linear TYPE ty_annot_linear.

*   Instantiate Parser
    DATA(lr_parser) = NEW cl_ddl_annot_def_parser( ).

*   Parse CDS Annotations
    LOOP AT mt_annot_defs_ddl ASSIGNING FIELD-SYMBOL(<fs_annot_defs>).
*     Parse clumsy annotation definitions
      lr_parser->parse(
          EXPORTING
            source     = <fs_annot_defs>-definition
          IMPORTING
            annot_defs = DATA(lt_parsed_annot) ).

      CLEAR ls_annot_linear.
      ls_annot_linear = VALUE #( annot       = <fs_annot_defs>
                                 linear_defs = lt_parsed_annot ).
      APPEND ls_annot_linear TO mt_parsed_linear_ddl.
    ENDLOOP.

*   Parse DCL Annotations
    UNASSIGN <fs_annot_defs>.
    LOOP AT mt_annot_defs_dcl ASSIGNING <fs_annot_defs>.
*     Parse clumsy annotation definitions
      lr_parser->parse(
          EXPORTING
            source     = <fs_annot_defs>-definition
          IMPORTING
            annot_defs = lt_parsed_annot ).

      CLEAR ls_annot_linear.
      ls_annot_linear = VALUE #( annot       = <fs_annot_defs>
                                 linear_defs = lt_parsed_annot ).
      APPEND ls_annot_linear TO mt_parsed_linear_dcl.
    ENDLOOP.
  ENDMETHOD.


  METHOD prepare_scope.
*   This method will read all the DDL annotations and segment
*   them based on the scope

    FIELD-SYMBOLS:
       <fs_annot_details_new> type ty_annot_linear.

*   Scan individual Linear Defs
    LOOP AT mt_parsed_linear_ddl INTO DATA(ls_parsed_ddl).
*     Scan Tokens within Linear Defs
      LOOP AT ls_parsed_ddl-linear_defs INTO DATA(ls_linear_defs).
*       Scan Scopes within individual tokens to segragate them
        LOOP AT ls_linear_defs-scopes INTO DATA(ls_scopes).

*         Save Local copy
          DATA(ls_linear_defs_copy) = ls_linear_defs.

*         Check is Scope is already available
          READ TABLE mt_annot_defs_scoped ASSIGNING FIELD-SYMBOL(<fs_annot_scoped>)
               WITH KEY scope = ls_scopes-lexem.
          IF sy-subrc NE 0.
*           Set Annotation Scope
            APPEND INITIAL LINE TO mt_annot_defs_scoped ASSIGNING <fs_annot_scoped>.
            <fs_annot_scoped>-scope       = ls_scopes-lexem.

*           Set Annotation Details
            APPEND INITIAL LINE TO <fs_annot_scoped>-annot
                             ASSIGNING <fs_annot_details_new>.
            <fs_annot_details_new>-annot = ls_parsed_ddl-annot.
            APPEND ls_linear_defs TO <fs_annot_details_new>-linear_defs.
          ELSE.
*           Check if the annotation key is already available
            READ TABLE <fs_annot_scoped>-annot ASSIGNING FIELD-SYMBOL(<fs_annot_details>)
                 WITH KEY annot-annotation_upper = ls_parsed_ddl-annot-annotation_upper.
            IF sy-subrc EQ 0.
*             Set the linear Definitions
              APPEND  ls_linear_defs TO <fs_annot_details>-linear_defs.
            ELSE.
*             Set Annotation Scope
              APPEND INITIAL LINE TO <fs_annot_scoped>-annot
                             ASSIGNING <fs_annot_details_new>.
              <fs_annot_details_new>-annot = ls_parsed_ddl-annot.
              APPEND ls_linear_defs TO <fs_annot_details_new>-linear_defs.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
