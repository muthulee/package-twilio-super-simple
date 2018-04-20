
package ballerina.websub;

import ballerina/http;

//Listener object
public type EchoListener object {

    public {
        EchoListenerEndpointConfiguration config;
    }

    private {
        http:Listener serviceEndpoint;
    }

    public new () {
        self.serviceEndpoint = new;
    }

    public function init(EchoListenerEndpointConfiguration config);

    public function register(typedesc serviceType);

    public function start();

    public function getClient() returns (http:Connection);

    public function stop();

//    public function sendSubscriptionRequest();
};



// ================ Impl

public type EchoListenerEndpointConfiguration {
    string host;
    int port;
};

public function EchoListener::init(EchoListenerEndpointConfiguration config) {
    self.config = config;
    http:ServiceEndpointConfiguration serviceConfig = { host:config.host,
                                                             port:config.port};
    self.serviceEndpoint.init(serviceConfig);
}

public function EchoListener::register(typedesc serviceType) {
    self.serviceEndpoint.register(serviceType);
}

public function EchoListener::start() {
    self.serviceEndpoint.start();
}

public function EchoListener::getClient() returns http:Connection {
    return self.serviceEndpoint.getClient();
}

public function EchoListener::stop () {
    self.serviceEndpoint.stop();
}



public type Service object {

    public function getEndpoint () returns (EchoListener) {
        EchoListener ep = new;
        return ep;
    }

};


endpoint EchoListener echoEP {
    port:9090,
    host:"localhost"
};

@http:ServiceConfig {basePath:"/service"}
service<Service> echox bind echoEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/echo"
    }
    doEcho (endpoint conn, http:Request req) {
        http:Response res = new;
        _ = conn -> respond(res);
    }

}



