* Autor      : Ailson Luis                            Data: 18/01/2022 *

                                                                     *
report zqmr0004.

class lcl_app definition.
  public section.

    types:
      begin of ty_sel,
        matnr type matnr,
        werks type werks_d,
        lgort type lgort_d,
        mtart type mtart,
        sobkz type sobkz,
        days  type int4,

      end of ty_sel,

      begin of ty_alv,
        matnr	                  type matnr,
        werks	                  type werks_d,
        materialdescription	    type maktx,
        materialbaseunit        type meins,
        materialtype            type mtart,
        lgort_sid	              type nsdm_lgort,
        charg_sid	              type nsdm_charg,
        sobkz	                  type sobkz,
        lifnr_sid	              type nsdm_lifnr,
        vendor                  type /b631/oivendor,
        kunnr_sid	              type nsdm_kunnr,
        custumer                type /b631/oicustomer,
        lbbsa_sid	              type NSDM_LBBSA,
        txtlbbsa                type char30,
        stock                   type menge_d,
        batchbysupplier	        type lichn,
        manufacturedate	        type hsdat,
        shelflifeexpirationdate	type vfdat,
        prazovalidade           type int4,
        diasvencimento          type int4,
        dataatual               type dats,
        status                  type icon_d,
      end of ty_alv.



    class-data r_sel type ref to ty_sel.


    data:
      gt_data type table of zddl_stockactual,
      gt_alv  type table of ty_Alv,
      r_alv   type ref to cl_salv_table.

    data:
      rg_matnr type range of matnr,
      rg_werks type range of werks_d,
      rg_lgort type range of lgort_d,
      rg_mtart type range of mtart,
      rg_days  type range of int4,
      p_check  type flag,
      p_venc   type flag.


    methods start.

    methods show_alv.



endclass.

class lcl_app implementation.


  method start.



    select *

       from zddl_stockactual
      into corresponding fields of table @gt_alv
      where matnr in @rg_matnr
        and werks in @rg_werks
        and lgort_sid in @rg_lgort
        and diasvencimento in @rg_days
        and stock > 0 .

     select * from DD07T
        into table @data(lt_txtlbbsa)
        where domname = 'NSDM_LBBSA'
       and ddlanguage = @sy-langu.


    "Considerar apenas materiais administrados por lote
    if p_check eq abap_true.
      delete gt_alv where charg_sid is initial.
    endif.

    loop at gt_alv ASSIGNING FIELD-SYMBOL(<fs_data>).
      if <fs_data>-diasvencimento < 0 .
        <fs_data>-status =  ICON_LED_RED.
      else.
        <fs_data>-status =  ICON_LED_GREEN.
      endif.
      try.
        <fs_data>-txtlbbsa = lt_txtlbbsa[ domvalue_l = <fs_data>-lbbsa_sid ]-ddtext.
      catch cx_sy_itab_line_not_found.
      endtry.
    ENDLOOP.

    "Remove lotes no prazo, para listar somente os vencidos
    if p_venc is not INITIAL.
      delete gt_alv where diasvencimento >=  0.
    endif.

    if gt_alv is initial.
      message |Dados não encontrados| type 'S' display like 'E'.
      exit.
    endif.



    show_alv( ).
  endmethod.


  method show_alv.
    data: r_events     type ref to cl_salv_events_table,
          r_selections type ref to cl_salv_selections,
          r_columns    type ref to cl_salv_columns_table,
          r_column     type ref to cl_salv_column,
          lr_layout    type ref to cl_salv_layout,
          ls_key       type salv_s_layout_key.
    try.
*       Monta lista ALV de acordo com a tabela GT_CTE:
        cl_salv_table=>factory(
          exporting
            list_display   = if_salv_c_bool_sap=>false
            "r_container    =
            "container_name = 'Name'
          importing
            r_salv_table   = r_alv
          changing
            t_table        =  gt_alv ).


      catch cx_salv_msg.

    endtry.


* * Layouts
    lr_layout = r_alv->get_layout( ).
    ls_key-report = sy-repid.
    lr_layout->set_key( ls_key ).
    lr_layout->set_default( if_salv_c_bool_sap=>true ).
    lr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

*
    data(r_functions) = r_alv->get_functions( ).
    r_functions->set_all( abap_true ).



*   Seleção das linhas:
    r_selections = r_alv->get_selections( ).
    r_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

*   Seta eventos
    " r_events = r_alv->get_event( ).
    " set handler on_user_command for r_events.

    r_columns = r_alv->get_columns( ).
    r_columns->set_optimize( 'X' ).
    try.

        r_column = r_columns->get_column( 'STOCK' ).
        r_column->set_long_text( |Saldo|  ).
        r_column->set_short_text( |Saldo|  ).
        r_column->set_medium_text( |Saldo| ).


        r_column = r_columns->get_column( 'PRAZOVALIDADE' ).
        r_column->set_long_text( |Prazo de Validade em dias|  ).
        r_column->set_short_text( |PrzValidade|  ).
        r_column->set_medium_text( |Prazo de Validade em dias| ).

        r_column = r_columns->get_column( 'DIASVENCIMENTO' ).
        r_column->set_long_text( | Vencimento em dias |  ).
        r_column->set_short_text( | Vencimento em dias| ).
        r_column->set_medium_text( | Vencimento em dias| ).

        r_column = r_columns->get_column( 'DATAATUAL' ).
        r_column->set_long_text( | Data Atual |  ).
        r_column->set_short_text( | Data Atual| ).
        r_column->set_medium_text( | Data Atual| ).

        r_column = r_columns->get_column( 'STATUS' ).
        r_column->set_long_text( | Status |  ).
        r_column->set_short_text( | Status| ).
        r_column->set_medium_text( | Status| ).

        r_column = r_columns->get_column( 'TXTLBBSA' ).
        r_column->set_long_text( |Txt.Tipo Estoque|  ).
        r_column->set_short_text( |Txt.Tipo Estoque| ).
        r_column->set_medium_text( |Txt.Tipo Estoque| ).



      catch cx_salv_not_found .
        " error handling
    endtry.

*   Exibe:
    r_alv->display( ).
  endmethod.

endclass.


selection-screen begin of block b1 with frame title text-t01.

  select-options:
                 s_werks for lcl_app=>r_sel->werks  obligatory ,
                 s_lgort for lcl_app=>r_sel->lgort,
                 s_mtart for lcl_app=>r_sel->mtart ,
                 s_matnr for lcl_app=>r_sel->matnr.


selection-screen end of block b1.


selection-screen begin of block b3 with frame title text-t03.

  parameters:  p_chkbx1 as checkbox default ''.
  parameters:  p_chkbx2 as checkbox default ''.
  select-options:s_days for lcl_app=>r_sel->days  no-extension.
selection-screen end of block b3.


start-of-selection.

  data r_app type ref to lcl_app.


  r_app = new lcl_app( ).

  r_app->rg_werks = s_werks[].
  r_app->rg_matnr = s_matnr[].
  r_app->rg_mtart = s_mtart[].

  r_app->rg_days = s_days[].
  "r_app->pr_price = p_price.
  r_app->p_check = p_chkbx1.
  r_app->p_venc = p_chkbx2.
  r_app->start( ).
