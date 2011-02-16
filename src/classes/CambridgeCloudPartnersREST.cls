public with sharing class CambridgeCloudPartnersREST {
	public static Boolean inTest;
	public static String testReturnXml;
	private static final String TEST_XML = '<?xml version="1.0" encoding="utf-8"?><response xmlns="http://www.freshbooks.com/api/" status="ok"><clients page="1" per_page="15" pages="3" total="42"><client><client_id>13</client_id><first_name>Jane</first_name><last_name>Doe</last_name><organization>ABC Corp</organization><email>janedoe@freshbooks.com</email><username>janedoe</username><work_phone>(555) 123-4567</work_phone><home_phone>(555) 234-5678</home_phone><mobile></mobile><fax></fax><language>en</language><currency_code>USD</currency_code><credit currency="USD" deprecated="true">123.45</credit><credits><credit currency="USD">123.45</credit><credit currency="CAD">43.45</credit><credit currency="EUR">12.00</credit></credits><notes>Prefers email over phone calls</notes><p_street1>123 Fake St.</p_street1><p_street2>Unit 555</p_street2><p_city>New York</p_city><p_state>New York</p_state><p_country>United States</p_country><p_code>553132</p_code></client></clients></response>';
	public static Dom.Document domify(String xml){
		Dom.Document doc = new Dom.Document();
		doc.load(xml);
		return doc;
	}
	@isTest
	public static void test_domify(){
		inTest = true;
		Dom.Document doc = domify(TEST_XML);
		System.assert(doc != null);
	}
	
	public static String restGet(String url){
		return restGet(url,null,null);
	}
	@isTest
	public static void test_restGet(){
		inTest = true;
		String response = restGet('http://salesforce.com');
		System.assert(response != null);
	}
	public static String restGet(String url, String basicUsername, String basicPassword){
		return rest('GET',url,'',basicUsername,basicPassword);
	}
	public static String restPost(String url, String body){
		return restPost(url,body,null,null);
	}
	@isTest
	public static void test_restPost(){
		inTest = true;
		String response = restPost('http://salesforce.com',TEST_XML);
		System.assert(response != null);
	}
	public static String restPost(String url, String body, String basicUsername, String basicPassword){
		return rest('POST',url,body, basicUsername, basicPassword);
	}
	public static String restPut(String url, String body){
		return restPut(url,body,null,null);
	}
	@isTest
	public static void test_restPut(){
		inTest = true;
		String response = restPut('http://salesforce.com',TEST_XML);
		System.assert(response != null);
	}
	public static String restPut(String url, String body, String basicUsername, String basicPassword){
		return rest('PUT',url,body, basicUsername, basicPassword);
	}
	public static String restDelete(String url){
		return restDelete(url,null,null);
	}
	@isTest
	public static void test_restDelete(){
		inTest = true;
		String response = restDelete('http://salesforce.com');
		System.assert(response != null);
	}
	public static String restDelete(String url, String basicUsername, String basicPassword){
		return rest('DELETE',url,'', basicUsername, basicPassword);
	}
	private static String rest(String method, String url, String body){
		return rest(method, url, body, null,null);
	}
	@isTest
	public static void test_rest(){
		inTest = true;
		String response = rest('GET','http://salesforce.com',TEST_XML);
		System.assert(response != null);
	}
	private static String rest(String method, String url, String body, String basicUsername, String basicPassword){
		
		System.debug('******** url: '+url);
		System.debug('******** body: '+body);
		
		HttpRequest req = new HttpRequest(); 
		req.setMethod(method);
		req.setHeader('Connection','keep-alive');
		req.setEndpoint(url);
		req.setBody(body);
		// perform authentication if requested
		if(basicUsername != null || basicPassword != null){
			System.debug('******** basicUsername: '+basicUsername);
			System.debug('******** basicPassword: '+basicPassword);
			req.setHeader('Authorization', 'Basic '+EncodingUtil.base64Encode(Blob.valueOf(basicUsername+':'+basicPassword)));
			// interesting - the capitalization matters from service to service
			//Blob headerValue = Blob.valueOf(basicUsername + ':' + basicPassword); 
			//String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue); 
			//req.setHeader('Authorization', authorizationHeader);
		}
		
		Http http = new Http();
		HTTPResponse res;
		
		if(inTest == true){
			return (testReturnXml == null ? TEST_XML : testReturnXml);
		}else{
			res = http.send(req);
			//System.debug('res = '+res);
			//System.debug('HTTP_RESPONSE:'+res.toString());
			System.debug('HTTP_RESPONSE_BODY:'+res.getBody());
			//System.debug('STATUS:'+res.getStatus());
			//System.debug('STATUS_CODE:'+res.getStatusCode());
			return res.getBody();
		}
	}
	@isTest
	public static void test_restWithAuthentication(){
		CambridgeCloudPartnersREST.inTest = true;
		String response = rest('GET','http://salesforce.com',TEST_XML,'testuser','testpass');
		System.assert(response != null);
	}
}