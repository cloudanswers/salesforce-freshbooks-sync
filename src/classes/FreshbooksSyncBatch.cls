global class FreshbooksSyncBatch implements Schedulable, Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful{
	public List<FreshbooksSyncTask> taskQueue = new List<FreshbooksSyncTask>();
	public Set<String> taskQueueSeen = new Set<String>();
	public List<Integer> iterator; // allows us to step through the taskqueue list dynamically
	
	global Iterable<Integer> start(Database.batchableContext info){
		// create a padded iterator so that we can add work to the work queue (taskQueue)
		iterator = new List<Integer>();
		Integer iterationsNeeded = 50 * taskQueue.size();
		if(!taskQueue.isEmpty() && taskQueue.get(0).action.equals('all_clients'))
			iterationsNeeded = 1000;
		for(Integer i = 0 ; i < iterationsNeeded ; i++)
			iterator.add(i);
		return iterator;
	}
	
	global void execute(Database.BatchableContext BC, List<Integer> scope){
		for(Integer index : scope){
			if(index >= taskQueue.size()) break;
			FreshbooksSyncTask t = taskQueue.get(index);
			if(taskQueueSeen.contains(t.fingerprint()))
				continue;
			taskQueueSeen.add(t.fingerprint());
			if(t.action.equals('all_clients')){
				Account[] accounts = FreshbooksAPI.getClients(); // shoot - 1 call out per batch?
				List<Account> upsertBatch = new List<Account>();
				for(Integer i = 0 ; i < accounts.size() ; i++){
					taskQueue.add(new FreshbooksSyncTask('projects_by_client',accounts[i].Freshbooks_Client_ID__c));
					taskQueue.add(new FreshbooksSyncTask('invoices_by_client',accounts[i].Freshbooks_Client_ID__c));
					upsertBatch.add(accounts[i]);
					if(upsertBatch.size() == 200 || i == accounts.size()-1){
						upsert upsertBatch Freshbooks_Client_ID__c;
						upsertBatch = new List<Account>();
					}
				}
			}else if(t.action.equals('client')){
				Account a = FreshbooksAPI.getClient(t.Id);
				upsert a Freshbooks_Client_ID__c;
				taskQueue.add(new FreshbooksSyncTask('projects_by_client',t.Id));
				taskQueue.add(new FreshbooksSyncTask('invoices_by_client',t.Id));
			}else if(t.action.equals('projects_by_client')){
				Freshbooks_Project__c[] projects = FreshbooksAPI.getProjects(new Map<String,String>{'client_id'=>t.id});
				upsert projects Freshbooks_Project_ID__c;
				for(Freshbooks_Project__c p : projects)
					taskQueue.add(new FreshbooksSyncTask('time_entries_by_project',p.Freshbooks_Project_ID__c));
			}else if(t.action.equals('time_entries_by_project')){
				Freshbooks_Time_Entry__c[] timeEntries = FreshbooksAPI.getTimeEntries(new Map<String,String>{'project_id'=>t.id});
				upsert timeEntries Freshbooks_Time_Entry_ID__c;
			}else if(t.action.equals('invoices_by_client')){
				Freshbooks_Invoice__c[] invoices = FreshbooksAPI.getInvoices(new Map<String,String>{'client_id'=>t.id});
				upsert invoices Freshbooks_Invoice_ID__c;
			}
		}
	}
	
	global void finish(Database.BatchableContext BC){
	}
	
	global class FreshbooksSyncTask{
		public String action {get;set;}
		public String id {get;set;}
		public FreshbooksSynctask(String action, String id){
			this.action = action;
			this.id = id;
		}
		public String fingerprint(){
			return action + '|' + id;
		}
	}
	
	@isTest public static void test_FreshbooksSyncBatch(){
		FreshbooksAPI.inTest = true;
		Test.StartTest();
		FreshbooksSyncBatch batch = new FreshbooksSyncBatch();
		batch.taskQueue = new List<FreshbooksSyncTask>{
			new FreshbooksSyncTask('client','123'),
			new FreshbooksSyncTask('projects_by_client','123'),
			new FreshbooksSyncTask('time_entries_by_project','123'),
			new FreshbooksSyncTask('invoices_by_client','123')
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
		b.taskQueue.add(new FreshbooksSyncBatch.FreshbooksSyncTask('all_clients',''));
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
		//String jobId = System.schedule('testScheduledApex',getCRON(), new FreshbooksSyncBatch());
		FreshbooksSyncBatch.schedule();
		String jobId = FreshbooksSyncBatch.scheduledBatchId;
		CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(getCRON(),ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest(); // scheduled job runs here
	}
}