
#include "webserver.hpp"

#include <errno.h>
#include <limits.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include "h2o.h"
#include "h2o/http1.h"
#include "h2o/http2.h"

#include "openssl/ssl.h"

#define USE_HTTPS 1

static int chunked_test(h2o_handler_t *self,
                        h2o_req_t *req) {

//    h2o_conn_t *conn = req->conn;
    
    static h2o_generator_t generator = {NULL, NULL};
    
    if (!h2o_memis(req->method.base, req->method.len, H2O_STRLIT("GET")))
        return -1;
    
    h2o_iovec_t body = h2o_strdup(&req->pool, "Hello.  There is a mouse in the house.\n", SIZE_MAX);
    req->res.status = 200;
    req->res.reason = "OK";
    h2o_add_header(&req->pool, &req->res.headers, H2O_TOKEN_CONTENT_TYPE, NULL, H2O_STRLIT("text/plain"));
    h2o_start_response(req, &generator);
    h2o_send(req, &body, 1, H2O_SEND_STATE_FINAL);
    
    return 0;
}

static int reproxy_test(h2o_handler_t *self, h2o_req_t *req) {
    if (!h2o_memis(req->method.base, req->method.len, H2O_STRLIT("GET"))) {
        return -1;
    }
    
    req->res.status = 200;
    req->res.reason = "OK";
    h2o_add_header(&req->pool,
                   &req->res.headers,
                   H2O_TOKEN_X_REPROXY_URL,
                   NULL, H2O_STRLIT("http://www.ietf.org/"));
    h2o_send_inline(req, H2O_STRLIT("you should never see this!\n"));
    
    return 0;
}

static int post_test(h2o_handler_t *self, h2o_req_t *req) {
    if (h2o_memis(req->method.base, req->method.len, H2O_STRLIT("POST")) &&
        h2o_memis(req->path_normalized.base,
                  req->path_normalized.len,
                  H2O_STRLIT("/post-test/"))) {
        static h2o_generator_t generator = {NULL, NULL};
        req->res.status = 200;
        req->res.reason = "OK";
        h2o_add_header(&req->pool, &req->res.headers, H2O_TOKEN_CONTENT_TYPE, NULL, H2O_STRLIT("text/plain; charset=utf-8"));
        h2o_start_response(req, &generator);
        h2o_send(req, &req->entity, 1, H2O_SEND_STATE_FINAL);
        return 0;
    }
    
    return -1;
}



int webserver_demo(H2O_Webserver &server) {
    h2o_access_log_filehandle_t *logfh = h2o_access_log_open_handle("/dev/stdout", NULL, H2O_LOGCONF_ESCAPE_APACHE);
    h2o_pathconf_t *pathconf;
    
    
    pathconf = server.register_handler("/post-test", post_test);
    if (logfh != NULL)
        h2o_access_log_register(pathconf, logfh);
    
    pathconf = server.register_handler("/chunked-test", chunked_test);
    if (logfh != NULL)
        h2o_access_log_register(pathconf, logfh);
    
    pathconf = server.register_handler("/reproxy-test", reproxy_test);
    h2o_reproxy_register(pathconf);
    if (logfh != NULL)
        h2o_access_log_register(pathconf, logfh);
    
    pathconf = server.register_path("/");
    h2o_file_register(pathconf, "examples/doc_root", NULL, NULL, 0);
    if (logfh != NULL)
        h2o_access_log_register(pathconf, logfh);
    
    if (USE_HTTPS &&
        server.setup_ssl("certs/server-crt.pem",
                         "certs/server-key.pem",
                         "DEFAULT:!MD5:!DSS:!DES:!RC4:!RC2:!SEED:!IDEA:!NULL:!ADH:!EXP:!SRP:!PSK") != 0) {
        return -5;
    }
    
    server.accept_ctx.ctx   = &server.ctx;
    server.accept_ctx.hosts = server.config.hosts;
    
    if (server.create_ip4_listener(7890) != 0) {
        fprintf(stderr, "failed to listen to 127.0.0.1:7890:%s\n", strerror(errno));
        return -4;
    }

    return 0;
}
