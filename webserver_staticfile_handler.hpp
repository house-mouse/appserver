#ifndef __WEBSERVER_STATICFILE_HANDLER_HPP__
#define __WEBSERVER_STATICFILE_HANDLER_HPP__

#include "h2o.h"
#include "webserver_handler.hpp"

// Wrapper around h2o_handler_t
//
// Provides allocation, deallocation, C++ trampoline etc...

class WebServerStaticFileHandler:public WebServerHandler {
    const char *content_type;
    size_t content_type_size;
    const char *body;
    size_t body_size;
public:
    WebServerStaticFileHandler(H2O_Webserver &server,
                               const char *path,
                               const char *content_type,
                               const unsigned char *data,
                               size_t len);

    virtual ~WebServerStaticFileHandler();
    
    virtual int on_request(h2o_req_t *req);

};

#endif // __WEBSERVER_STATICFILE_HANDLER_HPP__
