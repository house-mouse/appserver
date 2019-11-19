#ifndef __APPSERVER_WEBSOCKET_H__
#define __APPSERVER_WEBSOCKET_H__

#include "h2o.h"
#include "h2o/websocket.h"

void on_ws_message(h2o_websocket_conn_t *conn, const struct wslay_event_on_msg_recv_arg *arg);

int on_websocket_req(h2o_handler_t *self, h2o_req_t *req);

void on_websocket_complete(void *user_data, h2o_socket_t *sock, size_t reqsize);

ssize_t recv_callback(wslay_event_context_ptr ctx, uint8_t *buf, size_t len, int flags, void *_conn);

ssize_t send_callback(wslay_event_context_ptr ctx, const uint8_t *data, size_t len, int flags, void *_conn);

static void on_msg_callback(wslay_event_context_ptr ctx, const struct wslay_event_on_msg_recv_arg *arg, void *_conn);

static void free_write_buf(h2o_websocket_conn_t *conn);


static void on_write_complete(h2o_socket_t *sock, const char *err);

static void on_close(h2o_websocket_conn_t *conn);

static void create_accept_key(char *dst, const char *client_key);


static void on_recv(h2o_socket_t *sock, const char *err);

h2o_websocket_conn_t *h2o_upgrade_to_websocket(h2o_req_t *req, const char *client_key, void *data, h2o_websocket_msg_callback cb);

int h2o_is_websocket_handshake(h2o_req_t *req, const char **ws_client_key);

void h2o_websocket_close(h2o_websocket_conn_t *conn);

void h2o_websocket_proceed(h2o_websocket_conn_t *conn);

#endif // __APPSERVER_WEBSOCKET_H__
