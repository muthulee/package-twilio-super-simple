// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.package twilio;

import ballerina/http;
import ballerina/io;

// Endpoint
documentation {Object for Twilio endpoint.
    F{{twilioConfig}} Reference to TwilioBasicConfiguration type
    F{{twilioConnector}} Reference to TwilioConnector type
}
public type Client object {

    public {
        TwilioConfiguration twilioConfig;
        TwilioConnector twilioConnector = new;
    }

    documentation { Initialize Twilio endpoint
        P{{twilioConfig}} Twilio configuraion
    }
    public function init (TwilioConfiguration twilioConfig);

    documentation { Initialize Twilio endpoint
        R{{}} The Twilio connector object
    }
    public function getClient () returns TwilioConnector;

};


// Connector
documentation {Object to initialize the connection with Twilio.
    F{{accountSid}} Unique identifier of the account
    F{{basicClient}} Http client endpoint
}
public type TwilioConnector object {

    public {
        string accountSid;
        http:Client basicClient;
    }

    documentation { Return account details of the given account-sid.
        R{{account}} Account object with basic details
        R{{err}} Error occured when getting account details by http call or parsing the response into json
    }
    public function getAccountDetails() returns (Account|error);
};

// Configuration
documentation {Object for Twilio configuration.
    F{{clientConfig}} Reference to HTTP client configuration
}
public type TwilioConfiguration {
    http:ClientEndpointConfig clientConfig;
};

//Record to represent type
documentation {Record to represent Account
    F{{sid}} Unique identifier of the account
    F{{name}} The name of the account
    F{{status}} The status of the account (active, suspended, closed)
    F{{^"type"}} The type of this account (Trial, Full)
    F{{createdDate}} The date that this account was created
    F{{updatedDate}} The date that this account was last updated
}
public type Account {
    string sid;
    string name;
    string status;
    string ^"type";  //As type is a keyword it is escaped
    string createdDate;
    string updatedDate;
};


// Constants
@final string BASE_URL = "https://api.twilio.com/2010-04-01";
@final string ACCOUNTS_API = "/Accounts/";
@final string RESPONSE_TYPE_JSON = ".json";
@final string EMPTY_STRING = "";

// =========== Implementation of the Endpoint
public function Client::init (TwilioConfiguration twilioConfig) {
    twilioConfig.clientConfig.targets = [{url:BASE_URL}];
    var usernameOrEmpty = twilioConfig.clientConfig.auth.username;
    string username;
    string password;
    match usernameOrEmpty {
        string usernameString => username = usernameString;
        () => {
            error err;
            err.message = "Username cannot be empty";
            throw err;
              }
    }
    var passwordOrEmpty = twilioConfig.clientConfig.auth.password;
    match passwordOrEmpty {
        string passwordString => password = passwordString;
        () => {
            error err;
            err.message = "Password cannot be empty";
            throw err;
        }
    }

//    string password = twilioConfig.clientConfig.auth.password but {() => EMPTY_STRING}; //TODO

    http:AuthConfig authConfig = {scheme:"basic", username:username , password:password};
    self.twilioConnector.accountSid = username;
    twilioConfig.clientConfig.auth = authConfig;
    self.twilioConnector.basicClient.init(twilioConfig.clientConfig);
}

public function Client::getClient () returns TwilioConnector {
    return self.twilioConnector;
}
// =========== End of implementation of the Endpoint


// =========== Implementation for Connector
public function TwilioConnector::getAccountDetails() returns (Account|error) {

    endpoint http:Client httpClient = self.basicClient;
    http:Request request = new();

    string requestPath = ACCOUNTS_API + self.accountSid + RESPONSE_TYPE_JSON;
    var response = httpClient -> get(requestPath, request);
    var jsonResponse = parseResponseToJson(response);
    match jsonResponse {
        json jsonPayload => { return mapJsonToAccount(jsonPayload); }
        error err => return err;
    }
}
// =========== End of implementation for Connector



function parseResponseToJson(http:Response|http:HttpConnectorError response) returns (json|error) {
    json result = {};
    match response {
        http:Response httpResponse => {
            var jsonPayload = httpResponse.getJsonPayload();
            match jsonPayload {
                json payload => return payload;
                http:PayloadError payloadError => return payloadError;
            }
        }
        http:HttpConnectorError httpError => return httpError;
    }
}

function mapJsonToAccount(json jsonPayload) returns Account {
    Account account = {};
    account.sid = jsonPayload.sid.toString() but { () => EMPTY_STRING };
    account.name = jsonPayload.friendly_name.toString() but { () => EMPTY_STRING };
    account.status = jsonPayload.status.toString() but { () => EMPTY_STRING };
    account.^"type" = jsonPayload.^"type".toString() but { () => EMPTY_STRING };
    account.createdDate = jsonPayload.date_created.toString() but { () => EMPTY_STRING };
    account.updatedDate = jsonPayload.date_updated.toString() but { () => EMPTY_STRING };
    return account;
}

function main(string[] args) {
    endpoint Client twilioClient {
        clientConfig:{
            auth:{
                scheme:"basic",
                username: "",
                password: ""
            }
        }
    };

    Account account = check twilioClient->getAccountDetails();
    io:println(account);
}
