public with sharing class FreshbooksSync {
	public String inTest;
	public String pageTitle {get;private set;}
	public String id {get;private set;}
	public String idType {get;private set;}
	public String pageMode {get;private set;}
	
	public Boolean getShowInformationMessage(){return informationMessage != '' && informationMessage != null;}
	public String informationMessage {get;private set;} {informationMessage = '';}
	public PageReference informationMessageContinueTo {get;private set;}
	
	public Boolean getShowProgressBar(){return progressBarMaximumValue != 0;}
	public Integer getProgressBarValue(){if(progressBarMaximumValue==0) return 0;return Integer.valueOf(100*(progressBarCurrentValue/progressBarMaximumValue));}
	private Integer progressBarCurrentValue = 0;
	private Integer progressBarMaximumValue = 0;
	
	public Id batchId {get;private set;}
	
	public Id fullSyncBatchId {get;private set;}
	
	public String clientId {get;private set;}
	
	public Freshbooks_Settings_Protected__c settings {get;set;}
	
	public FreshbooksSync(ApexPages.StandardController stdController){
		Account a = (Account)stdController.getRecord();
		id = a.Id;
		idType = 'Account';
		pageTitle = 'Synchronizing '+idType+' '+getAccount(id).Name;
		clientId = getAccount(id).Freshbooks_Client_ID__c;
		if(idType == 'Account' && id != null && clientId == null)
			pageMode = 'clientSearch';
		else if(idType == 'Account' && id != null && clientId != null)
			pageMode = 'clientSync';
		
	}
	
	public FreshbooksSync(){
		pageTitle = 'Enterprise Connector for Freshbooks and Salesforce';
		pageMode = 'home';
		
		settings=Freshbooks_Settings_Protected__c.getInstance();
		if(settings==null) settings=new Freshbooks_Settings_Protected__c();
	}
	
	public PageReference immediateAction(){
		if(pageMode == 'clientSync'){
			batchId = scheduleSyncBatch(clientId);
			ajaxCheckStatus(); // so the progress bar gets drawn
			return null;
		}else{
			return null;
		}
	}
	
	public void scheduleBatchUpdate(){
		FreshbooksSyncBatch.schedule();
		ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.INFO, 'Scheduler configured successfully') );
	}
	public void runFullSyncNow(){
		if(fullSyncBatchId != null){
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.INFO, 'Woah nelly!  You already started a full sync not too long ago.  Are you sure you want to do that??') );
			fullSyncBatchId = null;
		}
		fullSyncBatchId = FreshbooksSyncBatch.runFullSyncNow();
		ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.INFO, 'Your full sync batch has been started.  You will receive an email with the details of the sync run after it is complete.  Now, shouldn\'t you be logging hours?') );
	}
	private Id scheduleSyncBatch(String clientId){
		FreshbooksSyncBatch batch = new FreshbooksSyncBatch();
		batch.taskQueue = new List<FreshbooksSyncBatch.FreshbooksSyncTask>{
			new FreshbooksSyncBatch.FreshbooksSyncTask('client',clientId)
		};
		return Database.executeBatch(batch,1);
	}
	
	public Account[] getClientList(){
		//if(pageMode != 'clientList') return null; // even though rendered is used in the page, getter is still called sometimes
		try{
			Account[] clientsSearchResults = FreshbooksAPI.getClients();
			clientsSearchResults.add(new Account(Name = '** Not Found, Create New **'));
			return clientsSearchResults;
		}catch(Exception e){
			ApexPages.addMessages(e);
			return null;
		}
		//TODO: identify the ones that are already linked to records in salesforce
	}
	
	public String clientIdSelected {get;set;}
	public PageReference chooseOrganizationFromSearch(){
		
		Account a = getAccount(id);
		if(clientIdSelected == '' || clientIdSelected == null){
			// default the email to my email until we build some workflow around this
			if(a.Freshbooks_Email__c == null) a.Freshbooks_Email__c = [select Id,Email from User where Id = :UserInfo.getUserId()].Email;
			FreshbooksAPI.saveClient(a);
		}else{
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'account: '+a));
			a.Freshbooks_Client_ID__c = clientIdSelected;
		}
		try{
			update a;
		}catch(Exception e){
			ApexPages.addMessages(e);
			return null;
		}
		clientId = a.Freshbooks_Client_ID__c;
		batchId = scheduleSyncBatch(clientId);
		pageMode = 'clientSync';
		return null; // want to land on the page so the sync runs
		//TODO: next page should be a refresh of either side of data
	}
	
	public AsyncApexJob batchJob {get;private set;}
	public PageReference ajaxCheckStatus(){
		try{
			batchJob = [
				select Id,ApexClassId,JobItemsProcessed,TotalJobItems,NumberOfErrors,CreatedBy.Email,CompletedDate,ExtendedStatus
				from AsyncApexJob
				where id = :batchId
			];
			if(batchJob.ExtendedStatus != null && batchJob.ExtendedStatus != ''){
				informationMessage += 'Error: '+batchJob.ExtendedStatus;
				return null;
			}
		}catch(Exception e){
			ApexPages.addMessages(e);
			return null;
		}
		if(batchJob.CompletedDate != null)
			return new PageReference('/'+id);
		return null;
	}
	
	private Account getAccount(Id accountId){
		return Database.query('select Id,'+FreshbooksAPI.FRESHBOOKS_ACCOUNT_FIELDS+' from Account where Id = :accountId');
		//return [select Id,Name,Phone,Fax,Freshbooks_Client_ID__c,Freshbooks_Email__c from Account where Id = :accountId];
	}
	
	@isTest public static void test_FreshbooksSyncNewClient(){
		FreshbooksAPI.inTest = true;
		CambridgeCloudPartnersREST.inTest = true;
		Account a = new Account(
			Name = 'Test Corp'
		);
		insert a;
		PageReference pageRef = Page.FreshbooksSyncAccount;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController standardController = new ApexPages.StandardController(a);
		FreshbooksSync c = new FreshbooksSync(standardController);
		c.immediateAction();
		c.getClientList();
		c.clientIdSelected = '123123123123';
		System.assert( ApexPages.getMessages().isEmpty() );
		c.chooseOrganizationFromSearch();
		System.assert( ApexPages.getMessages().isEmpty(), ApexPages.getMessages() );
		c.ajaxCheckStatus();
		System.assert( ApexPages.getMessages().isEmpty(), ApexPages.getMessages() );
	}
	@isTest public static void test_FreshbooksSyncExistingClient(){
		FreshbooksAPI.inTest = true;
		CambridgeCloudPartnersREST.inTest = true;
		Account a = new Account(
			Name = 'Test Corp',
			Freshbooks_Client_ID__c = '123'
		);
		insert a;
		Test.startTest();
		PageReference pageRef = Page.FreshbooksSyncAccount;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController standardController = new ApexPages.StandardController(a);
		FreshbooksSync c = new FreshbooksSync(standardController);
		c.immediateAction();
		c.getShowProgressBar();
		c.getProgressBarValue();
		System.assert(c.batchId != null);
		Test.stopTest();
		c.ajaxCheckStatus();
		c.getShowInformationMessage();
		c.getShowProgressBar();
		c.getProgressBarValue();
	}
	
	@isTest public static void test_FreshbooksSyncHome(){
		FreshbooksAPI.inTest = true;
		CambridgeCloudPartnersREST.inTest = true;
		Account a = new Account(
			Name = 'Test Corp',
			Freshbooks_Client_ID__c = '123'
		);
		insert a;
		Test.startTest();
		System.Test.setCurrentPageReference(new PageReference('/apex/FreshbooksSync'));
		FreshbooksSync c = new FreshbooksSync();
		c.immediateAction();
		System.assert(c.batchId == null);
		c.scheduleBatchUpdate();
		c.runFullSyncNow();
		c.saveSettings();
		c.testSettings();
		c.getShowInformationMessage();
		Test.stopTest();
	}
	
	// --- settings editing
	public Boolean getCanSeeSettings(){
		Profile p = [select Id,Name from Profile where Id = :UserInfo.getProfileId()];
		return p.Name.equals('System Administrator');
	}
	public void testSettings(){
		// test the connection
		Account[] clientsSearchResults;
		try{
			clientsSearchResults = FreshbooksAPI.getClients();
		}catch(Exception e){
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'I tried to login using those credentials but it did not work:  '+e) );
			//ApexPages.addmessages(e);
			return;
		}
		ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.INFO, 'Your freshbooks credentials were tested successfully.  Wooha!') );
	}
	public void saveSettings(){
		//TODO: validate that it's an admin saving it?
		upsert settings;
	}
}