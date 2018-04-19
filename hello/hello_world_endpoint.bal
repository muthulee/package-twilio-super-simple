import ballerina/io;
import ballerina/http;

// Endpoint Contract
public type Client object {

    public {
        HelloWorldConnector helloWorldConnector = new;
    }

    public function init (HelloWorldConfig helloWorldConfig);

    public function getClient () returns HelloWorldConnector;
};


// Connector Contract
public type HelloWorldConnector object {

    public {
        string name;
        http:Client basicClient;
    }

    public function sayHello();
};

//Configuration Object
public type HelloWorldConfig {
    string name;
    http:ClientEndpointConfig clientConfig;
};

// =========== Implementation of the Endpoint

public function Client::init (HelloWorldConfig helloWorldConfig) {
    self.helloWorldConnector.name = helloWorldConfig.name;
    self.helloWorldConnector.basicClient.init(helloWorldConfig.clientConfig);
}

public function Client::getClient () returns HelloWorldConnector {
    return self.helloWorldConnector;
}

// =========== End of implementation of the Endpoint


// =========== Implementation for Connector

public function HelloWorldConnector::sayHello()  {
    endpoint http:Client httpClient = self.basicClient;
    http:Request request = new();
    string requestPath = "http://example.com/";
    var response = httpClient -> get(requestPath, request);
    io:println("Hi " + self.name + ".  Hello world is successful!");
}
// =========== End of implementation for Connector


function main(string[] args) {
    endpoint Client helloWorldClient {
        name: "Gatsby",
        clientConfig:{
            targets: [{url:"http://example.com"}]
        }
    };

    helloWorldClient->sayHello();
}
