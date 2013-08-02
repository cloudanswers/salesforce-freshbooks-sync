global class FreshbooksSyncBatch implements Schedulable, Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful{
	global class MyException extends Exception {}
	public List<FreshbooksSyncTask> taskQueue = new List<FreshbooksSyncTask>();
	public Set<String> taskQueueSeen = new Set<String>();
	public List<Integer> iterator; // allows us to step through the taskqueue list dynamically
	
	global Iterable<Integer> start(Database.batchableContext info){
		// create a padded iterator so that we can add work to the work queue
		iterator = new List<Integer>();
		Integer iterationsNeeded = 50 * taskQueue.size();
		if(!taskQueue.isEmpty() && taskQueue.get(0).action.equals('all_clients'))
			iterationsNeeded = 1000;
		if(Test.isRunningTest())
			iterationsNeeded = 1;
		for(Integer i = 0 ; i < iterationsNeeded ; i++)
			iterator.add(i);
		return iterator;
	}
	
	global void requeue(FreshbooksSyncTask t){
		requeue(t, null);
	}

	global void requeue(FreshbooksSyncTask t, Exception e){
		if(t.retries>2) throw e; 
		taskQueueSeen.remove(t.fingerprint());
		taskQueue.add(t);
		t.retries++;
	}
	
	@isTest
	public static void test_requeue(){
		FreshbooksSyncBatch b = new FreshbooksSyncBatch();
		FreshbooksSyncTask t = new FreshbooksSyncTask('test', 'test', 0);
		b.requeue(t);
		System.assertEquals(t.retries, 1);
		b.requeue(t);
		System.assertEquals(t.retries, 2);
		b.requeue(t);
		System.assertEquals(t.retries, 3);
		Exception caughtException;
		try{
			b.requeue(t);
		}catch(Exception e){
			caughtException = e;
		}
		System.assert(caughtException != null);
	}
	
	global void execute(Database.BatchableContext BC, List<Integer> scope){
		for(Integer index : scope){
			if(index >= taskQueue.size()) break;
			FreshbooksSyncTask t = taskQueue.get(index);
			if(taskQueueSeen.contains(t.fingerprint()))
				continue;
			taskQueueSeen.add(t.fingerprint());
			if(t.action.equals('all_clients')){
				Account[] accounts;
				try{
					accounts = FreshbooksAPI.getClients(t.page,null);
				}catch(Exception e){
					requeue(t, e);
					continue;
				}
				if(accounts.size() == FreshbooksAPI.LIST_PAGE_COUNT_MAX)
					taskQueue.add(new FreshbooksSyncTask('all_clients',null,t.page+1));
				List<Account> upsertBatch = new List<Account>();
				for(Integer i = 0 ; i < accounts.size() ; i++){
					taskQueue.add(new FreshbooksSyncTask('projects_by_client',accounts[i].Freshbooks_Client_ID__c,1));
					taskQueue.add(new FreshbooksSyncTask('invoices_by_client',accounts[i].Freshbooks_Client_ID__c,1));
					upsertBatch.add(accounts[i]);
					if(upsertBatch.size() == 200 || i == accounts.size()-1){
						upsert upsertBatch Freshbooks_Client_ID__c;
						upsertBatch = new List<Account>();
					}
				}
			}else if(t.action.equals('client')){
				Account a;
				try{
					a = FreshbooksAPI.getClient(t.Id);
				}catch(Exception e){
					requeue(t, e);
					continue;
				}
				upsert a Freshbooks_Client_ID__c;
				taskQueue.add(new FreshbooksSyncTask('projects_by_client',t.Id,1));
				taskQueue.add(new FreshbooksSyncTask('invoices_by_client',t.Id,1));
			}else if(t.action.equals('projects_by_client')){
				Freshbooks_Project__c[] projects;
				try{
					projects = FreshbooksAPI.getProjects(t.page,new Map<String,String>{'client_id'=>t.id});
				}catch(Exception e){
					requeue(t, e);
					continue;
				}
				if(projects.size() == FreshbooksAPI.LIST_PAGE_COUNT_MAX)
					taskQueue.add(new FreshbooksSyncTask('projects_by_client',t.id,t.page+1));
				upsert projects Freshbooks_Project_ID__c;
				for(Freshbooks_Project__c p : projects)
					taskQueue.add(new FreshbooksSyncTask('time_entries_by_project',p.Freshbooks_Project_ID__c,1));
			}else if(t.action.equals('time_entries_by_project')){
				Freshbooks_Time_Entry__c[] timeEntries;
				try{
					timeEntries = FreshbooksAPI.getTimeEntries(t.page,new Map<String,String>{'project_id'=>t.id});
				}catch(Exception e){
					requeue(t, e);
					continue;
				}
				if(timeEntries.size() == FreshbooksAPI.LIST_PAGE_COUNT_MAX)
					taskQueue.add(new FreshbooksSyncTask('time_entries_by_project',t.id,t.page+1));
				upsert timeEntries Freshbooks_Time_Entry_ID__c;
			}else if(t.action.equals('invoices_by_client')){
				Freshbooks_Invoice__c[] invoices;
				try{
					invoices = FreshbooksAPI.getInvoices(t.page,new Map<String,String>{'client_id'=>t.id});
				}catch(Exception e){
					requeue(t, e);
					continue;
				}
				if(invoices.size() == FreshbooksAPI.LIST_PAGE_COUNT_MAX)
					taskQueue.add(new FreshbooksSyncTask('invoices_by_client',t.id,t.page+1));
				upsert invoices Freshbooks_Invoice_ID__c;
			}
		}
	}
	
	@isTest
	public static void test_execute(){
		FreshbooksSyncBatch controller = new FreshbooksSyncBatch();
		controller.taskQueue = new List<FreshbooksSyncTask>{new FreshbooksSyncTask('all_clients', '123', 0)};
		controller.execute(null, new List<Integer>{0});
		controller.taskQueue = new List<FreshbooksSyncTask>{new FreshbooksSyncTask('client', '123', 0)};
		controller.execute(null, new List<Integer>{0});
		controller.taskQueue = new List<FreshbooksSyncTask>{new FreshbooksSyncTask('projects_by_client', '123', 0)};
		controller.execute(null, new List<Integer>{0});
		controller.taskQueue = new List<FreshbooksSyncTask>{new FreshbooksSyncTask('time_entries_by_project', '123', 0)};
		controller.execute(null, new List<Integer>{0});
		controller.taskQueue = new List<FreshbooksSyncTask>{new FreshbooksSyncTask('invoices_by_client', '123', 0)};
		controller.execute(null, new List<Integer>{0});
	}
	
	global void finish(Database.BatchableContext BC){
	}
	
	global class FreshbooksSyncTask{
		public Integer retries = 0;
		public String action {get;set;}
		public String id {get;set;}
		public Integer page {get;set;}
		public FreshbooksSynctask(String action, String id, Integer page){
			this.action = action;
			this.id = id;
			this.page = page;
		}
		public String fingerprint(){
			return action + '|' + id + '|' + page;
		}
	}
	
	@isTest public static void test_FreshbooksSyncBatch(){
		FreshbooksAPI.inTest = true;
		Test.StartTest();
		FreshbooksSyncBatch batch = new FreshbooksSyncBatch();
		batch.taskQueue = new List<FreshbooksSyncTask>{
			new FreshbooksSyncTask('client','123',1),
			new FreshbooksSyncTask('projects_by_client','123',1),
			new FreshbooksSyncTask('time_entries_by_project','123',1),
			new FreshbooksSyncTask('invoices_by_client','123',1)
		};
		Id batchId = Database.executeBatch(batch);
		Test.StopTest();
	}
	
	
	// --- scheduled job methods
	public static Id scheduledBatchId;
	public static void schedule(){
		FreshbooksSyncBatch scheduler = new FreshbooksSyncBatch();
		scheduledBatchId = System.schedule('Freshbooks Scheduled Update',getCRON() ,scheduler);
	}
	public static Id runFullSyncNow(){
		FreshbooksSyncBatch b = new FreshbooksSyncBatch();
		b.taskQueue.add(new FreshbooksSyncBatch.FreshbooksSyncTask('all_clients','',1));
		b.taskQueue.add(new FreshbooksSyncBatch.FreshbooksSyncTask('projects_by_client','',1)); // for internal projects
		return Database.executeBatch(b,1);
	}
	global void execute(SchedulableContext SC) {
		runFullSyncNow();
	}
	// make the CRON value unique because we use this to figure out if this as a fingerprint later
	public static String getCRON(){
		//Datetime dt = Datetime.newInstance(2010, 11, 15, 23, 59, 57);
		//return '57 59 '+dt.hourGmt()+' * * ?';
		return '57 59 23 * * ?';
	}
	//public static final String CRON = '16 59 23 * * ?'; // 0 hour, on the 59th minute
	@isTest
	public static void testScheduler(){
		FreshbooksAPI.inTest = true;
		Test.startTest();
		FreshbooksSyncBatch.schedule();
		String jobId = FreshbooksSyncBatch.scheduledBatchId;
		CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(getCRON(),ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest(); // scheduled job runs here
	}
}