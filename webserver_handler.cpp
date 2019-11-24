#include "webserver_handler.hpp"

WebServerHandler::WebServerHandler(h2o_pathconf_t *pathconf) {
    
    handler = (internal_webserver_handler_t *)h2o_create_handler(pathconf, sizeof(*handler));
    handler->self = this;
    handler->handler.on_req = on_req_trampoline;
}


WebServerHandler::WebServerHandler(H2O_Webserver &server,
                                   const char *path) {    
    handler = (internal_webserver_handler_t *)h2o_create_handler(server.register_path(path), sizeof(*handler));
    handler->self = this;
    handler->handler.on_req = on_req_trampoline;
}

WebServerHandler::~WebServerHandler() {
    
    // TODO.. how do we free internal_webserver_handler_t ?
}

int WebServerHandler::on_req_trampoline(h2o_handler_t *handler, h2o_req_t *req) {
    internal_webserver_handler_t *h=(internal_webserver_handler_t *)handler;
    
    return h->self->on_request(req);
}
