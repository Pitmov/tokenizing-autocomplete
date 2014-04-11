FUNCTION RENDER (
    P_ITEM                IN APEX_PLUGIN.T_PAGE_ITEM,
    P_PLUGIN              IN APEX_PLUGIN.T_PLUGIN,
    P_VALUE               IN VARCHAR2,
    P_IS_READONLY         IN BOOLEAN,
    P_IS_PRINTER_FRIENDLY IN BOOLEAN )
  RETURN APEX_PLUGIN.T_PAGE_ITEM_RENDER_RESULT
IS
  L_RETURN APEX_PLUGIN.T_PAGE_ITEM_RENDER_RESULT;
  L_CURSOR NUMBER;
  L_COL_CNT PLS_INTEGER;
  REC_TAB DBMS_SQL.DESC_TAB;
  L_SQL VARCHAR2(32000);
  L_NAME VARCHAR2 ( 30 );
  L_LOV  VARCHAR2 ( 32000 ) := P_ITEM.LOV_DEFINITION; 
BEGIN
  --
  APEX_JAVASCRIPT.ADD_LIBRARY ( 
   P_NAME => 'jquery.tokeninput', 
   P_DIRECTORY => P_PLUGIN.FILE_PREFIX, 
   P_VERSION => NULL ) ;
  --
  APEX_CSS.ADD_FILE ( 
   P_NAME => 'token-input-facebook', 
   P_DIRECTORY => P_PLUGIN.FILE_PREFIX, 
   P_VERSION => NULL ) ;
  --
  L_NAME := APEX_PLUGIN.GET_INPUT_NAME_FOR_PAGE_ITEM ( FALSE ) ;
  HTP.P ( '<input ' || 'name="' || L_NAME ||'" id="' || P_ITEM.NAME ||'" type="text" maxlength="4000" size="30" value="'||P_VALUE||'" class="text_field" />' ) ;
  --
  L_CURSOR := DBMS_SQL.OPEN_CURSOR;
  --
  DBMS_SQL.PARSE ( L_CURSOR, P_ITEM.LOV_DEFINITION, DBMS_SQL.NATIVE ) ;
  DBMS_SQL.DESCRIBE_COLUMNS ( L_CURSOR, L_COL_CNT, REC_TAB ) ;
  --
  DBMS_SQL.CLOSE_CURSOR ( L_CURSOR ) ;
  --
  L_SQL := 'SELECT ' || REC_TAB ( 1 ).COL_NAME || ' AS "name", ';
  L_SQL := L_SQL || REC_TAB ( 2 ).COL_NAME || ' AS "id" ';
  IF TRIM (P_ITEM.ATTRIBUTE_08) IS NOT NULL THEN
    L_LOV := REGEXP_REPLACE (P_ITEM.LOV_DEFINITION, REGEXP_REPLACE (TRIM (P_ITEM.ATTRIBUTE_08), '(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE)', '?', 1, 0, 'i'), SYS.HTF.ESCAPE_SC ( WWV_FLOW.G_X01 ), 1, 1, 'i');
  END IF;
  L_SQL := L_SQL || 'FROM ( ' || L_LOV || ' ) '; 
  L_SQL := L_SQL || 'WHERE INSTR( '','' || ''' || SYS.HTF.ESCAPE_SC ( P_VALUE ) || ''' || '','', '','' || "' || REC_TAB ( 2 ).COL_NAME || '" || '','', 1 ) > 0';
  HTP.P ( '<script> ' || P_ITEM.NAME ||'_data =' );
  APEX_UTIL.JSON_FROM_SQL ( L_SQL ) ;
  HTP.P ( ';' );
  HTP.P ( '</script>' ) ;
  --
  APEX_JAVASCRIPT.ADD_ONLOAD_CODE ( '$( "#' || P_ITEM.NAME || '").tokenInput( "wwv_flow.show",{
  hintText: "'      || P_ITEM.ATTRIBUTE_02 || '",
  noResultsText: "' || P_ITEM.ATTRIBUTE_03 || '",
  searchingText: "' || P_ITEM.ATTRIBUTE_04 || '",
  pluginId: "' ||apex_plugin.get_ajax_identifier || '",
  allowNewValues: '|| CASE WHEN UPPER( P_ITEM.ATTRIBUTE_05 ) LIKE 'T%' THEN 'true' ELSE 'false' END || ',
  canCreate: '     || CASE WHEN UPPER( P_ITEM.ATTRIBUTE_05 ) LIKE 'T%' THEN 'true' ELSE 'false' END || ',
  createText: "'    || P_ITEM.ATTRIBUTE_06 || '",
  createIdentifier: "[NEW]",
  jsonContainer: "row",
  initialValues: ' || P_ITEM.NAME || '_data.row,
  queryParam: "p_flow_id=' || V ( 'APP_ID' ) || '&p_flow_step_id=' || V ( 'APP_PAGE_ID' ) || '&p_instance=' || V ( 'APP_SESSION' ) || '&p_request=PLUGIN=' || APEX_PLUGIN.GET_AJAX_IDENTIFIER || '&x01" } );' );
  --
  RETURN L_RETURN;
  --
END RENDER;

FUNCTION AJAX (
    P_ITEM   IN APEX_PLUGIN.T_PAGE_ITEM,
    P_PLUGIN IN APEX_PLUGIN.T_PLUGIN )
  RETURN APEX_PLUGIN.T_PAGE_ITEM_AJAX_RESULT
IS
  L_RETURN APEX_PLUGIN.T_PAGE_ITEM_AJAX_RESULT;
  L_CURSOR  INTEGER;
  L_COL_CNT PLS_INTEGER;
  L_REC_TAB DBMS_SQL.DESC_TAB;
  L_SQL     VARCHAR2 ( 32000 ) ;
  L_LOV  VARCHAR2 ( 32000 ) := P_ITEM.LOV_DEFINITION;
BEGIN
  --
  L_CURSOR := DBMS_SQL.OPEN_CURSOR;
  --
  DBMS_SQL.PARSE ( L_CURSOR, P_ITEM.LOV_DEFINITION, DBMS_SQL.NATIVE ) ;
  DBMS_SQL.DESCRIBE_COLUMNS ( L_CURSOR, L_COL_CNT, L_REC_TAB ) ;
  --
  DBMS_SQL.CLOSE_CURSOR ( L_CURSOR ) ;
  --
  L_SQL := 'SELECT ' || L_REC_TAB( 2 ).COL_NAME || ' AS "id", ';
  L_SQL := L_SQL || L_REC_TAB( 1 ).COL_NAME || ' AS "name" ';
  IF TRIM (P_ITEM.ATTRIBUTE_08) IS NOT NULL THEN
    L_LOV := REGEXP_REPLACE (P_ITEM.LOV_DEFINITION, REGEXP_REPLACE (TRIM (P_ITEM.ATTRIBUTE_08), '(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE)', '?', 1, 0, 'i'), SYS.HTF.ESCAPE_SC ( WWV_FLOW.G_X01 ), 1, 1, 'i');
  END IF;
  L_SQL := L_SQL || 'FROM ( ' || L_LOV || ' ) '; 
  --
  IF UPPER( NVL( P_ITEM.ATTRIBUTE_01, 'F' ) ) LIKE 'F%' THEN    
    L_SQL := L_SQL || 'WHERE UPPER(' || L_REC_TAB( 1 ).COL_NAME || ' ) ';
    L_SQL := L_SQL || ' LIKE  ''%' || UPPER(SYS.HTF.ESCAPE_SC ( WWV_FLOW.G_X01 )) || '%'' ';
  ELSE
    L_SQL := L_SQL || 'WHERE ' || L_REC_TAB( 1 ).COL_NAME;
    L_SQL := L_SQL || ' LIKE ''%' || SYS.HTF.ESCAPE_SC ( WWV_FLOW.G_X01 ) || '%'' ';
  END IF;
  --
  IF P_ITEM.ATTRIBUTE_07 IS NOT NULL THEN
    L_SQL := L_SQL || 'AND ROWNUM <= ' || P_ITEM.ATTRIBUTE_07 || ' ' ;
  END IF;
  --
  L_SQL := L_SQL || 'ORDER BY 2';
  --
  APEX_UTIL.JSON_FROM_SQL ( L_SQL ) ;
  --
  RETURN L_RETURN;
  --
END AJAX;
