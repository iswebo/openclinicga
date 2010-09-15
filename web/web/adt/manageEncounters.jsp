<%@ page import="be.openclinic.adt.Bed,
                 net.admin.Service,
                 java.sql.PreparedStatement,be.openclinic.adt.Encounter" %>
<%@include file="/includes/validateUser.jsp"%>
<%=checkPermission("adt.encounter","edit",activeUser)%>
<%
    PreparedStatement ps;
    ResultSet rs;
    //todo Labels invoegen

    String sCloseActiveEncounter = checkString(request.getParameter("CloseActiveEncounter"));

    if (sCloseActiveEncounter.equals("CLOSE")) {
        //Debug.println("Closing active encounter!");
        Encounter eActiveEncounter = Encounter.getActiveEncounter(activePatient.personid);
        eActiveEncounter.setEnd(ScreenHelper.getSQLDate(getDate()));
        eActiveEncounter.store();
    }

    boolean bActiveEncounterStatus;

    bActiveEncounterStatus = Encounter.getActiveEncounter(activePatient.personid) != null;

    //Action Parameter
    String sAction = checkString(request.getParameter("Action"));

    //Find Parameters
    String sFindEncounterType = checkString(request.getParameter("FindEncounterType"));
    String sFindEncounterBegin = checkString(request.getParameter("FindEncounterBegin"));
    String sFindEncounterEnd = checkString(request.getParameter("FindEncounterEnd"));

    String sFindEncounterPatient = checkString(request.getParameter("FindEncounterPatient"));
    String sFindEncounterPatientName = checkString(request.getParameter("FindEncounterPatientName"));

    String sFindEncounterManager = checkString(request.getParameter("FindEncounterManager"));
    String sFindEncounterManagerName = checkString(request.getParameter("FindEncounterManagerName"));

    String sFindEncounterBed = checkString(request.getParameter("FindEncounterBed"));
    String sFindEncounterBedName = checkString(request.getParameter("FindEncounterBedName"));

    String sFindEncounterService = checkString(request.getParameter("FindEncounterService"));
    String sFindEncounterServiceName = checkString(request.getParameter("FindEncounterServiceName"));

    String sFindSortColumn = checkString(request.getParameter("FindSortColumn"));

    //Edit Paramters
    String sEditEncounterUID = checkString(request.getParameter("EditEncounterUID"));

    String sEditEncounterType = checkString(request.getParameter("EditEncounterType"));
    String sEditEncounterBegin = checkString(request.getParameter("EditEncounterBegin"));
    String sEditEncounterEnd = checkString(request.getParameter("EditEncounterEnd"));

    String sEditEncounterService = checkString(request.getParameter("EditEncounterService"));
    String sEditEncounterServiceName = checkString(request.getParameter("EditEncounterServiceName"));

    String sEditEncounterBed = checkString(request.getParameter("EditEncounterBed"));
    String sEditEncounterBedName = checkString(request.getParameter("EditEncounterBedName"));

    String sEditEncounterPatient = checkString(request.getParameter("EditEncounterPatient"));
    String sEditEncounterPatientName = checkString(request.getParameter("EditEncounterPatientName"));

    String sEditEncounterManager = checkString(request.getParameter("EditEncounterManager"));
    String sEditEncounterManagerName = checkString(request.getParameter("EditEncounterManagerName"));

    if (Debug.enabled) {
        Debug.println("\n####################### FIND PARAMS ###########################" +
                "\nEncounterType: " + sFindEncounterType +
                "\nEncounterBegin: " + sFindEncounterBegin +
                "\nEncounterEnd: " + sFindEncounterEnd +
                "\nEncounterPatient: " + sFindEncounterPatient +
                "\nEncounterPatientName: " + sFindEncounterPatientName +
                "\nEncounterManager: " + sFindEncounterManager +
                "\nEncounterManagerName: " + sFindEncounterManagerName +
                "\nEncounterService: " + sFindEncounterService +
                "\nEncounterServiceName: " + sFindEncounterServiceName +
                "\nEncounterBed: " + sFindEncounterBed +
                "\nEncounterBedName: " + sFindEncounterBedName +
                "\nSortColumn: " + sFindSortColumn +
                "\n###############################################################" +
                "\n####################### EDIT PARAMS ###########################" +
                "\nEditEncounterUID: " + sEditEncounterUID +
                "\nEncounterType: " + sEditEncounterType +
                "\nEncounterBegin: " + sEditEncounterBegin +
                "\nEncounterEnd: " + sEditEncounterEnd +
                "\nEncounterPatient: " + sEditEncounterPatient +
                "\nEncounterPatientName: " + sEditEncounterPatientName +
                "\nEncounterManager: " + sEditEncounterManager +
                "\nEncounterManagerName: " + sEditEncounterManagerName +
                "\nEncounterService: " + sEditEncounterService +
                "\nEncounterServiceName: " + sEditEncounterServiceName +
                "\nEncounterBed: " + sEditEncounterBed +
                "\nEncounterBedName: " + sEditEncounterBedName +
                "\n###############################################################"
        );
    }
    if (sAction.equals("SAVE")) {
        Encounter tmpEncounter = new Encounter();
        if (sEditEncounterUID.length() > 0) {//update
            tmpEncounter = Encounter.get(sEditEncounterUID);
        } else {//insert
            tmpEncounter.setCreateDateTime(ScreenHelper.getSQLDate(getDate()));
        }

        tmpEncounter.setType(sEditEncounterType);
        tmpEncounter.setBegin(ScreenHelper.getSQLDate(sEditEncounterBegin));
        tmpEncounter.setEnd(ScreenHelper.getSQLDate(sEditEncounterEnd));

        Service tmpService = Service.getService(sEditEncounterService);
        Bed tmpBed = Bed.get(sEditEncounterBed);
        Connection ad_conn = MedwanQuery.getInstance().getAdminConnection();
        AdminPerson tmpPatient = AdminPerson.getAdminPerson(ad_conn, sEditEncounterPatient);
        ad_conn.close();
        //AdminPerson tmpManager = AdminPerson.getAdminPerson(dbConnection,sEditEncounterManager);
        User tmpManager = new User();
        tmpManager.initialize(Integer.parseInt(sEditEncounterManager));

        if (tmpService == null) {
            tmpService = new Service();
        }
        if (tmpBed == null) {
            tmpBed = new Bed();
        }
        if (tmpPatient == null) {
            tmpPatient = new AdminPerson();
        }
        if (tmpManager == null) {
            tmpManager = new User();
        }

        tmpEncounter.setService(tmpService);
        tmpEncounter.setBed(tmpBed);
        tmpEncounter.setPatient(tmpPatient);
        tmpEncounter.setManager(tmpManager);
        tmpEncounter.setUpdateDateTime(ScreenHelper.getSQLDate(getDate()));
        tmpEncounter.setUpdateUser(activeUser.userid);
        tmpEncounter.store();
    }
    if (sEditEncounterUID.length() > 0) {
        Encounter tmpEncounter;
        tmpEncounter = Encounter.get(sEditEncounterUID);

        sEditEncounterType = tmpEncounter.getType();
        sEditEncounterBegin = new SimpleDateFormat("dd/MM/yyyy").format(tmpEncounter.getBegin());
        sEditEncounterEnd = new SimpleDateFormat("dd/MM/yyyy").format(tmpEncounter.getEnd());

        sEditEncounterService = tmpEncounter.getService().code;
        sEditEncounterServiceName = getTran("Service", tmpEncounter.getService().code, sWebLanguage);

        sEditEncounterBed = tmpEncounter.getBed().getUid();
        sEditEncounterBedName = tmpEncounter.getBed().getName();

        sEditEncounterPatient = tmpEncounter.getPatient().personid;
        Connection ad_conn = MedwanQuery.getInstance().getAdminConnection();
        sEditEncounterPatientName = ScreenHelper.getFullPersonName(tmpEncounter.getPatient().personid, ad_conn);

        sEditEncounterManager = tmpEncounter.getManager().personid;
        sEditEncounterManagerName = ScreenHelper.getFullUserName(tmpEncounter.getManager().userid, ad_conn);
		ad_conn.close();
        sEditEncounterUID = tmpEncounter.getUid();
    }
%>
<%-- BEGIN FIND BLOCK--%>
<%
    if(sAction.equals("SEARCH") || sAction.equals("")){
%>
<form name='FindEncounterForm' method='POST' action='<c:url value="/main.do"/>?Page=adt/manageEncounters.jsp&ts=<%=getTs()%>'>
    <table class='menu' border='0' width='100%' cellspacing='0'>
        <%-- title --%>
        <tr>
            <td colspan="2"><%=writeTableHeader("Web.manage","manageEncounters",sWebLanguage," doBack();")%></td>
        </tr>
        <tr>
            <td width="<%=sTDAdminWidth%>"><%=getTran("Web","type",sWebLanguage)%></td>
            <td><input class='text' name='FindEncounterType' value='<%=sFindEncounterType%>' size="40"></td>
        </tr>
        <%-- date begin --%>
        <tr>
            <td><%=getTran("Web","begindate",sWebLanguage)%></td>
            <td><%=writeDateField("FindEncounterBegin","FindEncounterForm",sFindEncounterBegin,sWebLanguage)%></td>
        </tr>

        <%-- date end --%>
        <tr>
            <td><%=getTran("Web","enddate",sWebLanguage)%></td>
            <td><%=writeDateField("FindEncounterEnd","FindEncounterForm",sFindEncounterEnd,sWebLanguage)%></td>
        </tr>
        <%-- patient --%>
        <tr>
            <td><%=getTran("Web","patient",sWebLanguage)%></td>
            <td>
                <input type="hidden" name="FindEncounterPatient" value="<%=sFindEncounterPatient%>">
                <input class="text" type="text" name="FindEncounterPatientName" readonly size="<%=sTextWidth%>" value="<%=sFindEncounterPatientName%>">
                <input class="button" type="button" name="SearchPatientButton" value="<%=getTran("Web","Select",sWebLanguage)%>" onclick="searchPatient('FindEncounterPatient','FindEncounterPatientName');">
            </td>
        </tr>
        <%-- manager --%>
        <tr>
            <td><%=getTran("Web","manager",sWebLanguage)%></td>
            <td>
                <input type="hidden" name="FindEncounterManager" value="<%=sFindEncounterManager%>">
                <input class="text" type="text" name="FindEncounterManagerName" readonly size="<%=sTextWidth%>" value="<%=sFindEncounterManagerName%>">
                <input class="button" type="button" name="SearchManagerButton" value="<%=getTran("Web","Select",sWebLanguage)%>" onclick="searchManager('FindEncounterManager','FindEncounterManagerName');">
            </td>
        </tr>
        <%-- bed --%>
        <tr>
            <td><%=getTran("Web","bed",sWebLanguage)%></td>
            <td>
                <input type="hidden" name="FindEncounterBed" value="<%=sFindEncounterBed%>">
                <input class="text" type="text" name="FindEncounterBedName" readonly size="<%=sTextWidth%>" value="<%=sFindEncounterBedName%>">
                <input class="button" type="button" name="SearchBedButton" value="<%=getTran("Web","Select",sWebLanguage)%>" onclick="searchBed('FindEncounterBed','FindEncounterBedName');">
            </td>
        </tr>
        <%-- service --%>
        <tr>
            <td><%=getTran("Web","service",sWebLanguage)%></td>
            <td>
                <input type="hidden" name="FindEncounterService" value="<%=sFindEncounterService%>">
                <input class="text" type="text" name="FindEncounterServiceName" readonly size="<%=sTextWidth%>" value="<%=sFindEncounterServiceName%>">
                <input class="button" type="button" name="SearchServiceButton" value="<%=getTran("Web","Select",sWebLanguage)%>" onclick="searchService('FindEncounterService','FindEncounterServiceName');">
            </td>
        </tr>
        <%-- buttons --%>
        <tr>
            <td/>
            <td>
                <input class='button' type='button' name='buttonfind' value='<%=getTran("Web","search",sWebLanguage)%>' onclick='doFind();'>
                <input class='button' type='button' name='buttonclear' value='<%=getTran("Web","Clear",sWebLanguage)%>' onclick='doClear();'>
                <input class='button' type='button' name='buttonnew' value='<%=getTran("Web.Occup","medwan.common.create-new",sWebLanguage)%>' onclick='doNew();'>&nbsp;
                <input class='button' type="button" name="Backbutton" value='<%=getTran("Web","Back",sWebLanguage)%>' onclick="doBack();">
            </td>
        </tr>
        <%-- action,sortcolumn --%>
        <input type='hidden' name='Action' value=''>
        <input type='hidden' name='FindSortColumn' value='<%=sFindSortColumn%>'>
    </table>


</form>
<%
    }
%>
<%-- END FIND BLOCK --%>

<%-- BEGIN FINDRESULTS BLOCK --%>

<%
    if (sAction.equals("SEARCH")) {
        StringBuffer sbResults = new StringBuffer();
        String sSelect = " SELECT * FROM OC_ENCOUNTERS_VIEW " +
                " WHERE OC_ENCOUNTER_TYPE LIKE ? " +
                " AND OC_ENCOUNTER_BEGINDATE > ? " +
                " AND OC_ENCOUNTER_ENDDATE > ? ";
        if (sFindSortColumn.length() > 0) {
            sSelect += " ORDER BY " + sFindSortColumn;
        }
        Connection oc_conn=MedwanQuery.getInstance().getOpenclinicConnection();
        try {
            ps = oc_conn.prepareStatement(sSelect);
            ps.setString(1, sFindEncounterType.toLowerCase() + "%");
            ps.setDate(2, ScreenHelper.getSQLDate(sFindEncounterBegin));
            ps.setDate(3, ScreenHelper.getSQLDate(sFindEncounterEnd));
            rs = ps.executeQuery();

            String sClass = "";

            Encounter tmpEncounter;
            java.util.Date dBegin, dEnd;
            String sBegin, sEnd;
            String sServiceUID;
            while (rs.next()) {
                if (sClass.equals("")) {
                    sClass = "1";
                } else {
                    sClass = "";
                }

                tmpEncounter = Encounter.get(checkString(rs.getString("OC_ENCOUNTER_SERVERID")) + "." + checkString(rs.getString("OC_ENCOUNTER_OBJECTID")));

                dBegin = rs.getDate("OC_ENCOUNTER_BEGINDATE");
                dEnd = rs.getDate("OC_ENCOUNTER_ENDDATE");
                if (dBegin != null) {
                    sBegin = new SimpleDateFormat("dd/MM/yyyy").format(dBegin);
                } else {
                    sBegin = "";
                }
                if (dEnd != null) {
                    sEnd = new SimpleDateFormat("dd/MM/yyyy").format(dEnd);
                } else {
                    sEnd = "";
                }
                sServiceUID = checkString(rs.getString("OC_ENCOUNTER_SERVICEUID"));
                sbResults.append("<tr class='list");
                sbResults.append(sClass);
                sbResults.append("' onmouseover=\"this.style.cursor='hand';this.className='list_select';\" " + " onmouseout=\"this.style.cursor='default';this.className='list");
                sbResults.append(sClass);
                sbResults.append("';\" onclick=\"doSelect('");
                sbResults.append(checkString(rs.getString("OC_ENCOUNTER_SERVERID") + "." + checkString(rs.getString("OC_ENCOUNTER_OBJECTID"))));
                sbResults.append("');\"><td>");
                sbResults.append(checkString(rs.getString("OC_ENCOUNTER_TYPE")));
                sbResults.append("</td><td>");
                sbResults.append(sBegin);
                sbResults.append("</td><td>");
                sbResults.append(sEnd);
                sbResults.append("</td><td>");
                Connection ad_conn = MedwanQuery.getInstance().getAdminConnection();
                sbResults.append(ScreenHelper.getFullPersonName(tmpEncounter.getPatient().personid,ad_conn));
                sbResults.append("</td><td>");
                sbResults.append(ScreenHelper.getFullUserName(tmpEncounter.getManager().userid, ad_conn));
				ad_conn.close();
                sbResults.append("</td><td>");
                sbResults.append(checkString(tmpEncounter.getBed().getName()));
                sbResults.append("</td><td>");
                sbResults.append(getTran("Service", sServiceUID, sWebLanguage));
                sbResults.append("</td></tr>");
            }

            rs.close();
            ps.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        oc_conn.close();
%>
<table width='100%' cellspacing="0" cellpadding="0" class="list">
    <tr class="admin">
        <td width=''><%=getTran("Web","type",sWebLanguage)%></td>
        <td width="10%"><a href="#" class="underlined" onClick="doSearch('OC_ENCOUNTER_BEGINDATE');"><%=getTran("Web","begindate",sWebLanguage)%></a></td>
        <td width="10%"><a href="#" class="underlined" onClick="doSearch('OC_ENCOUNTER_ENDDATE');"><%=getTran("Web","enddate",sWebLanguage)%></a></td>
        <td width=''><%=getTran("Web","patient",sWebLanguage)%></td>
        <td width=''><%=getTran("Web","manager",sWebLanguage)%></td>
        <td width=''><%=getTran("Web","bed",sWebLanguage)%></td>
        <td width=''><%=getTran("Web","service",sWebLanguage)%></td>
    </tr>
    <%=sbResults%>
</table>
<%
    }
%>

<%-- END FINDRESULTS BLOCK --%>

<%-- EDIT BLOCK --%>
<%
    if(sAction.equals("NEW") || sAction.equals("SELECT") || sAction.equals("SAVE")){
%>
<form name='EditEncounterForm' method='POST' action='<c:url value="/main.do"/>?Page=adt/manageEncounters.jsp&ts=<%=getTs()%>'>
    <table class='list' border='0' width='100%' cellspacing='1'>
        <%-- title --%>
        <tr>
            <td colspan="2"><%=writeTableHeader("Web.manage","manageEncounters",sWebLanguage," doBack();")%></td>
        </tr>
        <%-- type --%>
        <tr>
            <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("Web","type",sWebLanguage)%></td>
            <td class='admin2'><input class='text' name='EditEncounterType' value='<%=sEditEncounterType%>' size="40"></td>
        </tr>
        <%-- date begin --%>
        <tr>
            <td class="admin"><%=getTran("Web","begindate",sWebLanguage)%></td>
            <td class="admin2"><%=writeDateField("EditEncounterBegin","EditEncounterForm",sEditEncounterBegin,sWebLanguage)%></td>
        </tr>

        <%-- date end --%>
        <tr>
            <td class="admin"><%=getTran("Web","enddate",sWebLanguage)%></td>
            <td class="admin2"><%=writeDateField("EditEncounterEnd","EditEncounterForm",sEditEncounterEnd,sWebLanguage)%></td>
        </tr>
        <%-- patient --%>
        <tr>
            <td class="admin"><%=getTran("Web","patient",sWebLanguage)%></td>
            <td class='admin2'>
                <input type="hidden" name="EditEncounterPatient" value="<%=sEditEncounterPatient%>">
                <input class="text" type="text" name="EditEncounterPatientName" readonly size="<%=sTextWidth%>" value="<%=sEditEncounterPatientName%>">
                <input class="button" type="button" name="SearchPatientButton" value="<%=getTranNoLink("Web","Select",sWebLanguage)%>" onclick="searchPatient('EditEncounterPatient','EditEncounterPatientName');">
            </td>
        </tr>
        <%-- manager --%>
        <tr>
            <td class="admin"><%=getTran("Web","manager",sWebLanguage)%></td>
            <td class='admin2'>
                <input type="hidden" name="EditEncounterManager" value="<%=sEditEncounterManager%>">
                <input class="text" type="text" name="EditEncounterManagerName" readonly size="<%=sTextWidth%>" value="<%=sEditEncounterManagerName%>">
                <input class="button" type="button" name="SearchManagerButton" value="<%=getTranNoLink("Web","Select",sWebLanguage)%>" onclick="searchManager('EditEncounterManager','EditEncounterManagerName');">
            </td>
        </tr>
        <%-- bed --%>
        <tr>
            <td class="admin"><%=getTran("Web","bed",sWebLanguage)%></td>
            <td class='admin2'>
                <input type="hidden" name="EditEncounterBed" value="<%=sEditEncounterBed%>">
                <input class="text" type="text" name="EditEncounterBedName" readonly size="<%=sTextWidth%>" value="<%=sEditEncounterBedName%>">
                <input class="button" type="button" name="SearchBedButton" value="<%=getTranNoLink("Web","Select",sWebLanguage)%>" onclick="searchBed('EditEncounterBed','EditEncounterBedName');">
            </td>
        </tr>
        <%-- service --%>
        <tr>
            <td class="admin"><%=getTran("Web","service",sWebLanguage)%></td>
            <td class='admin2'>
                <input type="hidden" name="EditEncounterService" value="<%=sEditEncounterService%>">
                <input class="text" type="text" name="EditEncounterServiceName" readonly size="<%=sTextWidth%>" value="<%=sEditEncounterServiceName%>">
                <input class="button" type="button" name="SearchServiceButton" value="<%=getTranNoLink("Web","Select",sWebLanguage)%>" onclick="searchService('EditEncounterService','EditEncounterServiceName');">
            </td>
        </tr>
        <%=ScreenHelper.setFormButtonsStart()%>
            <input class='button' type="button" name="saveButton" value='<%=getTran("Web","save",sWebLanguage)%>' onclick="doSave();">&nbsp;
            <input class='button' type="button" name="Backbutton" value='<%=getTran("Web","Back",sWebLanguage)%>' onclick="doBack();">
        <%=ScreenHelper.setFormButtonsStop()%>
        <%-- action, uid --%>
        <input type='hidden' name='Action' value=''>
        <input type='hidden' name='EditEncounterUID' value='<%=sEditEncounterUID%>'>
        <input type='hidden' name='CloseActiveEncounter' value=''>
    </table>
    <%
    if(sAction.equals("NEW")){
            if(bActiveEncounterStatus){
                %>
                    <script>
                        function closeActiveEncounter(){
                            EditEncounterForm.Action.value = "NEW";
                            EditEncounterForm.CloseActiveEncounter.value = "CLOSE";
                            EditEncounterForm.submit();
                        }
                        var answer = confirm("Do you want to close the current Encounter?");
                        if(answer){
                            closeActiveEncounter();
                        }
                    </script>
                <%
            }
        }
    %>
</form>
<script>
    EditEncounterForm.EditEncounterType.focus();
</script>
<%
    }
%>
<%-- END EDIT BLOCK --%>

<script>

<%-- Find Block --%>

    function doClear(){
        FindEncounterForm.FindEncounterService.value = "";
        FindEncounterForm.FindEncounterServiceName.value = "";
        FindEncounterForm.FindEncounterPatient.value = "";
        FindEncounterForm.FindEncounterPatientName.value = "";
        FindEncounterForm.FindEncounterManager.value = "";
        FindEncounterForm.FindEncounterManagerName.value = "";
        FindEncounterForm.FindEncounterBed.value = "";
        FindEncounterForm.FindEncounterBedName.value = "";
        FindEncounterForm.FindEncounterType.value = "";
        FindEncounterForm.FindEncounterBegin.value = "";
        FindEncounterForm.FindEncounterEnd.value = "";
        FindEncounterForm.FindEncounterType.focus();

    }
    function doFind(){
        FindEncounterForm.Action.value = "SEARCH";
        FindEncounterForm.buttonfind.disabled = true;
        FindEncounterForm.submit();
    }

    function doNew(){
        FindEncounterForm.Action.value = "NEW";
        FindEncounterForm.submit();
    }

<%-- End Find Block --%>

<%-- FindResults Block --%>

    function doSelect(id){
        window.location.href="<c:url value='/main.do'/>?Page=adt/manageEncounters.jsp&Action=SELECT&EditEncounterUID=" + id + "&ts=<%=getTs()%>";
    }

<%-- End FindResults Block --%>

<%-- Edit Block --%>

    function doBack(){
        window.location.href="<c:url value='/main.do'/>?Page=adt/index.jsp&ts=<%=getTs()%>";
    }

    <%-- search service --%>
    function searchService(serviceUidField,serviceNameField){
        openPopup("/_common/search/searchService.jsp&ts=<%=getTs()%>&VarCode="+serviceUidField+"&VarText="+serviceNameField);
    }

    <%-- search patient --%>
    function searchPatient(patientUidField,patientNameField){
        openPopup("/_common/search/searchPatient.jsp&ts=<%=getTs()%>&ReturnPersonID="+patientUidField+"&ReturnName="+patientNameField+"&displayImmatNew=no&isUser=no");
    }

    <%-- search manager --%>
    function searchManager(managerUidField,managerNameField){
        openPopup("/_common/search/searchUser.jsp&ts=<%=getTs()%>&ReturnUserID="+managerUidField+"&ReturnName="+managerNameField+"&displayImmatNew=no&FindServiceID="+EditEncounterForm.EditEncounterService.value+"&FindServiceName="+EditEncounterForm.EditEncounterServiceName.value);
    }
    <%-- search bed --%>
    function searchBed(bedUidField,bedNameField){
        openPopup("/_common/search/searchBed.jsp&ts=<%=getTs()%>&VarCode="+bedUidField+"&VarText="+bedNameField);
    }

    function doSave(){
        if(<%=bActiveEncounterStatus%>){
            var popupUrl = "<c:url value="/popup.jsp"/>?Page=_common/search/okPopup.jsp&ts=<%=getTs()%>&labelType=web&labelID=close_active_enc_before_new_one";
            var modalities = "dialogWidth:266px;dialogHeight:163px;center:yes;scrollbars:no;resizable:no;status:no;location:no;";
            (window.showModalDialog)?window.showModalDialog(popupUrl,"",modalities):window.confirm("<%=getTranNoLink("web","close_active_enc_before_new_one",sWebLanguage)%>");
            //alert("An encounter is still active. Please close the encounter before creating a new one.");
        }else{
            saveButton.disabled = true;
            EditEncounterForm.Action.value = "SAVE";
            EditEncounterForm.submit();
        }
    }

    <%-- DO SEARCH --%>
  function doSearch(sortCol){
       FindEncounterForm.buttonfind.disabled = true;
       FindEncounterForm.buttonclear.disabled = true;
       FindEncounterForm.buttonnew.disabled = true;

       FindEncounterForm.Action.value = "SEARCH";
       FindEncounterForm.FindSortColumn.value = sortCol;
       FindEncounterForm.submit();
  }
<%-- End Edit Block --%>
</script>