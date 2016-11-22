<%@ Page LANGUAGE="C#" %>
<%@ Import Namespace="xLibrary" %>
<%@ Import Namespace="xLibrary.ScriptHost" %>
<%@ Import Namespace="xLibrary.Directory" %>
<%@ Import Namespace="xLibrary.Data" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="CommonTools" %>
<script runat="server" type="text/C#">

string cProsp = "";


//Funciones
public String getDescTipoCampo(string tipo){
	var t = "";
	switch(tipo){
		case "C": //Caracter
			t = "System.String";
			break;
			
		case "L": //Entero Largo
			t = "System.Int32";
			break;
			
		case "I": //Entero Corto
			t = "System.Int16";
			break;
			
		case "S": //Autonumerico
			t = "System.Int16";
			break;
		
		case "F": //Flotante
			t = "System.Int16";
			break;
			
		case "D": //Fecha
			t = "System.Date";
			break;
		
		case "M": //Memo
			t = "System.String";
			break;
			
		default:
			t = "System.String";
			break;
		
	}
	
	return t;

}

public string crearTablaReports(){
	var sql = "CREATE TABLE  REPORTS ( "+
					  "ID int identity(1,1),"+
					  "FIELDS_EJE_X Varchar( 16 ),"+
					  "FIELDS_EJE_Y Varchar( 2500 ),"+
					  "FIELDS_FILTRO Varchar( 2500 ),"+
					  "NAME Varchar( 100 ),"+
					  "DESCRIPTION Varchar( 250 ),"+
					  "CHART_TYPE Varchar( 100 ),"+
					  "CHART_TITLE Varchar( 200 ),"+
					  "TITLE_EJE_X Varchar( 250 ),"+
					  "TITLE_EJE_Y Varchar( 250 ),"+
					  "CHART_LEGEND Varchar( 150 ),"+
					  "COLOR_TITLE_X Varchar( 50 ),"+
					  "COLOR_TITLE_Y Varchar( 50 ),"+
					  "COLOR_TITLE_CHART Varchar( 50 ),"+
					  "ALTA_USER Varchar( 3 ),"+
					  "UPD_USER Varchar( 3 ),"+
					  "FIELDS_X_GRUPO Varchar( 500 ),"+
					  "FIELDS_Y_GRUPO Varchar( 500 ),"+
					  "ACTIVECHART Varchar( 50 ),"+
					  "ENABLEDCHARTS Varchar( 100 ),"+
					  "SLTVAL_FILTRO Varchar( 2500 ),"+
					  "SLTCONCAT_FILTRO Varchar( 300 ),"+
					  "VALS_FILTRO Varchar( 1500 ),"+
					  "COLOR_FIELD Varchar( 50 ), "+
					  "FX_FIELDS_EJEX Varchar( 30 ), "+
					  "FX_FIELDS_EJEY Varchar( 2500 ), "+
					  "FX_FIELDS_XGRUPO Varchar( 2500 ), "+
					  "FX_FIELDS_YGRUPO Varchar( 2500 ), "+
					  "FX_FIELDS_FILTRO Varchar( 2500 ),"+
					  "FIELDS_DGRUPO Varchar( 2500 ),"+
					  "FX_FIELDS_DGRUPO Varchar( 2500 ),"+
					  "FIELDS_LISTA Varchar( 2500 ),"+
					  "FX_FIELDS_LISTA Varchar( 2500 ));";
					  
	return sql;
}

public string setNewField(string fieldname,string clase_header,string clase_cont, string tbl, DataConn conn)
{
	
	var texto_pregunta = "";
	if(clase_cont != ""){
		var sqlP = "SELECT PREG_TEXTO FROM " + cProsp + "P WITH(NOLOCK) WHERE RAIZ_CAMPO = '" + fieldname + "'";
		DataRs replyP = null;
        DataConn tempConn = null;

        try
        {
            tempConn = conn;
            replyP = tempConn.OpenRecordset(sqlP);
            if (replyP != null)
            {
                while (replyP.Read())
                {
                    if (replyP.GetFieldValue(0) != null)
                        texto_pregunta = String.Empty + replyP.GetFieldValue(0);
                }
            }
        }
        catch (Exception ex)
        {

        }
        finally
        {
            if(replyP !=  null)
                replyP.Dispose();

            /*if (tempConn != null)
            {
                tempConn.Close();
                tempConn.Dispose();
            }*/
        }
            
	}
	
	var html = "<li id=\"" + fieldname+tbl +"\" class=\"widget "+clase_header+" unselected-text\" title=\"Arrastre varias veces para repetir el campo\">"+
					"<div class=\"widget-head left\" style=\"cursor: move;\">"+
						"<input type=\"checkbox\" class=\"chkfield\" onclick=\"setField('"+fieldname+tbl+"', this, true);\">"+
                        "<h3 class='unselected-text'>" + fieldname.ToUpper() + "</h3>" +
					"</div>"+
					"<div class=\"remitem \">"+
						"<a class=\"remove disp_rem\" href=\"#\" onclick=\"removeItem(this)\">Borrar</a>"+
					"</div>"+
					"<div class=\"cleaboth\"></div>";
					
					
	if(texto_pregunta != "" && clase_cont != ""){
		html +=		"<div class=\"" + clase_cont + "\"><p>" + texto_pregunta + "</p></div>";
	}
	
	html += "</li>";

	return html;
}

</script>
<%    

/** Variables para implementacion multilenguaje **/
var LOAD_DATA_FILE_TITLE = "Gestor de Informes Aibe";
var LOAD_DATA_FILE_SUBTITLE = Me.Session.WriteLS("LOAD_DATA_FILE_SUBTITLE");
var LOAD_DATA_FILE_MSG_CLOSE = Me.Session.WriteLS("LOAD_DATA_FILE_MSG_CLOSE");

//VARIABLES GENERALES
var user = (String.Empty + User.Identity.Name).ToUpper();
Me.Session["fieldsType-"+user] = new NameValueCollection(); //para agrupar datos del grafico

// Nombre del fichero de prospectos
cProsp = Me.CurrentDb.ProspectName;

// Identificador de campana (IdScript)
var idScript = Me.IdScript;       	


// Obtenemos CurrentDb
var CurrentDb = Me.GlobalDb.GetCurrentDb(idScript);

var sql = (Tools.GetServerSettings.RDBMSName == BDConn.Sql) ? "SELECT TOP 1 * FROM " + cProsp +" WITH(NOLOCK)": "SELECT * FROM " + cProsp + " WITH(NOLOCK) LIMIT 1";
DataRs reply = null;
reply = CurrentDb.OpenRecordset(sql);
var numFields = 0; 

var fieldsHtml = "";
Dictionary<string, string> fieldsType = new Dictionary<string, string>();
var fieldsTypeCollection = new System.Collections.Specialized.NameValueCollection();
var camposProsp = true;

//consulta de campos de prospectos si la tabla tiene al menos un registro
if(reply.HasRows)
{
    using (DataConn currConn = Me.CurrentDb.GetNewConnection())
    {
        numFields = reply.GetNumFields();
        while (reply.Read())
        {
            for (var i = 0; i < numFields; i++)
            {
                fieldsHtml += setNewField((String.Empty +reply.GetFieldName(i)).ToUpper(), "color-blue", "widget-content", "", currConn);
                fieldsType.Add((String.Empty +reply.GetFieldName(i)).ToUpper(), reply.GetFieldType(i));
                fieldsTypeCollection.Add(("P." + reply.GetFieldName(i)).ToUpper(), reply.GetFieldType(i));
            }
        }
        reply.Dispose();
    }
}
else
{
	camposProsp = false;
}
    reply.Dispose();


//si no se pueden obtener los campos de prospectos, se obtienen de la tabla de preguntas
if(!camposProsp){
	
	sql = "SELECT DISTINCT RAIZ_CAMPO, TIPO_CAMPO FROM "+cProsp+"P WITH(NOLOCK) WHERE RAIZ_CAMPO IS NOT NULL AND RAIZ_CAMPO <> ''";
	reply = null;
	reply = CurrentDb.OpenRecordset(sql);
	numFields = 0; 

	if(reply != null)
	{	
		//numFields = reply.RecordCount();
        numFields = 0;
        using (DataConn currConn = Me.CurrentDb.GetNewConnection())
        {
            while (reply.Read())
            {
                fieldsHtml += setNewField((String.Empty + reply.GetFieldValue(0)).ToUpper(), "color-blue", "widget-content", "", currConn);
                fieldsType.Add((String.Empty + reply.GetFieldValue(0)).ToUpper(), getDescTipoCampo(String.Empty + reply.GetFieldValue(1)));
                fieldsTypeCollection.Add(("P." + reply.GetFieldValue(0)).ToUpper(), getDescTipoCampo(String.Empty + reply.GetFieldValue(1)));
            }
            reply.Dispose();
        }
		
	}
}


Me.Session["fieldsType-"+user] = fieldsTypeCollection;

//consulta de campos de Llamadas si la tabla tiene al menos un registro
var sql2 = (Tools.GetServerSettings.RDBMSName == BDConn.Sql) ? "SELECT TOP 1 * FROM LLAMADAS WITH(NOLOCK)" : "SELECT * FROM LLAMADAS WITH(NOLOCK) LIMIT 1";
DataRs reply2 = CurrentDb.OpenRecordset(sql2);
var numFieldsLlam = 0; 
var camposLlam = true;
var fieldsHtmlLlam = "";
if(reply2.HasRows)
{
    using (DataConn currConn = Me.CurrentDb.GetNewConnection())
    {
        numFieldsLlam = reply2.GetNumFields();
        while (reply2.Read())
        {
            for (var i = 0; i < numFieldsLlam; i++)
            {
                fieldsHtmlLlam += setNewField(reply2.GetFieldName(i).ToUpper(), "color-grey", "", "-LLAMADAS", currConn);
                fieldsType.Add(reply2.GetFieldName(i).ToUpper() + "-LLAMADAS", reply2.GetFieldType(i));
                fieldsTypeCollection.Add("LL." + reply2.GetFieldName(i).ToUpper(), reply2.GetFieldType(i));
            }
        }
        reply2.Dispose();
    }
}
else
{
    camposLlam = false;
}



//si no se pueden obtener los campos de Llamadas, se obtienen de un array estatico
if(!camposLlam){ //TODO: Leer campos de la tabla llamadas
    Dictionary<string, string> arrLlamt = new Dictionary<string, string>();
	arrLlamt.Add("UNIQUEID", "System.Int32");
	arrLlamt.Add("FECHA", "System.Date");
	arrLlamt.Add("HORA1", "System.String");
	arrLlamt.Add("PREFPAIS", "System.String");
	arrLlamt.Add("TELTOTAL", "System.String");
	arrLlamt.Add("PREFIJO", "System.String");
	arrLlamt.Add("TELEFONO", "System.String");
	arrLlamt.Add("CONTACTAR", "System.String");
	arrLlamt.Add("EMPRESA", "System.String");
	arrLlamt.Add("DEPTO", "System.String");
	arrLlamt.Add("PUESTO", "System.String");
	arrLlamt.Add("HEMOSLLAMA", "System.String");
	arrLlamt.Add("COGIDOLLAM", "System.String");
	arrLlamt.Add("CONTACTADO", "System.String");
	arrLlamt.Add("WHYCALL", "System.String");
	arrLlamt.Add("PEMPRESA", "System.String");
	arrLlamt.Add("TRABAJOPOR", "System.String");
	arrLlamt.Add("ORDREMOTO", "System.String");
	arrLlamt.Add("DURACION", "System.Double");
	arrLlamt.Add("MPDURACI", "System.Double");
	arrLlamt.Add("AGDURACI", "System.Double");
	arrLlamt.Add("COSTETELEF", "System.Double");
	arrLlamt.Add("COSTEMO", "System.Double");
	arrLlamt.Add("COSTERH", "System.Double");
	arrLlamt.Add("COEQVRH", "System.Double");
	arrLlamt.Add("COSTEMP", "System.Double");
	arrLlamt.Add("COSTESS", "System.Double");
	arrLlamt.Add("COSTESP", "System.Double");
	arrLlamt.Add("COSTERP", "System.Double");
	arrLlamt.Add("COSTETOT", "System.Double");
	arrLlamt.Add("VENTAMO", "System.Double");
	arrLlamt.Add("VENTATELEF", "System.Double");
	arrLlamt.Add("VENTAFIJO", "System.Double");
	arrLlamt.Add("COMOPAGO", "System.String");
	arrLlamt.Add("COMOCOBR", "System.String");
	arrLlamt.Add("MANUAL", "System.String");
	arrLlamt.Add("POB", "System.Double");
	arrLlamt.Add("OBSERVACIO", "System.String");
	arrLlamt.Add("BORRAR", "System.String");
	arrLlamt.Add("PASADO", "System.String");
	arrLlamt.Add("ACUMLLAMAD", "System.Int32");
	arrLlamt.Add("INDICE", "System.String");
	arrLlamt.Add("CODUNICO", "System.String");
	arrLlamt.Add("DESDE_FONO", "System.String");
	arrLlamt.Add("ORIPREF", "System.String");
	arrLlamt.Add("ORICDPO", "System.String");
	arrLlamt.Add("ORDINAL", "System.String");
	arrLlamt.Add("AUDIOQUE", "System.String");
	arrLlamt.Add("FICHAUDI", "System.String");
	arrLlamt.Add("REGPROSP", "System.Int32");
	arrLlamt.Add("CDPOSTAL", "System.String");
	arrLlamt.Add("RECWITNESS", "System.DateTime");
	arrLlamt.Add("ISARGUMENTED", "System.Boolean");
	arrLlamt.Add("PROCESSAUDIO", "System.Boolean");
	
	numFieldsLlam = arrLlamt.Count;

    using (DataConn currConn = Me.CurrentDb.GetNewConnection())
    {
        foreach (string key in arrLlamt.Keys)
        {
            fieldsHtmlLlam += setNewField(String.Empty + key, "color-grey", "", "-LLAMADAS",currConn);
            fieldsType.Add(key + "-LLAMADAS", String.Empty + arrLlamt[key]);
            fieldsTypeCollection.Add("LL." + key, String.Empty + arrLlamt[key]);
        }
    }
		
}



/**************LISTA DE GRAFICOS/REPORTES GUARDADOS EN LA CAMPAÑA **************/
DataRs replyRep = null;
var arrReportes = new ArrayList();
var tableReports = "REPORTS";
var sqlRep = "SELECT ID, NAME, DESCRIPTION, ACTIVECHART FROM "+tableReports+" WITH(NOLOCK) ORDER BY ID DESC";

try{	
	replyRep = CurrentDb.OpenRecordset(sqlRep);

	if(replyRep != null)
	{	
		while(replyRep.Read())
		{
            ArrayList Al = new ArrayList();
            Al.Add(replyRep.GetFieldValue(0));
            Al.Add(replyRep.GetFieldValue(1));
            Al.Add(replyRep.GetFieldValue(2));
            Al.Add(replyRep.GetFieldValue(3));
            arrReportes.Add(Al);
		}
	}
    replyRep.Dispose();
}catch(Exception e){

	//verificamos si el error se debe a que la tabla no existe y la creamos
	var index = e.ToString().ToLower().IndexOf("error 7041:");

    if (e.ToString().Contains("Invalid object name 'REPORTS'"))
    {
			
		arrReportes = new ArrayList();
		var sqlc = crearTablaReports();
		DataRs replyc = null;
		int resp = -1;
		try{
			resp = Me.CurrentDb.Execute(sqlc);
			if(resp < 0){
				try{
					//si no existe la tabla no hay que hacer consulta
				}catch(Exception e2){
					Response.Write("Ha ocurrido un error al procesar la consulta. Error: " + e.Message);
				}
			}
		}catch(Exception e2){
			Response.Write("Ha ocurrido un error al crear la tabla REPORTS en la BDs. " + e.Message);
		}

	}else{
		//print("Ha ocurrido un error al procesar la consulta. Error: "+e);
	}
}
    string ActionButtons = "[";
    ActionButtons += "{id:'cerrar5',action:'window.close();',text:'Cerrar',icon:'icon-close'}";
    ActionButtons += "]";
        
    Server.Execute("/Partials/AibeHeader.aspx?SignalR=NO&title=Generador de informes Aibe&subtitle=" + Me.Session.WriteLS("LOAD_DATA_FILE_SUBTITLE") + " " + (String.Empty + Request["idscript"]).ToUpper() + "&buttons=" + ActionButtons);  
%>

    <style>
        h3 {
            font-size: 1.4em;
            line-height: 17px;
        }
        
        html, body
        {
            /*overflow-y: auto !important;*/
        }
        
    </style>
	<link href="/Content/aibe/css/massive-export.css" rel="stylesheet" type="text/css" rel="stylesheet" />	
		
	<!-- Gestor Reportes -->
	<link href="css/reports/gestorReportes.css" rel="stylesheet" type="text/css" />
	<script type="text/javascript" language="javascript" src="js/reports/gestorReportes.js"></script> 
		
	<!-- Sortable Lists -->
	<link href="css/reports/sortable.css" rel="stylesheet" type="text/css" />
	<script type="text/javascript" language="javascript" src="js/reports/sortable.js"></script>
		
	<!-- IMPOTACION PARA MANEJO DE TABS -->
	<script type="text/javascript" language="javascript" src="js/jquery.idTabs.min.js"></script>
	<link rel="stylesheet" href="css/idTabs.css" type="text/css" />
		
	<!-- Load jQuery, SimpleModal and Basic JS files -->
	<script type='text/javascript' src='js/simplemodal/js/jquery.simplemodal.js'></script>
	<script type='text/javascript' src='js/simplemodal/js/basic.js'></script>
	<!-- CSS files -->
	<link type='text/css' href='js/simplemodal/css/basic.css' rel='stylesheet' media='screen' />

	<!-- IE6 "fix" for the close png image -->
	<!--[if lt IE 7]>
	<link type='text/css' href='js/simplemodal/css/basic_ie.css' rel='stylesheet' media='screen' />
	<![endif]-->    

	<!-- MultiSelect Widget-->
	<script type='text/javascript' src='js/multiselect/jquery.multiselect.min.js'></script>
	<link rel="stylesheet" href="js/multiselect/jquery.multiselect.css" type="text/css" />
		
    <!-- Jquery Numeric -->
	<script type="text/javascript" src="js/jquery-numeric.js"></script>

    <script type="text/javascript" src="/Content/external/js/jquery.blockUI.js?sess=<%= Me.Session.Auth %>"></script>
	
	<!-- Poshy Tip jQuery Plugin - Tooltip classes -->
	<link rel="stylesheet" href="js/poshytip-1.2/tip-skyblue/tip-skyblue.css" type="text/css" />
	<!--<link rel="stylesheet" href="js/poshytip-1.2/tip-violet/tip-violet.css" type="text/css" />
	<link rel="stylesheet" href="js/poshytip-1.2/tip-darkgray/tip-darkgray.css" type="text/css" />
	<link rel="stylesheet" href="js/poshytip-1.2/tip-yellow/tip-yellow.css" type="text/css" />
	<link rel="stylesheet" href="js/poshytip-1.2/tip-yellowsimple/tip-yellowsimple.css" type="text/css" />
	<link rel="stylesheet" href="js/poshytip-1.2/tip-twitter/tip-twitter.css" type="text/css" />
	<link rel="stylesheet" href="js/poshytip-1.2/tip-green/tip-green.css" type="text/css" />-->
	
	<!-- librerias para selestores de fecha y Tiempo -->
	<script type="text/javascript" src="js/timepicker-addon/jquery-ui-timepicker-addon.js"></script>
	<!-- Se carga la libreria segun el Idioma deseado para el selector de fecah y Hora-->
	<!--<script src="js/datepicker/i18n/jquery.ui.datepicker-es.js"></script>-->
	<script type="text/javascript" src="js/timepicker-addon/localization/jquery-ui-timepicker-es.js"></script>
	
	<!-- jQuery and the Poshy Tip plugin files -->
	<!--<script type="text/javascript" src="js/jquery-1.4.2.min.js"></script>-->
	<script type="text/javascript" src="js/poshytip-1.2/jquery.poshytip.js"></script>
	
		<script>			
		    $jq(document).ready(function(){
		        $jq("#Subtitulo2").html($jq("#main-title-report").val());    

		    });
		    
 
			//Array de Tipos de campos
		    var arrFieldsT = <%= Util.Serialize(fieldsType) %>;			
			
			//Array de Reportes disponibles
			var arrReportes = <%= Util.Serialize(arrReportes) %>;
		</script>
		<div>				
			<div>
                <!-- En versión ads estaba en un span dentro de la cabecera de la web -->
				<input type="hidden" id="main-title-report" value="Nuevo Informe" />
				<div class="left-panel" valign="top">
					<div class="border-pane1 bkg-pane1 panel_txt_title_list">
						<div id="panel_campos">
							<div>
								<b>Lista de Campos Gr&aacute;fica</b>
							</div>
							<i>Arrastre y suelte las columnas</i>
						</div>
					</div>
					
					<div class="border-pane1 td-campos">
						<div class="block-container-campos"></div>
						<div id="campos-aibe">
									
							<div >
								<div class="panel_herr_campos fields-table" style="">
									<div class="left pnl_sltall">
										<span class="sltall" id="select_all" onclick="selectAll('ul_campos_tabla')">Seleccionar Todos</span>
									</div>
									<div class="right pnl_slttables">
										<select id="tables" multiple="multiple">
											<option value="Prosp" selected="selected">Prospectos</option>
											<option value="Llamadas" selected="selected">Llamadas</option>
										</select>
									</div>
									<div class="cleaboth"></div>
									
									<div class="pnl_buscador">
										<div class="left buscText">Buscar:&nbsp;</div>
										<div id="buscador" class="left"></div>
										<div class="cleaboth"></div>
									</div>
									<div class="cleaboth"></div>
								</div>
								<div id="campos" class="reports-container-campos fields-table">
									<ul id="ul_campos_tabla" class="listing campos">
										<%= fieldsHtml %>
										<%= fieldsHtmlLlam %>
									</ul>
								</div>
							</div>											
						</div>
					</div>							
				</div>
					
					
				<div class="right-panel">
					<div class="bkg-pane1 border-pane1 panel_txt_title_list">
						<div id="panel_herramientas">
							<div class="tools-table">
							
								<div>
									<div class="ui-top-button ui-top-button-en left" onclick="newChart()">
										<div class="ui-button-top-img-r">
											<img src="images/agregar-informe-16.png" title="Nuevo Gr&aacute;fico" alt="Nuevo Gr&aacute;fico" height="16" width="16" >
										</div>
										<div class="ui-button-top-text-l">Nuevo</div>
										<div class="cleaboth"></div>
									</div>
									<div class="ui-top-button ui-top-button-en left" onclick="showModal(4)">
										<div class="ui-button-top-img-r">
											<img src="images/guardar-informe-16.png" title="Guardar Gr&aacute;fico" alt="Guardar Gr&aacute;fico" height="16" width="16" id="imgG">
										</div>
										<div class="ui-button-top-text-l" id="btnG">Guardar</div>
										<div class="cleaboth"></div>
									</div>
									<!--<div class="ui-top-button ui-top-button-en left" onclick="reloadChart()">
										<div class="ui-button-top-img-r">
											<img src="images/actualizar-informe-16.png" title="Actualizar Gr&aacute;fico" alt="Actualizar Gr&aacute;fico" height="16" width="16" >
										</div>
										<div class="ui-button-top-text-l" onclick="generarGrafico()">Graficar</div>
										<div class="cleaboth"></div>
									</div>-->
									<div class="ui-top-button ui-top-button-en left" onclick="borrarGrafico()">
										<div class="ui-button-top-img-r">
											<img src="images/borrar-informe-16.png" title="Borrar Gr&aacute;fico" alt="Borrar Gr&aacute;fico" height="16" width="16" >
										</div>
										<div class="ui-button-top-text-l">Borrar</div>
										<div class="cleaboth"></div>
									</div>
									<!--<div class="ui-top-button ui-top-button-en left ui-text-bottom-gallery-2" onclick="showModal(1)">
											<div class="ui-button-bottom-text-3">Listar</div>
											<div class="ui-button-top-img-r ui-button-bottom-img-r">
												<img src="images/flecha-abajo-16.png" title="Listar graficas" alt="Listar graficas" height="7" width="7" >
											</div>
											<div class="cleaboth"></div>
										</div>-->
									
									<div class="cleaboth"></div>
								</div>
								
								<div class="panel-herr-cell"><hr/></div>
								
								<div>
									<div class="ui-bottom-gallery">
										<!--
										<div class="ui-top-button left ui-bottom-button-disabled" onclick="" id="btn_config">
											<div class="config-img ui-button-top-img-r config-img">
												<img src="images/configurar-informe-16.png" title="Par&aacute;metros del Gr&aacute;fico" alt="Par&aacute;metros del Gr&aacute;fico" height="16" width="16" >
											</div>
											<div class="ui-button-top-text-l ">Configurar</div>
											<div class="cleaboth"></div>							
										</div>
										-->
										
										<div class="ui-button-bottom-text-l ui-bottom-button-disabled" id="btn_galeria">Galer&iacute;a: </div>
										
										<div id="disabledOptions" class="ui-bottom-button-disabled left">
											<div class="left" id="piechart">
												<img src="images/pie-chart-16.png" title="Gr&aacute;fico de Sectores" alt="Gr&aacute;fico de Sectores" height="16" width="16" onclick="">
											</div>
											<div class="left" id="columnchart">
												<img src="images/bar-chart-16.png" title="Gr&aacute;fico de Barras" alt="Gr&aacute;fico de Barras" height="16" width="16" onclick="">
											</div>
											<div class="left" id="stackedcolumnchart">
												<img src="images/stacked-column-chart-16.png" title="Gr&aacute;fico de Barras Apiladas" alt="Gr&aacute;fico de Barras Apiladas" height="16" width="16" onclick="">
											</div>
											<div class="left" id="linechart">
												<img src="images/line-chart-16.png" title="Gr&aacute;fico Lineal" alt="Gr&aacute;fico Lineal" height="16" width="16" onclick="">
											</div>
											<div class="left" id="areachart">
												<img src="images/area-chart-16.png" title="Gr&aacute;fico por Areas" alt="Gr&aacute;fico por Areas" height="16" width="16" onclick="">
											</div> 
											<div class="left" id="tablechart">
												<img src="images/table-chart-16.png" title="Tabla" alt="Tabla" height="16" width="16" onclick="">
											</div>
										</div>
										
										<div id="" class="sepoptions left">&nbsp;</div>
										
										<div id="enabledOptions" class="left"></div>
										
										<div class="ui-top-button left ui-text-bottom-gallery-2" onclick="" id="exportar">
											
										</div>
										<div class="cleaboth"></div>
										
									</div>
								</div>
								
							</div>
							
						</div>
					</div>
				
					<div class="border-pane1 pnl_tabs_grafico">
										
						<div id="panel_pestañas" class="usual"> 
																			
							<input type="hidden" value="" id="reportID"/>
							<input type="hidden" value="" id="reportID_desc"/>
							<input type="hidden" value="ul_campos_tabla" id="listaActiva"/>
							<input type="hidden" value="ul_tabla" id="listaBackup"/>
							
							<!-- Datos de Configuracion del Grafico -->
							<input type="hidden" value="" id="leyGrafico"/>
							<input type="hidden" value="" id="titGrafico"/>
							<input type="hidden" value="" id="colortitGrafico"/>
							<input type="hidden" value="" id="titEjex"/>
							<input type="hidden" value="" id="colortitEjex"/>
							<input type="hidden" value="" id="titEjey"/>
							<input type="hidden" value="" id="colortitEjey"/>
							
							<ul class="tabs-ul unselected-text"> 
							<li class="tabs-li"><a class="selected" href="#datos_tabla" onclick="activarListaFiltro('ul_campos_tabla','ul_tabla', true)">Tabla</a></li> 
								<li class="tabs-li"><a href="#datos_grafico" onclick="activarListaFiltro('ul_campos','ul_graficos', true)">Gr&aacute;fica</a></li> 
								<li class="tabs-li"><a href="#agrupamiento" onclick="activarListaFiltro('ul_campos_g','ul_grupos', true)">Agrupaci&oacute;n</a></li>
								<li class="tabs-li tab-dashboard"><a href="#dashboard" onclick="desactivarListaCampos(false)" >Dashboard</a></li>
								<li class="tabs-li tab-filtro"><a href="#generador_filtro" onclick="activarListaFiltro('ul_campos_f','ul_filtros', true)">Filtro</a></li>
								<!--<li class="tabs-li"><a href="#generador_filtro_sug" onclick="" class="disabled-tab">Filtro Sugerido</a></li>-->
								
							</ul> 
							
							<!-- Tab 1 -->
							<div id="datos_tabla" class="divtab unselected-text">
								<div class="left">
									<div class="datos-grafico">
										
										<div class="left-wtab-1 left-text cell-datos-grafico-text"><b>Tabla:</b>
											<div id="columns" class="eje-tabla">
												<div id="eje_t" class="column ejes eje-tabla-child">
													<ul id="ul_eje_tabla" class="eje_tabla campos" style="">
													</ul>
												</div>
											</div>
										</div>
										
										<div class="line-sep left"></div>
										
										
										<div class="left-wtab-1-padding">
											<div class="margin-eje-y div-sql">
												<span id="text-show-sql1" class="sltall text-show-sql" onclick="showSqlContent()">Ver SQL &raquo;</span>
												
												<div class="main_sql_report" id="sql-content1">
													<div class="left" style="width:80%;text-align:left;"><b>SQL:</b><a class="btn-copy">Copiar</a></div>
													<div class="right" style="width:20%; text-align:right;">
														<img width="12" height="12"  style="cursor:pointer" onclick="hideSqlContent()" alt="SQL generada" title="SQL generada" src="images/close-icono-2-16.png" />
													</div>
													<div class="cleaboth"></div><br />
													<div id="sql-content-text" style="word-wrap: break-word;"></div>
												</div>
											</div>
										</div>
										
										
										<div class="cleaboth"></div>
										 
									</div>
								</div>

								<div class="cleaboth"></div>
							</div>
							<!-- Fin Tab 1 -->
							
							<!-- Tab 2 -->
							<div id="datos_grafico" class="divtab unselected-text">
								<div class="left">
									<div class="datos-grafico">
										
										<div class="left-wtab-1">
											<div class="cell-datos-grafico-text-2"><b>Gr&aacute;ficas:</b></div>
											<div>
												<div class="left cell-datos-grafico-text margin-top-titulos-ejes">Eje X:&nbsp;</div>
												<div id="columns" class="eje-x right">
													<div id="eje_x" class="column ejes eje-x-child">
														<ul id="ul_ejex" class="eje_x campos" style="">
														</ul>
													</div>
												</div>
												 <div class="cleaboth"></div>
											</div>

											<div class="margin-eje-y">
												<div class="left cell-datos-grafico-text margin-top-titulos-ejes">Eje Y:&nbsp;</div>
												<div id="columns" class="eje-y right">
													<div id="eje_y" class="column ejes eje-y-child">
														<ul id="ul_ejey" class="eje_y campos"></ul>								
													</div>
												</div>
											</div>
											 <div class="cleaboth"></div>
										</div>
										
										<div class="left-wtab-1">
											
											<div class="div-color">
												<div class="left cell-datos-grafico-text margin-top-titulos-ejes">Leyenda:&nbsp;</div>
												<div class="right">
													<div id="eje_color" class="column ejes eje-color">
														<ul id="ul_eje_color" class="eje_color campos" style="" title="Este campo le permitir&aacute; incluir etiquetas de ayuda para los gr&aacute;ficos.">
														</ul>
													</div>
												</div>
												 <div class="cleaboth"></div>
											</div>
											
											
										</div>
										
										<div class="line-sep left line-color"></div>
										
										<div class="left-wtab-1-padding">
											<div class="margin-eje-y div-sql">
												<span id="text-show-sql" class="sltall text-show-sql" onclick="showSqlContent()">Ver SQL &raquo;</span>
												
												<div class="main_sql_report" id="sql-content">
													<div class="left" style="width:80%;text-align:left;"><b>SQL:</b><a class="btn-copy">Copiar</a></div>
													<div class="right" style="width:20%; text-align:right;">
														<img width="12" height="12"  style="cursor:pointer" onclick="hideSqlContent()" alt="SQL generada" title="SQL generada" src="images/close-icono-2-16.png" />
													</div>
													<div class="cleaboth"></div><br />
													<div id="sql-content-text" style="word-wrap: break-word;"></div>
												</div>
											</div>
										</div>
										
										
										<div class="cleaboth"></div>
										 
									</div>
								</div>

								<div class="cleaboth"></div>
							</div>
							<!-- Fin Tab 2 -->

							<!-- Tab 3 -->
							<div id="agrupamiento" class="divtab unselected-text">
								<div class="left">
									<div class="datos-grafico">
										<div class="left-wtab-2">
											Columnas:<br>
											<div id="columns" class="eje-y">
												<div id="fields_agrupx" class="column ejes fields-grupo">
													<ul id="ul_campos_grupo2" class="campos grupo"></ul>						
												</div>
											</div>
										</div>
											
										<div class="left-wtab-2">
											Filas:<br>
											<div id="columns" class="eje-y">
												<div id="fields_agrupx" class="column ejes fields-grupo">
														<ul id="ul_campos_grupo1" class="campos grupo"></ul>								
												</div>
											</div>
										</div>
											
										<div class="left-wtab-2-padding">
											Datos (Pivotar datos):<br>
											<div id="columns" class="eje-y">
												<div id="fields_agrupx" class="column ejes fields-grupo tabla-pivot" title="Trasponer columnas y filas para desglose de datos">
													<ul id="ul_campos_datos" class="campos grupo"></ul>						
												</div>
											</div>
										</div>
										
										<div class="cleaboth"></div>
										
									</div>
									
									<!--<div class="right container_sql" id="factivoGrupos">
									</div>-->
									<div class="cleaboth"></div>
								
								</div> 
							</div> 
							<!-- Fin Tab 3 -->														
							
							<!-- Tab 4 -->
							<div id="generador_filtro" class="divtab unselected-text">
								<div class="datos-grafico left-text">
									<div class="left">
										<div class="div-title-filtro">
											Campos para filtro:
											<span class="sltall right" onclick="limpiarFiltro()">(Limpiar)</span>
										</div>
										<div id="filtro" class="eje-y-filtro">
											<div id="fields_filtro" class="column ejes fields-filtro">
												<ul id="ul_campo_filtro" class="campos filtro"></ul>
											</div>
										</div>
									</div>
									<div class="left td-filtro">
										<ul id="lista_nuevo_filtro"></ul>
									</div>
									<div class="cleaboth"></div>
								</div>
							</div> 
							<!-- Fin Tab 4 -->	
							
							<!-- Tab 5 -->
							<!--<div id="generador_filtro_sug" class="divtab unselected-text">
								<table cellpadding="2" cellspacing="2" border="0" width="" class="datos-grafico">
									<tr>
										<td valign="top">
											<span style="color:red">En construcci&oacute;n</span>
										</td>
										
									</tr>
									
								</table>
							</div> -->
							<!-- Fin Tab 5 -->	
							
							<!-- Tab 6 -->
							<div id="dashboard" class="divtab unselected-text">
								<div class="block-container"></div>
								<div class="left dashb-reports">
									<table cellpadding="0" cellspacing="0" border="0" width="100%" class="datos-grafico">
										<tr>
											<td valign="top" align="center" width="200px" class="dashboard-text">
												<br><span style="font-weight: bold;">Reportes disponibles en esta campa&ntilde;a:</span>
												<br/><br/><span style="font-size:11px; padding-top: 5px;"><i>(Haga clic en algún reporte para visualizarlo)</i></span>
											</td>	

											<td valign="top" align="center" class="dashboard-imgs">
												<ul id="listaReportes">
													<!-- graficas BDs -->
												</ul>
											</td>																	
										</tr>
										
									</table>
								</div>
								
								<div class="cleaboth"></div>
							</div> 
							<!-- Fin Tab 6 -->

						</div>
											
						<div class="contenedor-filtro" id="factivo">
							<div class="left text-filtro-aplicado"><b>Filtro Activo</b></div>
							<div class="left f-button-img">Refrescar &raquo; <img valign="bottom" src="images/filtro-icono-16.png" onclick="refrescarFiltro()" title="Refrescar Filtro" alt="Refrescar Filtro"  class="img-filtro"/></div>
							<div class="cleaboth"></div>
							
							<div class="campos-filtroact"></div>
						</div>
											
						<div class="reports-container">
							<input type="hidden" value="sample_chart" id="idchart" />
							<input type="hidden" value="sample_chart" id="activeChart" />
							<input type="hidden" value="" id="idreport" />
							
							<iframe src="gallery-chart-pages/sample_chart.aspx" width="100%" height="600px" marginheight="0" frameborder="0" onLoad="autoResize('chart-container');" scroling="no" id="chart-container" style=""></iframe>
							
						</div>
											
					</div>
							
				</div>
					
				<div class="cleaboth" ></div>
				
			</div>
			
			<div class="sep-panel"></div>
			
			<!-- Ventana Modal -->
			<div id="modalContent" class="basic-modal-content"></div> 
			<div id="simplemodal-container2" class="basic-modal-content"></div> 
			
			<!-- Contenedores temporales Tabla-->
			<div class="hidden-class">
				<ul id="ul_prosp_tmp_tabla"></ul>
				<ul id="ul_llam_tmp_tabla"></ul>
				<ul id="ul_tabla"></ul>
			</div>
			
			<!-- Contenedores temporales Graficos-->
			<div class="hidden-class">
				<ul id="ul_prosp_tmp"></ul>
				<ul id="ul_llam_tmp"></ul>
				<ul id="ul_graficos">
					<% 
						var fieldsGrafico = fieldsHtml; 
						fieldsGrafico += fieldsHtmlLlam; 
						//fieldsGrafico = fieldsGrafico.Replace("onclick=\"setField", "onclick=\"setFieldFiltro");
						Response.Write(fieldsGrafico);
					%>
				</ul>
			</div>
			
			<!-- Contenedores temporales Filtros-->
			<div class="hidden-class">
				<ul id="ul_prosp_tmp_filtros"></ul>
				<ul id="ul_llam_tmp_filtros"></ul>
				<ul id="ul_filtros">
					<% 
						var fieldsF = fieldsHtml; 
						fieldsF += fieldsHtmlLlam; 
						fieldsF = fieldsF.Replace("onclick=\"setField", "onclick=\"setFieldFiltro");
						Response.Write(fieldsF);
					%>
				</ul>
			</div>
			
			<!-- Contenedores temporales Agrupaciones-->
			<div class="hidden-class">
				<ul id="ul_prosp_tmp_grupos"></ul>
				<ul id="ul_llam_tmp_grupos"></ul>
				<ul id="ul_grupos">
					<% 
						var fieldsG = fieldsHtml; 
						fieldsG += fieldsHtmlLlam; 
						fieldsG = fieldsG.Replace("onclick=\"setField", "onclick=\"setFieldGrupo");
						Response.Write(fieldsG);
					%>
				</ul>
			</div>
			
			<!-- Contenedor temporal para Nuevo Filtro-->
			<div id="nuevo_filtro_html" class="hidden-class">
				<li class="filtro_nuevo" name="nombcamp___filtro" id="nombcamp_li___">
					<div class="txt_filtro_campo clase_widget_tabla" />
						<!--<img src="img_src" id="" width="16" />-->&nbsp;&nbsp;campof
						<a class="remove" onclick="removeItemFiltro(this)" href="#">Borrar</a>
					</div>
					<div class="slt_filtro_campo">
						selectf
					</div>
					<div class="val_filtro_campo">
						<input type="text" value="" id="id_val_filtro" class="typeclassinp" class="tooltip_elemento center" title="" />
					</div>
				</li>
			</div>
			
			<div id="nuevo_filtro_html_slt" class="hidden-class slt-nuevo-filtro">
				<li class="filtro_nuevo_slt" id="idcamposlt_li___" name="idcamposlt___slt">
					<select id="idcamposlt_slt___" class="sltli_concat" onmousedown="event.stopPropagation();">
						<option value="AND">Y</option>
						<option value="OR">O</option>
					</select>
				</li>					
			</div>
			
			<!-- Contenerdor temporal de backups de listas para cargas desde Dashboard -->
			<ul id="ul_backup_tabla" style="display:none;">
				<%= fieldsHtml %>
				<%= fieldsHtmlLlam %>
			</ul>
			<ul id="ul_backup" style="display:none;">
				<%= fieldsHtml %>
				<%= fieldsHtmlLlam %>
			</ul>
			<ul id="ul_backup_filtros" style="display:none;">
				<% 
					fieldsF = fieldsHtml; 
					fieldsF += fieldsHtmlLlam; 
					fieldsF = fieldsF.Replace("onclick=\"setField", "onclick=\"setFieldFiltro");
					Response.Write(fieldsF);
				%>
			</ul>
			<ul id="ul_backup_grupos" style="display:none;">
				<% 
					fieldsG = fieldsHtml; 
					fieldsG += fieldsHtmlLlam; 
					fieldsG = fieldsG.Replace("onclick=\"setField", "onclick=\"setFieldGrupo");
					Response.Write(fieldsG);
				%>
			</ul>
			
			<div style="display:none;" class="standar_selects">
				
				<div id="div_fxfecha" style="display:none;">
					<select class="fxslt" onclick="onClicSelect()" onmousedown="event.stopPropagation()">
						<option value="dia">A&ntilde;o, Mes, D&iacute;a</option>
						<option value="año-mes-dia y hora">A&ntilde;o, Mes, D&iacute;a, Hora</option>
						<option value="dia agrupado">D&iacute;a</option>
						<option value="mes">Mes</option>
						<option value="ano">A&ntilde;o</option>
						<option value="dia semana">D&iacute;a de la semana</option>
						<option value="semana ano">Semana del A&ntilde;o</option>
						<option value="ano y mes">A&ntilde;o y Mes</option>
					</select>
				</div>
				<div id="div_fxstring" style="display:none;">
					<select class="fxslt" onclick="onClicSelect()" onmousedown="event.stopPropagation()">
						<option value="real">Real</option>
						<option value="recuento">Recuento</option>
					</select>
				</div>
				<div id="div_fxnumeric" style="display:none;">
					<select class="fxslt" onclick="onClicSelect()" onmousedown="event.stopPropagation()">
						<option value="real">Real</option>
						<option value="suma">Suma</option>
						<option value="recuento">Recuento</option>
						<option value="media">Media</option>
						<option value="max">M&aacute;ximo</option>
						<option value="min">M&iacute;nimo</option>
					</select>
				</div>
				
				<div id="div_fxstring_cols" style="display:none;">
					<select class="fxslt div_fxstring_cols" onclick="onClicSelect()" onmousedown="event.stopPropagation()">
						<option value="real">Real</option>
					</select>
				</div>
				<div id="div_fxstring_filas" style="display:none;">
					<select class="fxslt" onclick="onClicSelect()" onmousedown="event.stopPropagation()">
						<option value="recuento">Recuento</option>
						<option value="real">Recuento no nulos</option>
					</select>
				</div>
				<div id="div_fxnumeric_filas" style="display:none;">
					<select class="fxslt" onclick="onClicSelect()" onmousedown="event.stopPropagation()">
						<option value="recuento">Recuento</option>
						<option value="real">Recuento no nulos</option>
						<option value="suma">Suma</option>	
						<option value="media">Media</option>
						<option value="max">M&aacute;ximo</option>
						<option value="min">M&iacute;nimo</option>						
					</select>
				</div>
			</div>
			
		</div>
	</body>
</html>