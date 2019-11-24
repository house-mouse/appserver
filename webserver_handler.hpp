#ifndef __WEBSERVER_HANDLER_HPP__
#define __WEBSERVER_HANDLER_HPP__

#include "webserver.hpp"

// Wrapper around h2o_handler_t
//
// Provides allocation, deallocation, C++ trampoline etc...

class WebServerHandler {
    typedef struct {
        h2o_handler_t    handler;
        WebServerHandler *self;    
    } internal_webserver_handler_t;
    
    internal_webserver_handler_t *handler;
    
    static int on_req_trampoline(h2o_handler_t *, h2o_req_t *);
    
public:
    WebServerHandler(H2O_Webserver &server, const char *path);
    WebServerHandler(h2o_pathconf_t *conf);
    virtual ~WebServerHandler();
    
    virtual int on_request(h2o_req_t *req) = 0;

};

#endif // __WEBSERVER_HANDLER_HPP__
