<%@ page import="java.util.*,be.openclinic.system.ExportSpecification,be.openclinic.medical.LabAnalysis" %>
<%@page errorPage="/includes/error.jsp"%>
<%@include file="/includes/validateUser.jsp"%>
<%@include file="/includes/SingletonContainer.jsp"%>

<%=checkPermission("system.management","all",activeUser)%>
<%=sJSSORTTABLE%>

<%!
    //--- PROCESS EXPORT SPECIFICATION FOR ANALYSIS -----------------------------------------------
    private void processExportSpecificationForAnalysis(String elementType, String exportCode, String elementContent) throws Exception {
        // check if an exportSpecification exists for the specified prestation (=analysis-request)
        boolean exportSpecificationFound = ExportSpecification.exists(elementType);

        ExportSpecification exportSpec;
        exportSpec = new ExportSpecification();
        exportSpec.setElementType(elementType);
        exportSpec.setExportCode(exportCode);
        exportSpec.setElementContent(elementContent);
        exportSpec.setUpdatetime(getSQLTime());
        // add exportSpecification if no exportCode exists for the specified prestation
        if (!exportSpecificationFound) {
            exportSpec.insert();
        }
        // update exportSpecification if an exportCode was found
        else {
            exportSpec.update(elementType);
        }
    }
%>

<%
    final String sLabLabelType = "labanalysis";

    String sAction = checkString(request.getParameter("Action"));

    String sLabID        = checkString(request.getParameter("LabID")),
           sLabType      = checkString(request.getParameter("LabType")),
           sLabCodeOther = checkString(request.getParameter("LabCodeOther")),
            sFindLabCode  = checkString(request.getParameter("FindLabCode")).toLowerCase(),
            sEditLabUnit  = checkString(request.getParameter("EditLabUnit")).toLowerCase(),
           sEditLabCode  = checkString(request.getParameter("EditLabCode")).toLowerCase();
    /*
    // DEBUG ////////////////////////////////////////////////////////////////////////////
    Debug.println("### ACTION = "+sAction+" ####################################");
    Debug.println("### sLabID        = "+sLabID);
    Debug.println("### sLabType      = "+sLabType);
    Debug.println("### sLabCodeOther = "+sLabCodeOther);
    Debug.println("### sFindLabCode  = "+sFindLabCode);
    Debug.println("### sEditLabCode  = "+sEditLabCode+"\n\n");
    /////////////////////////////////////////////////////////////////////////////////////
    */

    String sMonster = "",
           sBiomonitoring = "",
           sMedidoccode = "",
           sComment = "",
           sLimitValue = "",
           sShortTimeValue = "",
           sPrestationCode = "",
           sLabGroup = "",
           sAlertValue = "",
           sPrestationType = "";
    int nEditUnavailable=0;

    // supported languages
    String supportedLanguages = MedwanQuery.getInstance().getConfigString("supportedLanguages");
    String supportedMonsters = MedwanQuery.getInstance().getConfigString("supportedMonsters");
    if(supportedLanguages.length()==0) supportedLanguages = "nl,fr";
    supportedLanguages = supportedLanguages.toLowerCase();

    // get all params starting with 'EditLabelValueXX', representing labels in different languages
    Hashtable labelValues = new Hashtable();
    Enumeration paramEnum = request.getParameterNames();
    String tmpParamName, tmpParamValue, tmpLang;

    if(sAction.equals("save") || sAction.equals("new")){
        while(paramEnum.hasMoreElements()){
            tmpParamName = (String)paramEnum.nextElement();

            if(tmpParamName.startsWith("EditLabelValue")){
                tmpParamValue = request.getParameter(tmpParamName);
                labelValues.put(tmpParamName.substring(14),tmpParamValue); // language, value
            }
        }
    }
    else if(sAction.equals("details")){
        StringTokenizer tokenizer = new StringTokenizer(supportedLanguages,",");
        while(tokenizer.hasMoreTokens()){
            tmpLang = tokenizer.nextToken();
            labelValues.put(tmpLang,getTranNoLink(sLabLabelType,sLabID,tmpLang));
        }
    }

    if(!sLabCodeOther.equals("1")) sLabCodeOther = "0";
    boolean recordExists = false;
%>
<%-- SEARCHFORM ---------------------------------------------------------------------------------%>
<form name="searchForm" method="post">
  <input type="hidden" name="Action" value="find"/>
  <input type="hidden" name="LabID" value="<%=sLabID%>"/>
<%=writeTableHeader("Web.Occup","medwan.system-related-actions.manage-labAnalysis",sWebLanguage,"doBack();")%>
<table width="100%" class="menu" cellspacing="0" cellpadding="1">
  <%-- INPUT & BUTTONS --%>
  <tr>
    <td class="menu" colspan="2">
      &nbsp;<%=getTran("Web.manage","labanalysis.cols.code_name",sWebLanguage)%>&nbsp;
      <input class="text" type="text" name="FindLabCode" size="18" value="<%=(sAction.equals("details")?"":sFindLabCode)%>" onblur="validateText(this);limitLength(this);">
      <input class="button" type="submit" name="findButton" value="<%=getTran("Web","find",sWebLanguage)%>" onclick="searchForm.Action.value='find';"/>&nbsp;
      <input class="button" type="button" name="clearButton" value="<%=getTran("Web","clear",sWebLanguage)%>" onclick="doClear();">&nbsp;
      <input class="button" type="submit" name="createButton" value="<%=getTran("Web","new",sWebLanguage)%>" onclick="doNew();">&nbsp;
      <input class="button" type="button" name="backButton" value="<%=getTran("Web","back",sWebLanguage)%>" onclick="doBack();">
    </td>
  </tr>
</table>
<script>
  searchForm.FindLabCode.focus();

  function doClear(){
    searchForm.FindLabCode.value = '';
    searchForm.FindLabCode.focus();
  }

  function doNew(){
    searchForm.FindLabCode.value = '';
    searchForm.LabID.value = '';
    searchForm.Action.value = 'new';
  }

  function doBack(){
    window.location.href = '<c:url value="/main.jsp"/>?Page=system/menu.jsp&ts=<%=getTs()%>';
  }
</script>
</form>
<%
    //--- SAVE ------------------------------------------------------------------------------------
    if (sAction.equals("save") || sAction.equals("new")) {
        if (sEditLabCode.length() > 0) {
            sMonster = checkString(request.getParameter("EditMonster"));
            sBiomonitoring = checkString(request.getParameter("EditBiomonitoring"));
            sMedidoccode = checkString(request.getParameter("EditMedidoccode"));
            sComment = checkString(request.getParameter("EditComment"));
            sAlertValue = checkString(request.getParameter("EditAlertValue"));
            sLimitValue = checkString(request.getParameter("EditLimitValue"));
            sShortTimeValue = checkString(request.getParameter("EditShortTimeValue"));
            sPrestationCode = checkString(request.getParameter("EditPrestationcode"));
            sLabGroup = checkString(request.getParameter("EditLabGroup"));
            sPrestationType = "LABCODE." + sEditLabCode;
            if(request.getParameter("EditUnavailable")!=null){
                nEditUnavailable=1;
            }

            //--- SAVE ANALYSIS -------------------------------------------------------------------
            // check if labcode exists
            boolean deletedRecordFound;
            boolean unDeletedRecordFound;

            boolean recordsFound[];

            // when saving a new analysis, LabID is empty
            if (sAction.equals("new")) {
                recordsFound = LabAnalysis.isDeletedByLabCode(sEditLabCode);
                sLabID = MedwanQuery.getInstance().getOpenclinicCounter("LabAnalysisID")+"";
            } else {
                recordsFound = LabAnalysis.isDeletedByLabID(sLabID);
            }

            deletedRecordFound = recordsFound[0];
            unDeletedRecordFound = recordsFound[1];

            //--- NEW LABANALYSIS ---

            boolean bInsert = false;
            boolean bUpdate = false;

            if ((!deletedRecordFound && !unDeletedRecordFound) || (deletedRecordFound && !unDeletedRecordFound)) {
                bInsert = true;
            }
            //--- NEW ANALYSIS BUT IT ALLREADY EXISTS ---
            else if (unDeletedRecordFound && sAction.equals("new")) {
                recordExists = true;
            }
            //--- UPDATE LABANALYSIS ---
            else {
                bUpdate = true;
            }

            if (!recordExists) {
                LabAnalysis labAnalysis = new LabAnalysis();
                labAnalysis.setLabId(Integer.parseInt(sLabID));
                labAnalysis.setLabcode(sEditLabCode);
                labAnalysis.setLabtype(sLabType);
                labAnalysis.setMonster(sMonster);
                labAnalysis.setBiomonitoring(sBiomonitoring);
                labAnalysis.setMedidoccode(sMedidoccode);
                labAnalysis.setLabgroup(sLabGroup);
                labAnalysis.setComment(sComment);
                labAnalysis.setUpdateuserid(Integer.parseInt(activeUser.userid));
                labAnalysis.setUpdatetime(getSQLTime());
                labAnalysis.setDeletetime(null);
                labAnalysis.setLabcodeother(sLabCodeOther);
                labAnalysis.setAlertvalue(sAlertValue);
                labAnalysis.setLimitvalue(sLimitValue);
                labAnalysis.setShorttimevalue(sShortTimeValue);
                labAnalysis.setUnit(sEditLabUnit);
                labAnalysis.setUnavailable(nEditUnavailable);

                if (bInsert) {
                    labAnalysis.insert();
                } else if (bUpdate) {
                    labAnalysis.update();
                }
            }
            //--- SAVE LABEL ----------------------------------------------------------------------
            // check if label exists for each of the supported languages
            java.util.StringTokenizer tokenizer = new StringTokenizer(supportedLanguages, ",");
            while (tokenizer.hasMoreTokens()) {
                tmpLang = tokenizer.nextToken();
                Label label = new Label();
                label.type = sLabLabelType;
                label.id = sLabID;
                label.language = tmpLang;
                label.showLink = "0";
                label.updateUserId = activeUser.userid;
                label.value = checkString((String) labelValues.get(tmpLang));
                label.saveToDB();

                MedwanQuery.getInstance().removeLabelFromCache(sLabLabelType, sEditLabCode, tmpLang);
                MedwanQuery.getInstance().getLabel(sLabLabelType, sEditLabCode, tmpLang);
            }

            reloadSingleton(session);

            // save prestationcode if needed
            if (!recordExists && sPrestationCode.length() > 0) {
                processExportSpecificationForAnalysis( sPrestationType, sPrestationCode, "");
            }

            // message
            if (recordExists) {
                out.print("<span style='color:red;'>" + getTran("Web.Occup", "labanalysis.analysis", sWebLanguage) + " '" + sEditLabCode + "' " + getTran("Web", "exists", sWebLanguage) + "</span>");
            } else {
                out.print(getTran("Web", "dataissaved", sWebLanguage));
                sAction = "save";
            }
        }
    }

    //--- DELETE ----------------------------------------------------------------------------------
    if (sAction.equals("delete")) {
        //*** delete labAnalysis ***
        LabAnalysis labAnalysis = new LabAnalysis();
        labAnalysis.setLabId(Integer.parseInt(sLabID));
        labAnalysis.delete();
        // message
        out.print(getTran("Web.Occup", "labanalysis.analysis", sWebLanguage) + " '" + sEditLabCode + "' " + getTran("Web", "deleted", sWebLanguage));
    }

    //--- SEARCH ----------------------------------------------------------------------------------
    int iTotal = 0;
    if (sAction.equals("find")) {
        //--- FIND HEADER ---
%>
        <table width="100%" cellspacing="0" cellpadding="0" class="sortable" id="searchresults">
            <tr class='admin'>
                <td width='6%'>&nbsp;<%=getTran("Web.manage","labanalysis.cols.code",sWebLanguage)%></td>
                <td width='7%'>&nbsp;<%=getTran("Web.manage","labanalysis.cols.other",sWebLanguage)%></td>
                <td width='7%'>&nbsp;<%=getTran("Web.manage","labanalysis.cols.type",sWebLanguage)%></td>
                <td width='25%'>&nbsp;<%=getTran("Web","description",sWebLanguage)%></td>
                <td width='15%'>&nbsp;<%=getTran("Web.manage","labanalysis.cols.monster",sWebLanguage)%></td>
                <td width='10%'>&nbsp;<%=getTran("Web.manage","labanalysis.cols.biomonitoring",sWebLanguage)%></td>
                <td width='10%'>&nbsp;<%=getTran("Web.manage","labanalysis.cols.medidoccode",sWebLanguage)%></td>
                <td width='*'>&nbsp;<%=getTran("Web.manage","labanalysis.cols.labgroup",sWebLanguage)%></td>
            </tr>
        <%

        //--- compose search-select ---
        Vector vLabAnalyses = LabAnalysis.searchLabAnalyses("labanalysis",sFindLabCode,sWebLanguage);

        String sClass;
        Iterator iterator = vLabAnalyses.iterator();

        %><tbody onMouseOver='this.style.cursor="hand"' onMouseOut='this.style.cursor="default"'><%

        //--- display found records ---
        LabAnalysis labAnalysis;
        while(iterator.hasNext()){
            labAnalysis = (LabAnalysis)iterator.next();
            iTotal++;

            // get data from RS
            sLabID         = Integer.toString(labAnalysis.getLabId());
            sLabType       = labAnalysis.getLabtype();
            sEditLabCode   = labAnalysis.getLabcode();
            sMonster       = labAnalysis.getMonster();
            sBiomonitoring = labAnalysis.getBiomonitoring();
            sMedidoccode   = labAnalysis.getMedidoccode();
            sLabCodeOther  = labAnalysis.getLabcodeother();
            sLabGroup      = labAnalysis.getLabgroup();
            nEditUnavailable=labAnalysis.getUnavailable();

            // translate labtype
                 if(sLabType.equals("1")) sLabType = getTran("Web.occup","labanalysis.type.blood",sWebLanguage);
            else if(sLabType.equals("2")) sLabType = getTran("Web.occup","labanalysis.type.urine",sWebLanguage);
            else if(sLabType.equals("3")) sLabType = getTran("Web.occup","labanalysis.type.other",sWebLanguage);
            else if(sLabType.equals("4")) sLabType = getTran("Web.occup","labanalysis.type.stool",sWebLanguage);
            else if(sLabType.equals("5")) sLabType = getTran("Web.occup","labanalysis.type.sputum",sWebLanguage);
            else if(sLabType.equals("6")) sLabType = getTran("Web.occup","labanalysis.type.smear",sWebLanguage);
            else if(sLabType.equals("7")) sLabType = getTran("Web.occup","labanalysis.type.liquid",sWebLanguage);

            // translate biomonitoring
                 if(sBiomonitoring.equals("0")) sBiomonitoring = getTran("Web","no",sWebLanguage);
            else if(sBiomonitoring.equals("1")) sBiomonitoring = getTran("Web","yes",sWebLanguage);

            // translate labcodeother
                 if(sLabCodeOther.equals("0")) sLabCodeOther = "";
            else if(sLabCodeOther.equals("1")) sLabCodeOther = getTran("web.occup","labanalysis.labCodeOther",sWebLanguage);

            // translate labGroup
            sLabGroup = getTran("labanalysis.group",sLabGroup,sWebLanguage);

            // alternate row-style
            if((iTotal%2)==0) sClass = "1";
	        else              sClass = "";

            %>
                <tr class="list<%=sClass%>"  onmouseover="this.className='list_select';" onmouseout="this.className='list<%=sClass%>';" onClick="showDetails('<%=sEditLabCode%>','<%=sLabID%>');">
                    <td><%=sEditLabCode%></td>
                    <td><%=sLabCodeOther%></td>
                    <td><%=sLabType%></td>
                    <td><%=getTranNoLink(sLabLabelType,sLabID,sWebLanguage)%></td>
                    <td><%=sMonster%></td>
                    <td><%=sBiomonitoring%></td>
                    <td><%=sMedidoccode%></td>
                    <td><%=sLabGroup%></td>
                </tr>
            <%
        }
        %>
              </tbody>
          </table>
          <%-- MESSAGE --%>
          <table border="0" width="100%">
              <tr height="30">
                  <td><%=iTotal%> <%=getTran("Web","recordsFound",sWebLanguage)%></td>
                  <%-- link --%>
                  <td align="right">
                      <img src='<c:url value="/_img/pijl.gif"/>'>
                      <a class="menuItem" href="<c:url value="/main.jsp"/>?Page=system/manageLabProfiles.jsp&ts=<%=getTs()%>" onMouseOver="window.status='';return true;"><%=getTran("Web.Occup","medwan.system-related-actions.manage-labProfiles",sWebLanguage)%></a>&nbsp;
                  </td>
              </tr>
          </table>
        <%
    }

    %>
        <script>
          function showDetails(code,id){
            searchForm.Action.value = 'details';
            searchForm.FindLabCode.value = code;
            searchForm.LabID.value = id;
            searchForm.submit();
          }
        </script>
    <%

    if(sAction.equals("save")){
        sFindLabCode = sEditLabCode;
    }

    //--- EDIT/ADD FIELDS -------------------------------------------------------------------------
    if(sAction.equals("new") || sAction.equals("details") || sAction.equals("save")){
        iTotal = 0;

        //--- check if labcode exists; details are shown if it exists, else values will be blank ---
        if(sFindLabCode.length() > 0){

            LabAnalysis labAnalysis = LabAnalysis.getLabAnalysisByLabID(sLabID);

            if(labAnalysis!=null){
                iTotal++;

                // get data from RS
                sLabID          = Integer.toString(labAnalysis.getLabId());
                sEditLabCode    = checkString(labAnalysis.getLabcode());
                sLabType        = checkString(labAnalysis.getLabtype());
                sMonster        = checkString(labAnalysis.getMonster());
                sBiomonitoring  = checkString(labAnalysis.getBiomonitoring());
                if(sBiomonitoring.length()==0){
                    sBiomonitoring="0";
                }
                sMedidoccode    = checkString(labAnalysis.getMedidoccode());
                sComment        = checkString(labAnalysis.getComment());
                sLabGroup       = checkString(labAnalysis.getLabgroup());
                sLabCodeOther   = checkString(labAnalysis.getLabcodeother());
                sAlertValue     = checkString(labAnalysis.getAlertvalue());
                sLimitValue     = checkString(labAnalysis.getLimitvalue());
                sShortTimeValue = checkString(labAnalysis.getShorttimevalue());
                sEditLabUnit    = checkString(labAnalysis.getUnit());
                nEditUnavailable= labAnalysis.getUnavailable();
            }
            // get prestation code is one exists
            if(sEditLabCode.length() > 0){
                sPrestationCode = ExportSpecification.getExportCodeByElementType("LABCODE."+sEditLabCode);
            }
        }
    %>

<%-- EDIT/ADD FROM ------------------------------------------------------------------------------%>
<form name="editForm" id="editForm" method="post" onclick="setSaveButton(event);" onkeyup="setSaveButton(event);">
  <input type="hidden" name="Action" value="<%=(sAction.equals("new")?sAction:"save")%>"/>
  <input type="hidden" name="LabID" value="<%=sLabID%>"/>
<table border="0" width="100%" class="list" cellspacing="1">
  <%-- EDIT/ADD HEADER --%>
  <tr class="admin">
    <td colspan="2">
    <%
        if(iTotal > 0) out.print(getTran("Web","edit",sWebLanguage));
        else           out.print(getTran("Web","new",sWebLanguage));
    %>
    </td>
  </tr>
  <%-- CODE --%>
  <tr>
    <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("Web.manage","labanalysis.cols.code",sWebLanguage)%></td>
    <td class="admin2">
      <input type="text" name="EditLabCode" class="text" value="<%=sEditLabCode%>" size="20" onblur="validateText(this);limitLength(this);">
      <input type="checkbox" id="LabCodeOther" value="1" name="LabCodeOther" <%=(sLabCodeOther.equals("1")?"checked":"")%>><%=getLabel("web.occup","labanalysis.labCodeOther",sWebLanguage,"LabCodeOther")%>
    </td>
  </tr>
  <%-- UNIT --%>
  <tr>
    <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("Web.manage","labanalysis.cols.unit",sWebLanguage)%></td>
    <td class="admin2">
      <input type="text" name="EditLabUnit" class="text" value="<%=sEditLabUnit%>" size="20">
    </td>
  </tr>
  <%
  if(sEditLabCode.length()>0){
      %>
  <tr>
    <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("Web.manage","labanalysis.cols.reference",sWebLanguage)%></td>
    <td class="admin2">
        <input type="button" class="button" name="ageGenderControl" value="<%=getTran("web.occup","agegendercontrol",sWebLanguage)%>" onclick="showAgeGenderTable('<%=sLabID%>')">&nbsp;
    </td>
  </tr>
  <%
  }
  %>
  <%-- TYPE --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.type",sWebLanguage)%></td>
    <td class="admin2">
      <select name="LabType" class="text">
        <option value="0"></option>
        <option value="1" <%=(sLabType.equals("1")?"selected":"")%>><%=getTran("web.occup","labanalysis.type.blood",sWebLanguage)%></option>
          <option value="2" <%=(sLabType.equals("2")?"selected":"")%>><%=getTran("web.occup","labanalysis.type.urine",sWebLanguage)%></option>
        <option value="3" <%=(sLabType.equals("3")?"selected":"")%>><%=getTran("web.occup","labanalysis.type.other",sWebLanguage)%></option>
        <option value="4" <%=(sLabType.equals("4")?"selected":"")%>><%=getTran("web.occup","labanalysis.type.stool",sWebLanguage)%></option>
        <option value="5" <%=(sLabType.equals("5")?"selected":"")%>><%=getTran("web.occup","labanalysis.type.sputum",sWebLanguage)%></option>
        <option value="6" <%=(sLabType.equals("6")?"selected":"")%>><%=getTran("web.occup","labanalysis.type.smear",sWebLanguage)%></option>
        <option value="7" <%=(sLabType.equals("7")?"selected":"")%>><%=getTran("web.occup","labanalysis.type.liquid",sWebLanguage)%></option>
      </select>
    </td>
  </tr>
  <%-- LABEL --%>
  <%
      // display input field for each of the supported languages
      StringTokenizer tokenizer = new StringTokenizer(supportedLanguages,",");
      while(tokenizer.hasMoreTokens()){
          tmpLang = tokenizer.nextToken();

          %>
          <tr>
              <td class="admin"> <%=getTran("Web","Description",sWebLanguage)%> <%=tmpLang%> *</td>
              <td class="admin2">
                  <input type="text" class="text" name="EditLabelValue<%=tmpLang%>" value="<%=checkString((String)labelValues.get(tmpLang))%>" size="<%=sTextWidth%>">
              </td>
          </tr>
          <%
      }
  %>
  <%-- LAB MONSTER --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.monster",sWebLanguage)%></td>
    <td class="admin2">
      <select type="text" class="text" name="EditMonster">
        <option></option>
        <%=ScreenHelper.writeSelect("labanalysis.monster",sMonster,sWebLanguage)%>
      </select>
    </td>
  </tr>
  <%-- ALERT VALUE --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.alertvalue",sWebLanguage)%></td>
    <td class="admin2">
      <input type="text" name="EditAlertValue" class="text" id="alertValue" value="<%=sAlertValue%>" size="10" onBlur="isNumber(this);">
    </td>
  </tr>
  <%-- BIOMONITORING --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.biomonitoring",sWebLanguage)%></td>
    <td class="admin2">
      <input type="radio" onDblClick="uncheckRadio(this);hideBiomonOptions();" onClick="showBiomonOptions();" id="bioYes" name="EditBiomonitoring" value="1" <%=(sBiomonitoring.equals("1")?"checked":"")%>><%=getLabel("Web","yes",sWebLanguage,"bioYes")%>
      <input type="radio" onDblClick="uncheckRadio(this);" onClick="hideBiomonOptions();" id="bioNo"  name="EditBiomonitoring" value="0" <%=(sBiomonitoring.equals("0")?"checked":"")%>><%=getLabel("Web","no",sWebLanguage,"bioNo")%>
    </td>
  </tr>
  <%-- LIMIT VALUE --%>
  <tr id="biomonOption1" style="display:none;">
    <td class="admin">&nbsp;-&nbsp;<%=getTran("Web.manage","labanalysis.cols.limitvalue",sWebLanguage)%></td>
    <td class="admin2">
      <input type="text" name="EditLimitValue" class="text" id="limitValue" value="<%=sLimitValue%>" size="10" onBlur="isNumber(this);">
    </td>
  </tr>
  <%-- SHORT TIME VALUE --%>
  <tr id="biomonOption2" style="display:none;">
    <td class="admin">&nbsp;-&nbsp;<%=getTran("Web.manage","labanalysis.cols.shorttimevalue",sWebLanguage)%></td>
    <td class="admin2">
      <input type="text" name="EditShortTimeValue" id="shortTimeValue" class="text" value="<%=sShortTimeValue%>" size="10" onBlur="isNumber(this);">
    </td>
  </tr>
  <script>
    editForm.EditLabCode.focus();

    <%
        if(sBiomonitoring.equals("1")){
            %>showBiomonOptions();<%
        }
    %>

    function showBiomonOptions(){
      document.getElementById("biomonOption1").style.display = "";
      document.getElementById("biomonOption2").style.display = "";
    }

    function hideBiomonOptions(){
      document.getElementById("limitValue").value = "";
      document.getElementById("shortTimeValue").value = "";

      document.getElementById("biomonOption1").style.display = "none";
      document.getElementById("biomonOption2").style.display = "none";
    }
  </script>
  <%-- MEDIDOC CODE --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.medidoccode",sWebLanguage)%></td>
    <td class="admin2">
      <input type="text" name="EditMedidoccode" class="text" value="<%=sMedidoccode%>" size="50" onblur="validateText(this);limitLength(this);">
    </td>
  </tr>
  <%-- PRESTATION CODE --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.prestationcode",sWebLanguage)%></td>
    <td class="admin2">
      <input type="text" name="EditPrestationcode" class="text" value="<%=sPrestationCode%>" size="50" onblur="validateText(this);limitLength(this);">
    </td>
  </tr>
  <%-- LAB GROUP --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.labgroup",sWebLanguage)%></td>
    <td class="admin2">
      <select type="text" class="text" name="EditLabGroup">
        <option><%=getTran("web","choose",sWebLanguage)%></option>
        <%=ScreenHelper.writeSelect("labanalysis.group",sLabGroup,sWebLanguage)%>
      </select>
    </td>
  </tr>
  <%-- COMMENT --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.comment",sWebLanguage)%></td>
    <td class="admin2">
      <textarea onKeyup="resizeTextarea(this,10);limitChars(this,255);" class="text" cols="80" rows="2" name="EditComment"><%=sComment%></textarea>
    </td>
  </tr>
  <%-- AVAILABLE --%>
  <tr>
    <td class="admin"><%=getTran("Web.manage","labanalysis.cols.unavailable",sWebLanguage)%></td>
    <td class="admin2">
      <input type="checkbox" cols="80" rows="2" value="1" <%=nEditUnavailable==1?"checked":""%> name="EditUnavailable"/>
    </td>
  </tr>
</table>
<script>
  editForm.EditLabCode.focus();
</script>
<%-- EDIT BUTTONS --%>
<%=ScreenHelper.alignButtonsStart()%>
  <input class="button" type="button" name="SaveButton" id="SaveButton" value="<%=getTran("web","record",sWebLanguage)%>" onClick="checkSave();"/>&nbsp;
  <script>
    function checkSave(){
      if(editForm.EditLabCode.value.length == 0 || editForm.LabType.selectedIndex == 0 || editForm.EditLabGroup.selectedIndex == 0
        <%
            // check input field of each supported language for content
            tokenizer = new StringTokenizer(supportedLanguages,",");
            while(tokenizer.hasMoreTokens()){
                tmpLang = tokenizer.nextToken();

                %>|| editForm.EditLabelValue<%=tmpLang%>.value.length==0<%
            }
        %>
        ){
        var popupUrl = "<c:url value="/popup.jsp"/>?Page=_common/search/okPopup.jsp&ts=<%=getTs()%>&labelType=web.manage&labelID=dataMissing";
        var modalities = "dialogWidth:266px;dialogHeight:143px;center:yes;scrollbars:no;resizable:no;status:no;location:no;";
        var answer = (window.showModalDialog)?window.showModalDialog(popupUrl,"",modalities):window.confirm("<%=getTranNoLink("Web.manage","datamissing",sWebLanguage)%>");

             if(editForm.EditLabCode.value.length == 0){ editForm.EditLabCode.focus(); }
        else if(editForm.LabType.selectedIndex == 0){ editForm.LabType.focus(); }
        else if(editForm.EditLabGroup.selectedIndex == 0){ editForm.EditLabGroup.focus(); }
        <%
            // check input field of each supported language for content
            tokenizer = new StringTokenizer(supportedLanguages,",");
            while(tokenizer.hasMoreTokens()){
                tmpLang = tokenizer.nextToken();

                out.println("else if(editForm.EditLabelValue"+tmpLang+".value.length==0){ editForm.EditLabelValue"+tmpLang+".focus(); }");
            }
        %>
      }
      else{
        editForm.submit();
      }
    }
  </script>
  <%
      if(!sAction.equals("new")){
        %>
          <input class="button" type="button" value="<%=getTran("web","delete",sWebLanguage)%>" onClick="checkDelete();"/>&nbsp;
          <script>
            function checkDelete(){
              if(editForm.EditLabCode.value.length == 0){
                editForm.EditLabCode.focus();
              }
              else{
                <%-- delete --%>
                var popupUrl = "<%=sCONTEXTPATH%>/_common/search/yesnoPopup.jsp?ts=<%=getTs()%>&labelType=web&labelID=areyousuretodelete";
                var modalities = "dialogWidth:266px;dialogHeight:143px;center:yes;scrollbars:no;resizable:no;status:no;location:no;";
                var answer = (window.showModalDialog)?window.showModalDialog(popupUrl,"",modalities):window.confirm("<%=getTranNoLink("web","areyousuretodelete",sWebLanguage)%>");

                if(answer==1){
                  editForm.Action.value = 'delete';
                  editForm.submit();
                }
              }
            }
          </script>
        <%
      }
  %>
  <input class="button" type="button" value="<%=getTran("web","back",sWebLanguage)%>" onclick="showOverview();">&nbsp;
  <br><br>
  <%-- link to labprofiles --%>
  <img src='<c:url value="/_img/pijl.gif"/>'>
  <a class="menuItem" href="<c:url value="/main.jsp"/>?Page=system/manageLabProfiles.jsp&ts=<%=getTs()%>" onMouseOver="window.status='';return true;"><%=getTran("Web.Occup","medwan.system-related-actions.manage-labProfiles",sWebLanguage)%></a>&nbsp;
<%=ScreenHelper.alignButtonsStop()%>
<script>
  function showOverview(){
    window.location.href = '<c:url value="/main.jsp"/>?Page=system/manageLabAnalyses.jsp&ts=<%=getTs()%>';
  }

  function showAgeGenderTable(labcode){
    window.open("<c:url value="/popup.jsp"/>?Page=util/manageAgeGenderControl_view.jsp&ts=<%=getTs()%>&Type=LabAnalysis&ID="+labcode+"&PopupHeight=300&PopupWidth=600","<%=getTran("Web","Find",sWebLanguage)%>","toolbar=no, status=no, scrollbars=yes, resizable=yes, menubar=no, height=300, width=500");
  }
</script>
</form>
        <%=writeJSButtons("editForm","SaveButton")%>
        <%
    }
%>