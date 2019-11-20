#ifndef __APPSERVER_WEBSOCKET_HPP__
#define __APPSERVER_WEBSOCKET_HPP__
#include <string>
#include <vector>
#include <memory>


#include "h2o.h"
#include "h2o/websocket.h"

int on_websocket_req(h2o_handler_t *self, h2o_req_t *req);

void on_websocket_complete(void *user_data, h2o_socket_t *sock, size_t reqsize);

ssize_t recv_callback(wslay_event_context_ptr ctx, uint8_t *buf, size_t len, int flags, void *_conn);

ssize_t send_callback(wslay_event_context_ptr ctx, const uint8_t *data, size_t len, int flags, void *_conn);

h2o_websocket_conn_t *h2o_upgrade_to_websocket(h2o_req_t *req, const char *client_key, h2o_websocket_msg_callback cb);

int h2o_is_websocket_handshake(h2o_req_t *req, const char **ws_client_key);

void h2o_websocket_close(h2o_websocket_conn_t *conn);

void h2o_websocket_proceed(h2o_websocket_conn_t *conn);




// Derive a class from AppServerWebSocket to implement features using
// the websocket protocol.  Provide a generator that creates your
// implementation to your AppServerWebSocket when you register a path
// handler for your websocket URL.
class AppServerWebSocket;

// Generators will get this record sent to them when asked to create a new
// AppServerWebSocket
struct WebSocketCreationRecord {
    std::string path;   // The path registered with the AppServerWebServer
    void *data;         // data passed along from your registry call
};

struct WebSocketRegistrationRecord;

struct h2o_websocket_handler {
    h2o_handler_t super;
    WebSocketRegistrationRecord *registration_record;
};

typedef AppServerWebSocket *(*WebSocketGenerator)(const WebSocketCreationRecord &, h2o_websocket_conn_t *conn);

class AppServerWebSocket {
    h2o_websocket_conn_t *conn;
public:
    AppServerWebSocket(h2o_websocket_conn_t *conn);
    virtual ~AppServerWebSocket();
    
    // When a websocket message is sent to the AppServer by the
    // client, this function is called with the data.
    virtual void receive_websocket_message(const struct wslay_event_on_msg_recv_arg *arg);
    
    // You can send data to the client using this function.
    virtual void send_websocket_message(uint8_t opcode,
                                        const uint8_t *msg,
                                        size_t size);

    // When you're all done and you want to kick the client off, call this.
    // You should not receive websocket messages after calling close_websocket()
    // and you had best not try to send more messages.
    virtual void close_websocket();
};


class AppServerEchoWebSocket:public AppServerWebSocket {
public:

    AppServerEchoWebSocket(h2o_websocket_conn_t *conn);
    virtual ~AppServerEchoWebSocket();

    virtual void receive_websocket_message(const struct wslay_event_on_msg_recv_arg *arg);
};

AppServerWebSocket *EchoWebSocketGenerator(const WebSocketCreationRecord &creation_record, h2o_websocket_conn_t *conn);

#endif // __APPSERVER_WEBSOCKET_HPP__
