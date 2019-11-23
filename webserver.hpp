#ifndef __H2O_WEBSERVER_HPP__
#define __H2O_WEBSERVER_HPP__
// A C++ class for handling the H2O webserver

#include "h2o.h"
#include "h2o/memcached.h"

#include <stdint.h>
#include "appserver_websocket.hpp"

class H2O_Webserver;

// Static File handler

struct st_h2o_static_file_handler_t {
    h2o_handler_t super;
    const char *content_type;
    size_t content_type_size;
    const char *body;
    size_t body_size;
};
typedef struct st_h2o_static_file_handler_t h2o_static_file_handler_t;

struct ListenerRecord {
    H2O_Webserver *webserver;
    uv_tcp_t listener;
};

struct WebSocketRegistrationRecord {
    WebSocketCreationRecord creation_record;
    WebSocketGenerator      generator;
    h2o_pathconf_t          *path_conf;
};


// Webserver instance

class H2O_Webserver {
private:
    uv_tcp_t *new_connection_record();
    void release_connection_record(uv_tcp_t *record);
    static void close_connection(uv_handle_t* handle);
    
    ListenerRecord *new_listener_record();
    void release_listener_record(ListenerRecord *record);
    static void close_listener(uv_handle_t* handle);
    
    static void on_accept_trampoline(uv_stream_t *listener, int status);
    
    static h2o_multithread_receiver_t libmemcached_receiver;

    std::vector<std::shared_ptr<WebSocketRegistrationRecord> > websocket_registrations;
public:
    h2o_globalconf_t config;
    h2o_hostconf_t *hostconf;
    h2o_context_t ctx;

    h2o_accept_ctx_t accept_ctx;
    
    h2o_pathconf_t *register_path(const char *path,
                                  int flags=0);
    h2o_pathconf_t *register_handler(const char *path,
                                     int (*on_req)(h2o_handler_t *, h2o_req_t *));
    h2o_pathconf_t *register_static_file_handler(const char *path,
                                                 const char *mime_type,
                                                 const unsigned char *data,
                                                 size_t len);
    h2o_pathconf_t *register_websocket(const char *path);
    h2o_pathconf_t *register_websocket(const std::string path,
                                       WebSocketGenerator generator,
                                       void *data);

    void on_accept(uv_stream_t *listener, int status);

    int create_listener(struct sockaddr_in &addr);
    int create_ip4_listener(uint16_t port);
    int create_ip4_listener(const char *ip, uint16_t port);

    int setup_ssl(const char *cert_file,
                  const char *key_file,
                  const char *ciphers);
    
    H2O_Webserver(uv_loop_t &loop);
    ~H2O_Webserver();

};

#endif // __H2O_WEBSERVER_HPP__
