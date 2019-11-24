#include "webserver_staticfile_handler.hpp"

WebServerStaticFileHandler::WebServerStaticFileHandler(H2O_Webserver &server,
                                                       const char *path,
                                                       const char *_content_type,
                                                       const unsigned char *_data,
                                                       size_t _len):WebServerHandler(server, path) {

        
        
        content_type      = _content_type;
        content_type_size = strlen(_content_type);

        body              = (const char *)_data;
        body_size         = _len;
}

WebServerStaticFileHandler::~WebServerStaticFileHandler() {
}

int WebServerStaticFileHandler::on_request(h2o_req_t *req) {
    
    if (!h2o_memis(req->method.base, req->method.len, H2O_STRLIT("GET")))
        return -1;

    req->res.status = 200;
    req->res.reason = "OK";
    h2o_add_header(&req->pool, &req->res.headers, H2O_TOKEN_CONTENT_TYPE, NULL, content_type, content_type_size);
    h2o_send_inline(req, body, body_size);
    
    return 0;
}
