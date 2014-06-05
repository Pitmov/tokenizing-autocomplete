FUNCTION render(p_item                IN apex_plugin.t_page_item,
                p_plugin              IN apex_plugin.t_plugin,
                p_value               IN VARCHAR2,
                p_is_readonly         IN BOOLEAN,
                p_is_printer_friendly IN BOOLEAN)
  RETURN apex_plugin.t_page_item_render_result IS
  l_return  apex_plugin.t_page_item_render_result;
  l_cursor  NUMBER;
  l_col_cnt PLS_INTEGER;
  rec_tab   dbms_sql.desc_tab;
  l_sql     VARCHAR2(32000);
  l_name    VARCHAR2(30);
  l_lov     VARCHAR2(32000) := p_item.lov_definition;
BEGIN
  --
  apex_javascript.add_library(p_name      => 'jquery.tokeninput',
                              p_directory => p_plugin.file_prefix,
                              p_version   => NULL);
  --
  apex_css.add_file(p_name      => 'token-input-facebook',
                    p_directory => p_plugin.file_prefix,
                    p_version   => NULL);
  --
  l_name := apex_plugin.get_input_name_for_page_item(FALSE);
  htp.p('<input ' || 'name="' || l_name || '" id="' || p_item.name ||
        '" type="text" maxlength="4000" size="30" value="' || p_value ||
        '" class="text_field" />');
  --
  l_cursor := dbms_sql.open_cursor;
  --
  dbms_sql.parse(l_cursor,
                 p_item.lov_definition,
                 dbms_sql.native);
  dbms_sql.describe_columns(l_cursor,
                            l_col_cnt,
                            rec_tab);
  --
  dbms_sql.close_cursor(l_cursor);
  --
  l_sql := 'SELECT ' || rec_tab(1).col_name || ' AS "name", ';
  l_sql := l_sql || rec_tab(2).col_name || ' AS "id" ';
  IF TRIM(p_item.attribute_08) IS NOT NULL
  THEN
    l_lov := regexp_replace(p_item.lov_definition,
                            regexp_replace(TRIM(p_item.attribute_08),
                                           '(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE)',
                                           '?',
                                           1,
                                           0,
                                           'i'),
                            sys.htf.escape_sc(wwv_flow.g_x01),
                            1,
                            1,
                            'i');
  END IF;
  l_sql := l_sql || 'FROM ( ' || l_lov || ' ) ';
  l_sql := l_sql || 'WHERE INSTR( '','' || ''' ||
           sys.htf.escape_sc(p_value) || ''' || '','', '','' || "' || rec_tab(2)
          .col_name || '" || '','', 1 ) > 0';
  htp.p('<script> ' || p_item.name || '_data =');
  apex_util.json_from_sql(l_sql);
  htp.p(';');
  htp.p('</script>');
  --
  apex_javascript.add_onload_code('$( "#' || p_item.name || '").tokenInput( "wwv_flow.show",{
  hintText: "' || p_item.attribute_02 || '",
  noResultsText: "' ||
                                  p_item.attribute_03 || '",
  searchingText: "' ||
                                  p_item.attribute_04 || '",
  pluginId: "' ||
                                  apex_plugin.get_ajax_identifier || '",
  allowNewValues: ' || CASE WHEN
                                  upper(p_item.attribute_05) LIKE 'T%' THEN
                                  'true' ELSE 'false'
                                  END || ',
  canCreate: ' || CASE WHEN
                                  upper(p_item.attribute_05) LIKE 'T%' THEN
                                  'true' ELSE 'false'
                                  END || ',
  createText: "' || p_item.attribute_06 || '",
  createIdentifier: "[NEW]",
  jsonContainer: "row",
  initialValues: ' || p_item.name ||
                                  '_data.row,
  queryParam: "p_flow_id=' || v('APP_ID') ||
                                  '&p_flow_step_id=' || v('APP_PAGE_ID') ||
                                  '&p_instance=' || v('APP_SESSION') ||
                                  '&p_request=PLUGIN=' ||
                                  apex_plugin.get_ajax_identifier ||
                                  '&x01" } );');
  --
  RETURN l_return;
  --
END render;

FUNCTION ajax(p_item   IN apex_plugin.t_page_item,
              p_plugin IN apex_plugin.t_plugin)
  RETURN apex_plugin.t_page_item_ajax_result IS
  l_return  apex_plugin.t_page_item_ajax_result;
  l_cursor  INTEGER;
  l_col_cnt PLS_INTEGER;
  l_rec_tab dbms_sql.desc_tab;
  l_sql     VARCHAR2(32000);
  l_lov     VARCHAR2(32000) := p_item.lov_definition;
BEGIN
  wwv_flow.g_x01 := REPLACE(wwv_flow.g_x01,
                            '''',
                            '''''');
  wwv_flow.g_x02 := REPLACE(wwv_flow.g_x02,
                            '''',
                            '''''');
  --
  l_cursor := dbms_sql.open_cursor;
  --
  dbms_sql.parse(l_cursor,
                 p_item.lov_definition,
                 dbms_sql.native);
  dbms_sql.describe_columns(l_cursor,
                            l_col_cnt,
                            l_rec_tab);
  --
  dbms_sql.close_cursor(l_cursor);
  --
  l_sql := 'SELECT ' || l_rec_tab(2).col_name || ' AS "id", ';
  l_sql := l_sql || l_rec_tab(1).col_name || ' AS "name" ';
  IF TRIM(p_item.attribute_08) IS NOT NULL
  THEN
    l_lov := regexp_replace(p_item.lov_definition,
                            regexp_replace(TRIM(p_item.attribute_08),
                                           '(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE)',
                                           '?',
                                           1,
                                           0,
                                           'i'),
                            sys.htf.escape_sc(wwv_flow.g_x01),
                            1,
                            1,
                            'i');
  END IF;
  l_sql := l_sql || 'FROM ( ' || l_lov || ' ) ';
  --
  IF wwv_flow.g_x02 IS NULL
  THEN
    IF upper(nvl(p_item.attribute_01,
                 'F')) LIKE 'F%'
    THEN
      l_sql := l_sql || 'WHERE UPPER(' || l_rec_tab(1).col_name || ' ) ';
      l_sql := l_sql || ' LIKE  ''%' ||
               upper(sys.htf.escape_sc(wwv_flow.g_x01)) || '%'' ';
    ELSE
      l_sql := l_sql || 'WHERE ' || l_rec_tab(1).col_name;
      l_sql := l_sql || ' LIKE ''%' || sys.htf.escape_sc(wwv_flow.g_x01) ||
               '%'' ';
    END IF;
    --
    IF p_item.attribute_07 IS NOT NULL
    THEN
      l_sql := l_sql || 'AND ROWNUM <= ' || p_item.attribute_07 || ' ';
    END IF;
    --
    l_sql := l_sql || 'ORDER BY 2';
    --
    apex_util.json_from_sql(l_sql);
  ELSE
    l_sql := l_sql || 'WHERE ' || l_rec_tab(2).col_name;
    l_sql := l_sql ||
             ' in (select cast(column_value as varchar2(400)) col from xmltable(''' ||
             sys.htf.escape_sc(wwv_flow.g_x02) || ''')) ';
    --
    l_sql := l_sql || 'ORDER BY 2';
    --
    apex_util.json_from_sql(l_sql);
  END IF;
  --
  RETURN l_return;
  --
END ajax;
