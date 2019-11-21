
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
#include "h2o/websocket.h"
#include "appserver_websocket.hpp"

#include "openssl/ssl.h"

#define USE_MEMCACHED 0

H2O_Webserver::H2O_Webserver(uv_loop_t &loop) {
    h2o_config_init(&config);
    hostconf = h2o_config_register_host(&config, h2o_iovec_init(H2O_STRLIT("default")), 65535);
    
    h2o_context_init(&ctx, &loop, &config);
    
    if (USE_MEMCACHED) {
        h2o_multithread_register_receiver(ctx.queue, &libmemcached_receiver, h2o_memcached_receiver);
    }
}

H2O_Webserver::~H2O_Webserver() {
    h2o_context_request_shutdown(&ctx);

    h2o_context_dispose(&ctx);
    
    // TODO: tear everything down...
}

// C -> C++ trampoline...

void H2O_Webserver::on_accept_trampoline(uv_stream_t *listener,
                              int status) {
    ListenerRecord *l = (ListenerRecord *)listener->data;
    l->webserver->on_accept(listener, status);
}

//
// Accept incoming connection
//

void H2O_Webserver::on_accept(uv_stream_t *listener,
                                         int status) {
    h2o_socket_t *sock;
    
    if (status != 0)
        return;
    
    uv_tcp_t *conn = new_connection_record();
    uv_tcp_init(listener->loop, conn);
    
    if (uv_accept(listener, (uv_stream_t *)conn) != 0) {
        uv_close((uv_handle_t *)conn, (uv_close_cb)close_connection);
        return;
    }
    
    sock = h2o_uv_socket_create((uv_handle_t *)conn, (uv_close_cb)close_connection);
    sock->data = this; // todo... see if this is useful...
    
    h2o_accept(&accept_ctx, sock);
}

void H2O_Webserver::close_connection(uv_handle_t* handle) {
    delete handle; // drag...  socket uses data from handle, so
    // we can't use it to trapoline into C++ and do fancy stuff.
}

//
// connection records
//
// One day we could do pooling, and these hooks would allow
// for that...

uv_tcp_t *H2O_Webserver::new_connection_record() {
    // WARNING!  socket uses uv_tcp_t->data, so we can't!
    return (uv_tcp_t *)malloc(sizeof(uv_tcp_t));
//    return new uv_tcp_t();
}

void H2O_Webserver::release_connection_record(uv_tcp_t *record) {
    free(record);
//    delete record;
}

// listener records

ListenerRecord *H2O_Webserver::new_listener_record() {
    ListenerRecord *rv=new ListenerRecord();
    rv->webserver=this;
    rv->listener.data=rv;
    return rv;
}

void H2O_Webserver::release_listener_record(ListenerRecord *record) {
    delete record;
}

void H2O_Webserver::close_listener(uv_handle_t* handle) {
    if (handle->data) {
        ListenerRecord *lr = (ListenerRecord *)handle->data;
        H2O_Webserver *webserver = lr->webserver;
        webserver->release_listener_record(lr);
    }
    // This would be an error?
}


#define USE_HTTPS 1

h2o_pathconf_t *H2O_Webserver::register_path(const char *path,
                                             int flags) {
    return h2o_config_register_path(hostconf, path, flags);
}

h2o_pathconf_t *H2O_Webserver::register_handler(const char *path,
                                                int (*on_req)(h2o_handler_t *, h2o_req_t *)) {
    h2o_pathconf_t *pathconf = register_path(path);
    h2o_handler_t *handler = h2o_create_handler(pathconf, sizeof(*handler));
    handler->on_req = on_req;
    return pathconf;
}


// Static File Handler
//
// Probably could use some C++ magic...

static int static_file_handler(h2o_handler_t *self,
                        h2o_req_t *req) {
    if (!h2o_memis(req->method.base, req->method.len, H2O_STRLIT("GET")))
        return -1;
    
    h2o_static_file_handler_t *handler = (h2o_static_file_handler_t *)self;

    req->res.status = 200;
    req->res.reason = "OK";
    h2o_add_header(&req->pool, &req->res.headers, H2O_TOKEN_CONTENT_TYPE, NULL, handler->content_type, handler->content_type_size);
    h2o_send_inline(req, handler->body, handler->body_size);
    
    return 0;
}


// Serve a static string as a file with the given content type
// content_type and data must live "forever" (be static)

h2o_pathconf_t *H2O_Webserver::register_static_file_handler(const char *path,
                                                            const char *content_type,
                                                            const char *data,
                                                            size_t len) {
    
    h2o_pathconf_t *pathconf = register_path(path);
    h2o_static_file_handler_t *handler = (h2o_static_file_handler_t *)h2o_create_handler(pathconf, sizeof(*handler));
    handler->super.on_req      = static_file_handler;
    
    handler->content_type      = content_type;
    handler->content_type_size = strlen(content_type);

    handler->body              = data;
    handler->body_size         = len;
    
    return pathconf;
}



h2o_pathconf_t *H2O_Webserver::register_websocket(const char *path) {
    assert(0); // let's not use this...
    h2o_pathconf_t *pathconf = register_path(path, 0);
    h2o_create_handler(pathconf, sizeof(h2o_handler_t))->on_req = on_websocket_req;

    return pathconf;
}


h2o_pathconf_t *H2O_Webserver::register_websocket(const std::string path, WebSocketGenerator generator, void *data) {
    fprintf(stderr, "Registered websock path: %s\n", path.c_str());
    std::shared_ptr<WebSocketRegistrationRecord> registration(new WebSocketRegistrationRecord);
    
    registration->generator = generator;
    registration->path_conf = register_path(path.c_str(), 0);
    registration->creation_record.data = data;
    registration->creation_record.path = path;
    websocket_registrations.push_back(registration);
    
    h2o_websocket_handler *handler = (h2o_websocket_handler *)h2o_create_handler(registration->path_conf,
                                                       sizeof(h2o_websocket_handler));
    handler->super.on_req        = on_websocket_req;
    handler->registration_record = registration.get(); // sorta unfortunate...

    return registration->path_conf;
}


int H2O_Webserver::create_listener(struct sockaddr_in &addr) {
    ListenerRecord *listener = new_listener_record();

    int rv;
    
    uv_tcp_init(ctx.loop, &listener->listener);

    if ((rv = uv_tcp_bind(&listener->listener, (struct sockaddr *)&addr, 0)) != 0) {
        fprintf(stderr, "uv_tcp_bind:%s\n", uv_strerror(rv));
    } else if ((rv = uv_listen((uv_stream_t *)&listener->listener, 128, on_accept_trampoline)) != 0) {
        fprintf(stderr, "uv_listen:%s\n", uv_strerror(rv));
    } else {
        return 0;
    }
    
    uv_close((uv_handle_t *)&listener, close_listener);
    return rv;
}

int H2O_Webserver::create_ip4_listener(const char *ip,
                                       uint16_t port) {
    struct sockaddr_in addr;
    uv_ip4_addr(ip, port, &addr);
    return create_listener(addr);
}

int H2O_Webserver::create_ip4_listener(uint16_t port) {
    return create_ip4_listener("127.0.0.1", port);
}


int H2O_Webserver::setup_ssl(const char *cert_file,
                             const char *key_file,
                             const char *ciphers) {

    OPENSSL_init();
    
    SSL_load_error_strings();
    SSL_library_init();
    OpenSSL_add_all_algorithms();

   
    accept_ctx.ssl_ctx = SSL_CTX_new(SSLv23_server_method());
    SSL_CTX_set_options(accept_ctx.ssl_ctx, SSL_OP_NO_SSLv2);
    
    if (USE_MEMCACHED) {
        accept_ctx.libmemcached_receiver = &libmemcached_receiver;
        h2o_accept_setup_memcached_ssl_resumption(h2o_memcached_create_context("127.0.0.1", 11211, 0, 1, "h2o:ssl-resumption:"),
                                                  86400);
        h2o_socket_ssl_async_resumption_setup_ctx(accept_ctx.ssl_ctx);
    }

#ifdef SSL_CTX_set_ecdh_auto
    SSL_CTX_set_ecdh_auto(accept_ctx.ssl_ctx, 1);
#endif
    
    /* load certificate and private key */
    if (SSL_CTX_use_certificate_chain_file(accept_ctx.ssl_ctx, cert_file) != 1) {
        fprintf(stderr, "an error occurred while trying to load server certificate file:%s\n", cert_file);
        return -1;
    }
    if (SSL_CTX_use_PrivateKey_file(accept_ctx.ssl_ctx, key_file, SSL_FILETYPE_PEM) != 1) {
        fprintf(stderr, "an error occurred while trying to load private key file:%s\n", key_file);
        return -2;
    }
    
    if (SSL_CTX_set_cipher_list(accept_ctx.ssl_ctx, ciphers) != 1) {
        fprintf(stderr, "ciphers could not be set: %s\n", ciphers);
        return -3;
    }
    
    /* setup protocol negotiation methods */
#if H2O_USE_NPN
    h2o_ssl_register_npn_protocols(accept_ctx.ssl_ctx, h2o_http2_npn_protocols);
#endif
#if H2O_USE_ALPN
    h2o_ssl_register_alpn_protocols(accept_ctx.ssl_ctx, h2o_http2_alpn_protocols);
#endif
    
    return 0;
}

