class ZCL_CDS_EXCP_MANAGER definition
  public
  inheriting from CL_RECA_MESSAGE_LIST
  final
  create public .

public section.

  class-methods RAISE_EXCEPTION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_CDS_EXCP_MANAGER IMPLEMENTATION.


  method RAISE_EXCEPTION.
  endmethod.
ENDCLASS.
