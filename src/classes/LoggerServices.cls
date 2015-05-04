/**
* Public class that implements a simple logger that stores information in a document.
* It is implemented using the Singleton pattern to keep the operations centralized.
*
* @author Aldo Fernandez - @aldoforce
*/
public without sharing class LoggerServices {

    public static final String INLINE_SEPARATOR 				= ' | ';
    public static final String MSG_SEPARATOR 					= '\n';
    public static final String WHITE_BLOCK 					= '\n\n\n\n\n';
    public static final String MSG_BLOCK_SEPARATOR 			= '----------------------------------------------------------------------------------------------------------';
    public static final System.LoggingLevel LOGGING_LEVEL 	= LoggingLevel.ERROR; 
    public static final String LOG_FILE_TYPE 					= 'txt';
    public static final String LOG_FILE_CONTENT_TYPE 			= 'text/plain';    

    public static final Integer MAX_LOG_LENGTH 				= 1000000;	// Currently the maximum string length is 3000000,
    																		// but we shouldn't use such large strings since performace will degrade. 
    public static final String LOGFILE_NAME_FORMAT 			= 'yyyy-MM-dd HH:mm:ss:SSSS Z';
    public static final String LOGFILE_API_NAME_FORMAT 		= 'yyyyMMddHHmmssSS';	// Must use gmt for api name, since including the timezone in the api
    																					// name throws an error for the character '-' is not valid for api names 
    public static final String TIMESTAMP_FORMAT 				= 'yyyy-MM-dd HH:mm:ss Z';
    
    public static String LOG_FILENAME							= 'log';    
    public static String APPLICATION_FOLDER_NAME				= 'Logger_Services';
    
    private static LoggerServices instance;    
    private List<String> messages;
   
    /**
    * Private constructor to implement the Singleton pattern
    */
    public LoggerServices() {}
    
    /**
    * @Returns the list of messages that have to be added to the log file.
    */
    private List<String> getMessages() {
        if (messages == null) {
            messages = new List<String>();
        }
        return messages;
    }

    /**
    * Singleton instantiation static method
    *
    * @return the single LoggerServices instance
    * @throws LoggerServicesException if there is no file with the developer name specified in the custom settings for the app.
    */
    public static LoggerServices getInstance() {
        if (instance == null) {
            instance = new LoggerServices();
        }
        return instance;
    }
    
    /**
    * Returns the Twitter log file specified in the configuration settings.
    * Creates a new one if it doesn't exist.
    *
    * @returns the twitter log file
    */
    private Document getOrCreateLog() {
        Document logFile = getLog();
        if (logFile == null) {
			return this.createNewLog();
        }
        else {
            return logFile;
        }
    }
    
    public Document getLog() {
    	Document[] logFiles = [select Name, id, Body from Document 
	    	where DeveloperName LIKE :(LoggerServices.LOG_FILENAME + '%') 
	    	order by developerName desc limit 1];
        if (logFiles.isEmpty()) {
			return null;
        }
        else {
            return logFiles[0];
        }
    }
    
    public List<Document> getLogList() {
    	Document[] logFiles = [select Name, id, CreatedDate, LastModifiedDate from Document 
	    	where DeveloperName LIKE :(LoggerServices.LOG_FILENAME + '%') 
	    	order by CreatedDate desc limit 10];
        if (logFiles.isEmpty()) {
			return null;
        }
        else {
            return logFiles;
        }
    }
       
    /**
    * Renames the current log file and creates a new one.
    *
    * @returns the new log file
    */
    private Document createNewLog() {
        Folder[] logFolder = [select id from Folder where DeveloperName = :LoggerServices.APPLICATION_FOLDER_NAME limit 1];
        //system.debug('\n\n'+logFolder[0].Id+'\n\n');
        //system.debug('\n\n'+logFolder+'\n\n');
        if (logFolder.isEmpty()) {
            throw new LoggerServiceException(String.format('Logger Folder ({0}) not found.', new List<String> { LoggerServices.APPLICATION_FOLDER_NAME }) );
        }
        else {  
        	Datetime now = System.now();
            Document log = new Document(
                Name = LoggerServices.LOG_FILENAME.replace('_', ' ') + ' ' + now.format(LOGFILE_NAME_FORMAT),
                DeveloperName = LoggerServices.LOG_FILENAME + '_' + now.formatGMT(LOGFILE_API_NAME_FORMAT),
                FolderId = logFolder[0].id,
                Type = LOG_FILE_TYPE,
                ContentType = LOG_FILE_CONTENT_TYPE,
                Body = Blob.valueOf('')
            );
            insert log;
            return log;
        }
    }
    
    /**
    * Adds a message to be logged later with the {@link #logMessages() logMessages} method.
    *
    * @param msg    The message that will be logged
    * @return       this LoggerServices object
    */
    public LoggerServices addMessage(String msg) {
        this.getMessages().add(System.now().format(TIMESTAMP_FORMAT) + INLINE_SEPARATOR + msg);
        return this;
    }
    
     /**
    * Adds an Exception message to be logged later with the {@link #logMessages() logMessages} method.
    *
    * @param pMessage    	The message that will be logged
    * @param pException    	The exception object that will be logged
    * @return       this LoggerServices object
    */
    public LoggerServices addException(String pMessage, Exception pException) {				
		this.addMessage('	[ExceptionFrom:] ' + pMessage);
		this.addMessage('	[Message:] ' + pException.getMessage() );
		this.addMessage('	[Line:] ' + pException.getLineNumber() );
		this.addMessage('	[Trace:]\n' + pException.getStackTraceString() );
		this.addSeparator();
		
		return this;	
	}
    
    /**
    * Adds a separator to the log before all the messages, added from now on, are dumped to the document.
    *
    * @return this LoggerServices object
    */
    public LoggerServices addSeparator() {
		this.getMessages().add(MSG_BLOCK_SEPARATOR);
		return this;
    }
    
    /**
    * Adds a white space section to the log, added from now on, are dumped to the document.
    *
    * @return this LoggerServices object
    */
    public LoggerServices addSection() {
		this.getMessages().add(WHITE_BLOCK);
		return this;
    }
    
    /**
    * Updates the document in the database with all the logged messages.
    *
    * @return this LoggerServices object
    */
    public LoggerServices logMessages() {
		Document logFile = null;
		try {
	        logFile = getOrCreateLog();
	        logMessages(logFile);
	        
	        if (Logger_Setup__c.getInstance().Logger_Enabled__c) update logFile;	        	
		} catch (Exception e) {
			logFile = createNewLog();
	        logMessages(logFile);
	        if (Logger_Setup__c.getInstance().Logger_Enabled__c) update logFile;
		}
        getMessages().clear();
        return this;
    }
    
    private void logMessages(Document logFile) {
   		string logMessage = '';
        for (String msg : this.getMessages()) {
            logMessage += msg + MSG_SEPARATOR;
        }
        String bodyString = logFile.Body.toString();
        if ((MAX_LOG_LENGTH - bodyString.length()) < logMessage.length()) {
        
            logFile = createNewLog();	        
            bodyString = '';
        }
        logFile.Body = Blob.valueOf(logMessage + bodyString);
    }
    
    public class LoggerServiceException extends Exception {}
    
    /**
    * Test methods for the LoggerServices class
    */
    public static testMethod void test_1() {
    	test.startTest();
        String invalidFileName = 'dummy_name';
        String validFileName = 'Error_Log';
        String testMessage1 = 'test message 1';
        String testMessage2 = 'test message 2';

        // Delete files to be used
        delete [select id from Document where DeveloperName like :(invalidFileName + '%') or DeveloperName like :(validFileName + '%') LIMIT 1000];
        
        LoggerServices logger = LoggerServices.getInstance();
                     
        // Try an invalid file name
        LoggerServices.LOG_FILENAME = invalidFileName;
        logger.addSeparator();
        logger.addMessage(testMessage1);
        system.assert( logger.logMessages() != null );
        
        // Try a valid file name
        LoggerServices.LOG_FILENAME = validFileName;
        
        Document newDoc = logger.createNewLog();
        logger.addSeparator();
        logger.addMessage(testMessage2);
        logger.logMessages();    
        
        system.assert( logger.getLogList().size() > 0 );
        test.stopTest();
    }
    
 
}