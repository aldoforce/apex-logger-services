apex-logger-services
====================

Apex logger layer. Saves a Document record with the text from logger output.

## Overview

Sometimes the default salesforce's system.debug() method is not enough and you want to serialize the logger output to a record (log file) where you can review and analyze offline.

## Usage
1. Deploy this repo to your org: 3 components will be deployed: a class, a custom setting, and a folder.
2. In your apex class or trigger where you want to log some data, get an instance of the logger, add messages and log the messages (see example for more details)
3. There is no step 3, enjoy!

## Example
#### Original code
```java
LoggerServices logger = LoggerServices.getInstance();
logger.addMessage('hello world!');
logger.logMessages();
```

## Quick Install
Use the Github Salesforce Deploy Tool link [here](https://githubsfdeploy.herokuapp.com/app/githubdeploy/aldoforce/apex-logger-services) while logged into your target org and follow instructions.