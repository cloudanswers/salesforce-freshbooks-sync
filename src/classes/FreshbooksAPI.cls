public with sharing class FreshbooksAPI {
    public class FreshbooksException extends Exception{}
    public static Boolean inTest;
    public static Freshbooks_Settings_Protected__c settings;
    public final static String FRESHBOOKS_XML_API_NS = 'http://www.freshbooks.com/api/';
    public final static String FRESHBOOKS_ACCOUNT_FIELDS = 'Name,Phone,Fax,Freshbooks_Client_ID__c,Freshbooks_Email__c,Freshbooks_Notes__c,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode';
    public final static Integer LIST_PAGE_COUNT_MAX = 100;
    
    private static final String TEST_GET_CLIENTS_XML = '<?xml version="1.0" encoding="utf-8"?> <response xmlns="http://www.freshbooks.com/api/" status="ok"> <clients page="1" per_page="15" pages="3" total="42"> <client> <client_id>13</client_id> <first_name>Jane</first_name> <last_name>Doe</last_name> <organization>ABC Corp</organization> <email>janedoe@freshbooks.com</email> <username>janedoe</username> <work_phone>(555) 123-4567</work_phone> <home_phone>(555) 234-5678</home_phone> <mobile></mobile> <fax></fax> <language>en</language> <currency_code>USD</currency_code> <credit currency="USD" deprecated="true">123.45</credit>  <credits> <credit currency="USD">123.45</credit> <credit currency="CAD">43.45</credit> <credit currency="EUR">12.00</credit> </credits> <notes>Prefers email over phone calls</notes>  <p_street1>123 Fake St.</p_street1> <p_street2>Unit 555</p_street2> <p_city>New York</p_city> <p_state>New York</p_state> <p_country>United States</p_country> <p_code>553132</p_code>  <s_street1></s_street1> <s_street2></s_street2> <s_city></s_city> <s_state></s_state> <s_country></s_country> <s_code></s_code> <url deprecated="true">https://sample.freshbooks.com/view/Vbbfs324trTkxer</url> <auth_url deprecated="true">https://sample.freshbooks.com/clients/13</auth_url> <links> <client_view>https://sample.freshbooks.com/view/Vbbfs324trTkxer</client_view> <view>https://sample.freshbooks.com/clients/13</view> <statement>https://sample.freshbooks.com/view/3EbEwAkJGJkuJHSN</statement> </links> <vat_name></vat_name> <vat_number></vat_number> <updated>2009-08-12 09:00:00</updated> <folder>active</folder> </client> </clients> </response>';
    public static Account[] getClients(){
        return getClients(null);
    }
    @isTest public static void test_getClientsNoFilter(){
        inTest = true;
        Account[] response = getClients();
        System.assert(response != null);
    }
    public static Account[] getClients(Map<String,String> filter){
        List<Account> clientsToReturn = new List<Account>();
        Integer lastBatchSize = LIST_PAGE_COUNT_MAX;
        Integer pageNumber = 1;
        while(lastBatchSize == LIST_PAGE_COUNT_MAX){
            Account[] clientsBatch = getClients(pageNumber,filter);
            pageNumber++;
            lastBatchSize = clientsBatch.size();
            clientsToReturn.addAll(clientsBatch);
        }
        return clientsToReturn;
    }
    public static Account[] getClients(Integer pageNumber, Map<String,String> filter){
        Dom.Document requestDoc = new Dom.Document();
        Dom.XmlNode root = requestDoc.createRootElement('request', null, null);
        root.setAttribute('method', 'client.list');
        root.addChildElement('page', null, null).addTextNode(String.valueOf(pageNumber));
        if(filter != null && !filter.isEmpty())
            for(String k : filter.keySet())
                root.addChildElement(k,null,null).addTextNode(filter.get(k));
        if(filter == null || !filter.keySet().contains('per_page'))
            root.addChildElement('per_page',null,null).addTextNode(String.valueOf(LIST_PAGE_COUNT_MAX));
        Dom.Document responseDoc = ( inTest == true ? CambridgeCloudPartnersREST.domify(TEST_GET_CLIENTS_XML) : post(requestDoc) );
        checkError(responseDoc,'Error occured when getting client');
        Dom.XmlNode responseRoot = responseDoc.getRootElement();
        Dom.XmlNode clients = responseRoot.getChildElement('clients',FRESHBOOKS_XML_API_NS);
        List<Account> accounts = new List<Account>();
        if(clients != null && clients.getChildElements() != null && !clients.getChildElements().isEmpty())
        for(Dom.Xmlnode clientNode : clients.getChildElements()){
            accounts.add(xml2Account(clientNode));
        }
        return accounts;
    }
    public static Account getClient(String freshbooksClientId){
        Dom.Document requestDoc = new Dom.Document();
        Dom.XmlNode requestNode = requestDoc.createRootElement('request', null, null);
        requestNode.setAttribute('method','client.get');
        requestNode.addChildElement('client_id',null,null).addTextNode(freshbooksClientId);
        Dom.Document responseDoc = (inTest == true ? CambridgeCloudPartnersREST.domify(TEST_GET_CLIENT_XML) : post(requestDoc));
        checkError(responseDoc,'Error occured when getting client');
        Account a = xml2account(responseDoc.getRootElement().getChildElement('client',FRESHBOOKS_XML_API_NS));
        return a;
    }
    private static final String TEST_GET_CLIENT_XML = '<?xml version="1.0" encoding="utf-8"?><response xmlns="http://www.freshbooks.com/api/" status="ok"><client><client_id>123</client_id><first_name>Jane</first_name><last_name>Doe</last_name><organization>ABC Corp</organization><email>janedoe@freshbooks.com</email><username>janedoe</username><work_phone>(555) 123-4567</work_phone><home_phone>(555) 234-5678</home_phone><mobile/><fax/><language>en</language><currency_code>USD</currency_code><credit currency="USD" deprecated="true">123.45</credit><credits><credit currency="USD">123.45</credit><credit currency="CAD">43.45</credit><credit currency="EUR">12.00</credit></credits><notes/><p_street1>123 Fake St.</p_street1><p_street2>Unit 555</p_street2><p_city>New York</p_city><p_state>New York</p_state><p_country>United States</p_country><p_code>553132</p_code><s_street1/><s_street2/><s_city/><s_state/><s_country/><s_code/><url deprecated="true">https://sample.freshbooks.com/view/Vbbfs324trTkxer</url><auth_url deprecated="true">https://sample.freshbooks.com/clients/13</auth_url><links><client_view>https://sample.freshbooks.com/view/Vbbfs324trTkxer</client_view><view>https://sample.freshbooks.com/clients/13</view><statement>https://sample.freshbooks.com/view/3EbEwAkJGJkuJHSN</statement></links><vat_name/><vat_number/><folder>active</folder><updated>2009-08-12 09:00:00</updated></client></response>';
    @isTest public static void test_getClient(){
        inTest = true;
        Account response = getClient('123');
        System.assert(response != null);
    }
    public static void saveClient(Account a){
        Dom.Document requestDoc = new Dom.Document();
        Dom.XmlNode requestRoot = requestDoc.createRootElement('request', null, null);
        requestRoot.setAttribute('method', (a.Freshbooks_Client_ID__c != null ? 'client.update' : 'client.create' ) );
        appendAccountToXml(requestRoot, a);
        Dom.Document responseDoc = (inTest == true ? CambridgeCloudPartnersREST.domify(TEST_SAVE_CLIENT_XML) : post(requestDoc));
        checkError(responseDoc,'Error occured when saving client');
        if(a.Freshbooks_Client_ID__c == null)
            a.Freshbooks_Client_ID__c = responseDoc.getRootElement().getChildElement('client_id',FRESHBOOKS_XML_API_NS).getText();
    }
    public static final String TEST_SAVE_CLIENT_XML = '<?xml version="1.0" encoding="utf-8"?><response xmlns="http://www.freshbooks.com/api/" status="ok"><client_id>123</client_id></response>'; 
    @isTest public static void test_saveClient(){
        inTest = true;
        Account a = new Account(Name = 'test');
        saveClient(a);
        System.assert(a.Freshbooks_Client_ID__c != null);
        saveClient(a);
        System.assert(a.Freshbooks_Client_ID__c != null);
    }
    private static void checkError(Dom.Document doc, String exceptionPrefix){
        Dom.Xmlnode responseRoot = doc.getRootElement();
        if(responseRoot.getAttribute('status',null) != 'ok'){
            throw new FreshbooksException(exceptionPrefix + ': '+responseRoot.getChildElement('error', FRESHBOOKS_XML_API_NS).getText());
        }
    }
    @isTest public static void test_checkError(){
        inTest = true;
        Dom.Document doc = new Dom.Document();
        doc.load('<?xml version="1.0" encoding="utf-8"?><response status="ok"></response>');
        try{
            checkError(doc,'test');
        }catch(Exception e){
            System.assert(false);
        }
        doc = new Dom.Document();
        doc.load('<?xml version="1.0" encoding="utf-8"?><response status="fail"><error>WTF</error></response>');
        try{
            checkError(doc,'test');
            System.assert(false);
        }catch(Exception e){
        }
    }
    private static void appendTagAndText(Dom.XmlNode node, String tagName, String textValue){
        node.addChildElement(tagName,null,null).addTextNode((textValue==null?'':textValue));
    }
    private static void appendAccountToXml(Dom.XmlNode nodeToAppend, Account a){
        Dom.Xmlnode client = nodeToAppend.addChildElement('client', null, null);
        
        //TODO: finish mapping fields
        
        if(a.Freshbooks_Client_ID__c != null)
            appendTagAndText(client,'client_id',a.Freshbooks_Client_ID__c);
        //clientNode.addChildElement('first_name',null,null).addTextNode(firstName);
        //clientNode.addChildElement('last_name',null,null).addTextNode(lastName);
        appendTagAndText(client,'organization',a.Name);
        appendTagAndText(client,'email',a.Freshbooks_Email__c);
        //client.addChildElement('username',null,null).addTextNode(username);
        //client.addChildElement('password',null,null).addTextNode(password);
        appendTagAndText(client,'work_phone',a.Phone);
        //client.addChildElement('home_phone',null,null).addTextNode(homePhone);
        //client.addChildElement('mobile',null,null).addTextNode(mobile);
        appendTagAndText(client,'fax',a.Fax);
        //client.addChildElement('language',null,null).addTextNode(language);
        //client.addChildElement('currency_code',null,null).addTextNode(currencyCode);
        appendTagAndText(client,'notes',a.Freshbooks_Notes__c);
        appendTagAndText(client,'p_street1',a.BillingStreet);
        //client.addChildElement('p_street2',null,null).addTextNode(primaryStreet2);
        appendTagAndText(client,'p_city',a.BillingCity);
        appendTagAndText(client,'p_state',a.BillingState);
        appendTagAndText(client,'p_country',a.BillingCountry);
        appendTagAndText(client,'p_code',a.BillingPostalCode);
        //client.addChildElement('s_street1',null,null).addTextNode(secondaryStreet1);
        //client.addChildElement('s_street2',null,null).addTextNode(secondaryStreet2);
        //client.addChildElement('s_city',null,null).addTextNode(secondaryCity);
        //client.addChildElement('s_state',null,null).addTextNode(secondaryState);
        //client.addChildElement('s_country',null,null).addTextNode(secondaryCountry);
        //client.addChildElement('s_code',null,null).addTextNode(secondaryZipCode);
        //client.addChildElement('vat_number',null,null).addTextNode(vatNumber);
        //client.addChildElement('vat_name',null,null).addTextNode(vatName);
    }
    private static Account xml2Account(Dom.Xmlnode node){
        Account a = new Account();
        try{
            a.Freshbooks_Client_ID__c = node.getChildElement('client_id',FRESHBOOKS_XML_API_NS).getText();
            //a.Freshbooks_First_Name__c = node.getChildElement('first_name',null).getText();
            //a.Freshbooks_Last_Name__c = node.getChildElement('last_name',null).getText();
            a.Name = node.getChildElement('organization',FRESHBOOKS_XML_API_NS).getText();
            //a.Freshbooks_Email__c = node.getChildElement('email',null).getText();
            //a.Freshbooks_Username__c = node.getChildElement('username',null).getText();
            a.Phone = node.getChildElement('work_phone',FRESHBOOKS_XML_API_NS).getText();
            //a. = node.getChildElement('home_phone',null).getText();
            //a.Freshbooks_Mobile__c = node.getChildElement('mobile',null).getText();
            a.Fax = node.getChildElement('fax',FRESHBOOKS_XML_API_NS).getText();
            //a.Freshbooks_Language__c = node.getChildElement('language',null).getText();
            //a.Freshbooks_Currency_Code__c = node.getChildElement('currency_code',null).getText();
            //credit currency="USD" deprecated="true">123.45</credit> 
            //TODO: finish mapping fields
            /*
            <credits>
                <credit currency="USD">123.45</credit>
                <credit currency="CAD">43.45</credit>
                <credit currency="EUR">12.00</credit>
            </credits>
            */
            
            a.Freshbooks_Notes__c = node.getChildElement('notes',FRESHBOOKS_XML_API_NS).getText();
            a.BillingStreet = node.getChildElement('p_street1',FRESHBOOKS_XML_API_NS).getText()+node.getChildElement('p_street2',FRESHBOOKS_XML_API_NS).getText();
            //a.BillingStreet += node.getChildElement('p_street2',FRESHBOOKS_XML_API_NS).getText();
            a.BillingCity = node.getChildElement('p_city',FRESHBOOKS_XML_API_NS).getText();
            a.BillingState = node.getChildElement('p_state',FRESHBOOKS_XML_API_NS).getText();
            a.BillingCountry = node.getChildElement('p_country',FRESHBOOKS_XML_API_NS).getText();
            a.BillingPostalCode = node.getChildElement('p_code',FRESHBOOKS_XML_API_NS).getText();
            
            /*
            s_street1
            s_street2
            s_city
            s_state
            s_country
            s_code
            */
            /*
            <links>
                <client_view>https://sample.freshbooks.com/view/Vbbfs324trTkxer</client_view>
                <view>https://sample.freshbooks.com/clients/13</view>
                <statement>https://sample.freshbooks.com/view/3EbEwAkJGJkuJHSN</statement>
            </links>
            */
            /*
            <vat_name></vat_name>
            <vat_number></vat_number>
            <updated>2009-08-12 09:00:00</updated>
            <folder>active</folder>
            */
        }catch(Exception e){
            throw new FreshbooksException('Error parsing response from Freshbooks: '+e.getMessage());
        }
        return a;
    }
    @isTest public static void test_xml2Account(){
        inTest = true;
        String textXml = '<?xml version="1.0" encoding="utf-8"?><response xmlns="http://www.freshbooks.com/api/" status="ok"><clients page="1" per_page="15" pages="3" total="42"><client><client_id>13</client_id><first_name>Jane</first_name><last_name>Doe</last_name><organization>ABC Corp</organization><email>janedoe@freshbooks.com</email><username>janedoe</username><work_phone>(555) 123-4567</work_phone><home_phone>(555) 234-5678</home_phone><mobile></mobile><fax></fax><language>en</language><currency_code>USD</currency_code><credit currency="USD" deprecated="true">123.45</credit><credits><credit currency="USD">123.45</credit><credit currency="CAD">43.45</credit><credit currency="EUR">12.00</credit></credits><notes>Prefers email over phone calls</notes><p_street1>123 Fake St.</p_street1><p_street2>Unit 555</p_street2><p_city>New York</p_city><p_state>New York</p_state><p_country>United States</p_country><p_code>553132</p_code></client></clients></response>';
        Dom.Document doc = new Dom.Document();
        doc.load(textXml);
        Account a = xml2Account(doc.getRootElement().getChildElement('clients',FRESHBOOKS_XML_API_NS).getChildElement('client',FRESHBOOKS_XML_API_NS));
        System.assert(a.Freshbooks_Client_ID__c == '13');
    }
    
    public static Freshbooks_Project__c[] getProjects(){
        return getProjects(null);
    }
    
    public static Freshbooks_Project__c[] getProjects(Map<String,String> filter){
        List<Freshbooks_Project__c> projectsToReturn = new List<Freshbooks_Project__c>();
        Integer lastBatchSize = LIST_PAGE_COUNT_MAX;
        Integer pageNumber = 1;
        while(lastBatchSize == LIST_PAGE_COUNT_MAX){
            Freshbooks_Project__c[] projectsBatch = getProjects(pageNumber,filter);
            pageNumber++;
            lastBatchSize = projectsBatch.size();
            projectsToReturn.addAll(projectsBatch);
        }
        return projectsToReturn;
    }
    public static final String TEST_GET_PROJECTS_XML = '<?xml version="1.0" encoding="utf-8"?><response xmlns="http://www.freshbooks.com/api/" status="ok"><projects page="1" per_page="15" pages="1" total="5"><project><project_id>123</project_id><name>Super Fun Project</name><description/><rate>11000</rate><bill_method>flat-rate</bill_method><client_id>123</client_id><hour_budget>100</hour_budget><staff><staff_id>1</staff_id><staff_id>2</staff_id><staff_id>3</staff_id></staff></project></projects></response>';
    public static Freshbooks_Project__c[] getProjects(Integer pageNumber, Map<String,String> filter){
        Dom.Document requestDoc = new Dom.Document();
        Dom.XmlNode root = requestDoc.createRootElement('request', null, null);
        root.setAttribute('method', 'project.list');
        root.addChildElement('page', null, null).addTextNode(String.valueOf(pageNumber));
        if(filter != null && !filter.isEmpty())
            for(String k : filter.keySet())
                root.addChildElement(k,null,null).addTextNode(filter.get(k));
        if(filter == null || !filter.keySet().contains('per_page'))
            root.addChildElement('per_page',null,null).addTextNode(String.valueOf(LIST_PAGE_COUNT_MAX));
        Dom.Document responseDoc = ( inTest == true ? CambridgeCloudPartnersREST.domify(TEST_GET_PROJECTS_XML) : post(requestDoc) );
        checkError(responseDoc,'Error occured when getting client');
        Dom.XmlNode responseRoot = responseDoc.getRootElement();
        Dom.XmlNode projectNodes = responseRoot.getChildElement('projects',FRESHBOOKS_XML_API_NS);
        List<Freshbooks_Project__c> projectsToReturn = new List<Freshbooks_Project__c>();
        if(projectNodes != null && projectNodes.getChildElements() != null && !projectNodes.getChildElements().isEmpty())
        for(Dom.Xmlnode projectNode : projectNodes.getChildElements()){
            projectsToReturn.add(xml2Project(projectNode));
        }
        return projectsToReturn;
    }
    
    @isTest
    public static void test_getProjects(){
        inTest = true;
        Freshbooks_Project__c[] projects = getProjects();
        System.assert(projects != null);
        System.assert(projects.size() == 1);
    }
    
    private static String getText(DOM.XMLNode parentNode, String nodeName){
        try{
            return parentNode.getChildElement(nodeName,FRESHBOOKS_XML_API_NS).getText();
        }catch(Exception e){
            return '';
        }
    }
    
    private static Freshbooks_Project__c xml2Project(Dom.Xmlnode node){
        Freshbooks_Project__c project = new Freshbooks_Project__c();
        String field = '';
        try{
            /* put this on hold until we need it, need more work around handling types other than string
            Map<String,String> fieldMappings = new Map<String,String>{
                'project_id' => 'Freshbooks_Project_ID__c',
                'name' => 'Freshbooks_Project_ID__c',
                'description' => 'Freshbooks_Project_ID__c',
                'rate' => 'Freshbooks_Project_ID__c',
                'bill_method' => 'Freshbooks_Project_ID__c',
                //'client_id' => 'Freshbooks_Project_ID__c', // need to handle in non-standard way
                'hour_budget' => 'Freshbooks_Project_ID__c',
                'project_id' => 'Freshbooks_Project_ID__c'
            };
            zipperXmlToSObject(node,fieldMappings,(SObject)project);
            */
            field = 'project_id';
            project.Freshbooks_Project_ID__c = getText(node, 'project_id');
            field = 'name';
            project.Name = getText(node, 'name');
            field = 'description';
            project.Description__c = getText(node, 'description');
            field = 'rate';
            if(getText(node, 'rate').trim() != '')
                project.Rate__c = Double.valueOf(getText(node, 'rate'));
            field = 'bill_method';
            project.Bill_Method__c = getText(node, 'bill_method');
            field = 'client_id';
            if(getText(node, 'client_id').trim() != '')
                project.Account__r = new Account(Freshbooks_Client_ID__c = getText(node, 'client_id'));
            field = 'hour_budget';
            if(getText(node, 'hour_budget').trim() != '')
                project.Hour_Budget__c = Double.valueOf(getText(node, 'hour_budget'));
            //TODO: link to staff in future version
            //staff/staff_id
            //staff/staff_id
        }catch(Exception e){
            throw new FreshbooksException('Error parsing project information response from Freshbooks ('+field+'): '+e.getMessage()+node);
        }
        return project;
    }
    @isTest public static void test_xml2project(){
        inTest = true;
        Dom.Document doc = new Dom.Document();
        doc.load(TEST_GET_PROJECTS_XML);
        Freshbooks_Project__c project = xml2Project(doc.getRootElement().getChildElement('projects',FRESHBOOKS_XML_API_NS).getChildElement('project',FRESHBOOKS_XML_API_NS));
        System.assert(project.Freshbooks_Project_ID__c == '123');
    }
    
    
    
    // --- invoices
    
    public static Freshbooks_Invoice__c[] getInvoices(){
        return getInvoices(null);
    }
    public static Freshbooks_Invoice__c[] getInvoices(Map<String,String> filter){
        List<Freshbooks_Invoice__c> invoicesToReturn = new List<Freshbooks_Invoice__c>();
        Integer lastBatchSize = LIST_PAGE_COUNT_MAX;
        Integer pageNumber = 1;
        while(lastBatchSize == LIST_PAGE_COUNT_MAX){
            Freshbooks_Invoice__c[] batch = getInvoices(pageNumber,filter);
            pageNumber++;
            lastBatchSize = batch.size();
            invoicesToReturn.addAll(batch);
        }
        return invoicesToReturn;
    }
    public static final String TEST_GET_INVOICES_XML = '<?xml version="1.0" encoding="utf-8"?><response xmlns="http://www.freshbooks.com/api/" status="ok"><invoices page="1" per_page="10" pages="4" total="47"><invoice><invoice_id>123</invoice_id><client_id>123</client_id><number>FB00004</number><amount>45.6</amount><currency_code>CAD</currency_code><language>en</language><amount_outstanding>0</amount_outstanding><status>paid</status><date>2007-06-23</date><folder>active</folder><po_number/><discount>0</discount><notes>Due upon receipt.</notes><terms>Payment due in 30 days.</terms><url deprecated="true">https://2ndsite.freshbooks.com/view/St2gThi6rA2t7RQ</url><auth_url deprecated="true">https://2ndsite.freshbooks.com/invoices/344</auth_url><links><client_view>https://2ndsite.freshbooks.com/view/St2gThi6rA2t7RQ</client_view><view>https://2ndsite.freshbooks.com/invoices/344</view><edit>https://2ndsite.freshbooks.com/invoices/344/edit</edit></links><return_uri>http://www.example.com/callback</return_uri><updated>2009-08-12 09:00:00</updated><recurring_id>15</recurring_id><organization>ABC Corp</organization><first_name>John</first_name><last_name>Doe</last_name><p_street1>123 Fake St.</p_street1><p_street2>Unit 555</p_street2><p_city>New York</p_city><p_state>New York</p_state><p_country>United States</p_country><p_code>553132</p_code><vat_name/><vat_number/><lines><line><line_id>1</line_id><!-- (Read Only) line id --><amount>40</amount><name>Yard work</name><description>Mowed the lawn</description><unit_cost>10</unit_cost><quantity>4</quantity><tax1_name>GST</tax1_name><tax2_name>PST</tax2_name><tax1_percent>5</tax1_percent><tax2_percent>8</tax2_percent><type>Item</type></line></lines></invoice></invoices></response>';
    public static Freshbooks_Invoice__c[] getInvoices(Integer pageNumber, Map<String,String> filter){
        Dom.Document requestDoc = new Dom.Document();
        Dom.XmlNode root = requestDoc.createRootElement('request', null, null);
        root.setAttribute('method', 'invoice.list');
        root.addChildElement('page', null, null).addTextNode(String.valueOf(pageNumber));
        if(filter != null && !filter.isEmpty())
            for(String k : filter.keySet())
                root.addChildElement(k,null,null).addTextNode(filter.get(k));
        if(filter == null || !filter.keySet().contains('per_page'))
            root.addChildElement('per_page',null,null).addTextNode(String.valueOf(LIST_PAGE_COUNT_MAX));
        Dom.Document responseDoc = ( inTest == true ? CambridgeCloudPartnersREST.domify(TEST_GET_INVOICES_XML) : post(requestDoc) );
        checkError(responseDoc,'Error occured when getting invoice');
        Dom.XmlNode responseRoot = responseDoc.getRootElement();
        Dom.XmlNode invoices = responseRoot.getChildElement('invoices',FRESHBOOKS_XML_API_NS);
        List<Freshbooks_Invoice__c> toReturn = new List<Freshbooks_Invoice__c>();
        if(invoices != null && invoices.getChildElements() != null && !invoices.getChildElements().isEmpty())
        for(Dom.Xmlnode invoice : invoices.getChildElements()){
            toReturn.add(xml2Invoice(invoice));
        }
        return toReturn;
    }
    @isTest
    public static void test_getInvoices(){
        inTest = true;
        Freshbooks_Invoice__c[] invoices = getInvoices();
        System.assert(invoices != null);
        System.assert(invoices.size() == 1);
    }
    
    private static Freshbooks_Invoice__c xml2Invoice(Dom.Xmlnode node){
        Freshbooks_Invoice__c project = new Freshbooks_Invoice__c();
        String field = '';
        try{
            field = 'invoice_id';
            project.Freshbooks_Invoice_ID__c = node.getChildElement('invoice_id',FRESHBOOKS_XML_API_NS).getText();
            field = 'client_id';
            project.Account__r = new Account(Freshbooks_Client_ID__c = node.getChildElement('client_id',FRESHBOOKS_XML_API_NS).getText());
            field = 'number';
            project.Name = node.getChildElement('number',FRESHBOOKS_XML_API_NS).getText();
            field = 'amount';
            project.Amount__c = Double.valueOf(node.getChildElement('amount',FRESHBOOKS_XML_API_NS).getText());
            project.Amount_Outstanding__c = Double.valueOf(node.getChildElement('amount_outstanding',FRESHBOOKS_XML_API_NS).getText());
            
            project.Status__c = node.getChildElement('status',FRESHBOOKS_XML_API_NS).getText();
            project.Invoice_Date__c = Date.valueOf(node.getChildElement('date',FRESHBOOKS_XML_API_NS).getText());
            /*
            <currency_code>CAD</currency_code>
            <language>en</language>
            <folder>active</folder>
            <po_number/>
            <discount>0</discount>
            <notes>Due upon receipt.</notes>
            <terms>Payment due in 30 days.</terms>
            <url deprecated="true">https://2ndsite.freshbooks.com/view/St2gThi6rA2t7RQ</url>
            <auth_url deprecated="true">https://2ndsite.freshbooks.com/invoices/344</auth_url>
            <links>
                <client_view>https://2ndsite.freshbooks.com/view/St2gThi6rA2t7RQ</client_view>
                <view>https://2ndsite.freshbooks.com/invoices/344</view>
                <edit>https://2ndsite.freshbooks.com/invoices/344/edit</edit>
            </links>
            <return_uri>http://www.example.com/callback</return_uri>
            <updated>2009-08-12 09:00:00</updated>
            <recurring_id>15</recurring_id>
            <organization>ABC Corp</organization>
            <first_name>John</first_name>
            <last_name>Doe</last_name>
            <p_street1>123 Fake St.</p_street1>
            <p_street2>Unit 555</p_street2>
            <p_city>New York</p_city>
            <p_state>New York</p_state>
            <p_country>United States</p_country>
            <p_code>553132</p_code>
            <vat_name/>
            <vat_number/>
            <lines>
                <line>
                    <line_id>1</line_id>
                    <!-- (Read Only) line id -->
                    <amount>40</amount>
                    <name>Yard work</name>
                    <description>Mowed the lawn</description>
                    <unit_cost>10</unit_cost>
                    <quantity>4</quantity>
                    <tax1_name>GST</tax1_name>
                    <tax2_name>PST</tax2_name>
                    <tax1_percent>5</tax1_percent>
                    <tax2_percent>8</tax2_percent>
                    <type>Item</type>
                </line>
            </lines>
            */
        }catch(Exception e){
            throw new FreshbooksException('Error parsing project information response from Freshbooks ('+field+'): '+e.getMessage()+node);
        }
        return project;
    }
    @isTest public static void test_xml2Invoice(){
        inTest = true;
        Dom.Document doc = new Dom.Document();
        doc.load(TEST_GET_INVOICES_XML);
        Freshbooks_Invoice__c invoice = xml2Invoice(doc.getRootElement().getChildElement('invoices',FRESHBOOKS_XML_API_NS).getChildElement('invoice',FRESHBOOKS_XML_API_NS));
        System.assert(invoice.Freshbooks_Invoice_ID__c == '123');
    }
    
    
    
    // --- time entries
    
    public static Freshbooks_Time_Entry__c[] getTimeEntries(){
        return getTimeEntries(null);
    }
    public static Freshbooks_Time_Entry__c[] getTimeEntries(Map<String,String> filter){
        List<Freshbooks_Time_Entry__c> toReturn = new List<Freshbooks_Time_Entry__c>();
        Integer lastBatchSize = LIST_PAGE_COUNT_MAX;
        Integer pageNumber = 1;
        while(lastBatchSize == LIST_PAGE_COUNT_MAX){
            Freshbooks_Time_Entry__c[] batch = getTimeEntries(pageNumber,filter);
            pageNumber++;
            lastBatchSize = batch.size();
            toReturn.addAll(batch);
        }
        return toReturn;
    }
    public static final String TEST_GET_TIME_ENTRIES_XML = '<?xml version="1.0" encoding="utf-8"?><response xmlns="http://www.freshbooks.com/api/" status="ok"><time_entries page="1" per_page="15" pages="10" total="142"><time_entry><time_entry_id>123</time_entry_id><staff_id>123</staff_id><project_id>123</project_id><task_id>123</task_id><hours>2</hours><date>2009-03-13</date><notes>Sample Notes</notes></time_entry></time_entries></response>';
    public static Freshbooks_Time_Entry__c[] getTimeEntries(Integer pageNumber, Map<String,String> filter){
        Dom.Document requestDoc = new Dom.Document();
        Dom.XmlNode root = requestDoc.createRootElement('request', null, null);
        root.setAttribute('method', 'time_entry.list');
        root.addChildElement('page', null, null).addTextNode(String.valueOf(pageNumber));
        if(filter != null && !filter.isEmpty())
            for(String k : filter.keySet())
                root.addChildElement(k,null,null).addTextNode(filter.get(k));
        if(filter == null || !filter.keySet().contains('per_page'))
            root.addChildElement('per_page',null,null).addTextNode(String.valueOf(LIST_PAGE_COUNT_MAX));
        Dom.Document responseDoc = ( inTest == true ? CambridgeCloudPartnersREST.domify(TEST_GET_TIME_ENTRIES_XML) : post(requestDoc) );
        checkError(responseDoc,'Error occured when getting time entries');
        Dom.XmlNode responseRoot = responseDoc.getRootElement();
        Dom.XmlNode timeEntries = responseRoot.getChildElement('time_entries',FRESHBOOKS_XML_API_NS);
        List<Freshbooks_Time_Entry__c> toReturn = new List<Freshbooks_Time_Entry__c>();
        if(timeEntries != null && timeEntries.getChildElements() != null && !timeEntries.getChildElements().isEmpty())
        for(Dom.Xmlnode timeEntry : timeEntries.getChildElements()){
            toReturn.add(xml2TimeEntry(timeEntry));
        }
        return toReturn;
    }
    
    private static Freshbooks_Time_Entry__c xml2TimeEntry(Dom.Xmlnode node){
        Freshbooks_Time_Entry__c timeEntry = new Freshbooks_Time_Entry__c();
        String field = '';
        try{
            field = 'time_entry_id';
            timeEntry.Freshbooks_Time_Entry_ID__c = node.getChildElement('time_entry_id',FRESHBOOKS_XML_API_NS).getText();
            field = 'project_id';
            timeEntry.Freshbooks_Project__r = new Freshbooks_Project__c(Freshbooks_Project_ID__c = node.getChildElement('project_id',FRESHBOOKS_XML_API_NS).getText());
            field = 'hours';
            timeEntry.Hours__c = Double.valueOf(node.getChildElement('hours',FRESHBOOKS_XML_API_NS).getText());
            field = 'date';
            timeEntry.Date__c = Date.valueOf(node.getChildElement('date',FRESHBOOKS_XML_API_NS).getText());
            field = 'notes';
            timeEntry.Notes__c = node.getChildElement('notes',FRESHBOOKS_XML_API_NS).getText();
            
            timeEntry.Name = ( timeEntry.Notes__c.length()>50 ? timeEntry.Notes__c.substring(0,50) : timeEntry.Notes__c );
            /*
            <staff_id>1</staff_id>
            <task_id>1</task_id>
            */
        }catch(Exception e){
            throw new FreshbooksException('Error parsing time entry information response from Freshbooks ('+field+'): '+e.getMessage()+node);
        }
        return timeEntry;
    }
    @isTest public static void test_xml2TimeEntry(){
        inTest = true;
        Dom.Document doc = new Dom.Document();
        doc.load(TEST_GET_TIME_ENTRIES_XML);
        Freshbooks_Time_Entry__c te = xml2TimeEntry(doc.getRootElement().getChildElement('time_entries',FRESHBOOKS_XML_API_NS).getChildElement('time_entry',FRESHBOOKS_XML_API_NS));
        System.assert(te.Freshbooks_Time_Entry_ID__c == '123');
    }
    
    
    
    
    /* handle later when we can do a describe on the data types
    private void zipperXmlToSObject(Dom.XmlNode node, Map<String,String> mappings, SObject sobj){
        for(String k : mappings.keySet()){
            Dom.XmlNode value = node.getChildElement(k,null);
            if(value == null) value = node.getChildElement(k,FRESHBOOKS_XML_API_NS);
            if(value != null) sobj.put(mappings.get(k),value.getText());
        }
    }
    */
    
    private static Dom.Document post(Dom.Document requestXml){
        if(settings == null) settings = Freshbooks_Settings_Protected__c.getInstance();
        String url = 'https://'+settings.Subdomain__c+'.freshbooks.com/api/2.1/xml-in ';
        return CambridgeCloudPartnersREST.domify(
            CambridgeCloudPartnersREST.restPost(url, requestXml.toXmlString().replace('UTF-8','utf-8'), settings.Token__c, 'x')
        );
    }
    @isTest public static void test_post(){
        inTest = true;
        CambridgeCloudPartnersREST.inTest = true;
        if(Freshbooks_Settings_Protected__c.getInstance()==null)
            insert new Freshbooks_Settings_Protected__c(
                Subdomain__c = 'asdf',
                Token__c = 'asdf'
            );
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('test', null, null);
        root.addChildElement('test', null, null);
        Dom.Document response = post(doc);
        System.assert(response != null);
    }
    
    // XXX: freshbooks returns times in the timezone in the account settings but this function parse it without awareness of what that time zone is
    public static Datetime parseFreshbooksDatetime(String input) {
        if(input == null)
            return null;
        try {
            String[] split = input.split(' ');
            String[] dateSplit = split[0].split('-');
            String[] timeSplit = split[1].split(':');
            return DateTime.newInstance(Integer.valueOf(dateSplit[0]), Integer.valueOf(dateSplit[1]), Integer.valueOf(dateSplit[2]), 
                Integer.valueOf(timeSplit[0]), Integer.valueOf(timeSplit[1]), Integer.valueOf(timeSplit[2]));
        } catch(Exception e) {
            return null;
        } 
    }
    @isTest public static void test_parseFreshbooksDate(){
        Datetime response = parseFreshbooksDatetime('2009-08-12 09:00:00');
        System.assert(response != null);
        response = parseFreshbooksDatetime(null);
        System.assert(response == null);
        response = parseFreshbooksDatetime('');
        System.assert(response == null);
        response = parseFreshbooksDatetime('2010-10-10');
        System.assert(response == null);
        response = parseFreshbooksDatetime('123');
        System.assert(response == null);
    }
}
