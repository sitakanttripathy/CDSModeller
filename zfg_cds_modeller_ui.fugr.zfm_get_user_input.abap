FUNCTION zfm_get_user_input.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_CALL_TYPE) TYPE  SY-UCOMM
*"     REFERENCE(IV_REQ_NODE_TYPE) TYPE  Z_DE_NODE_TYPE OPTIONAL
*"  EXPORTING
*"     REFERENCE(ES_DDL_DETAILS) TYPE  DDDDLSRC
*"     REFERENCE(EV_CANCELLED) TYPE  ABAP_BOOL
*"  CHANGING
*"     REFERENCE(CS_DATA_SOURCE) TYPE  ZCDS_DATA_SOURCE_CAPTURE
*"       OPTIONAL
*"----------------------------------------------------------------------

  CASE iv_call_type.
*   Get View Name
    WHEN 'VIEW'.
      CALL SCREEN '9001' STARTING AT 40 5
                         ENDING   AT 110 9.

      es_ddl_details = gs_ddddlsource.
      CLEAR gs_ddddlsource.

*   Get Data Source
    WHEN 'SOURCE'.

*     Set Source Details provided
      gs_data_source = cs_data_source.

*     Set Requesting Node Type and relevant context
      gv_req_node_type = iv_req_node_type.
      PERFORM set_selection_context.
      CASE gv_req_node_type.
*       For Associations and Joins
        WHEN zcl_cds_modeller=>mc_node_type_a OR zcl_cds_modeller=>mc_node_type_j.
          CALL SCREEN '9002' STARTING AT 40 5
                             ENDING   AT 110 9.
*       For Other Dsplay in extended size
        WHEN OTHERS.
          CALL SCREEN '9002' STARTING AT 10 1
                             ENDING   AT 180 25.
      ENDCASE.


      cs_data_source = gs_data_source.
      CLEAR gs_data_source.
  ENDCASE.

* Set Operation cancelled flag
  ev_cancelled = gv_cancelled.
  PERFORM refresh_all.
ENDFUNCTION.
