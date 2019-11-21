/*
 * Copyright (c) 2014 DeNA Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include "h2o.h"
#include "h2o/websocket.h"

#include "appserver_websocket.hpp"
#include "webserver.hpp"

void on_websocket_message(h2o_websocket_conn_t *conn,
                          const struct wslay_event_on_msg_recv_arg *arg) {
    if (arg == NULL) {
        h2o_websocket_close(conn);
        return;
    }

    AppServerWebSocket *ws((AppServerWebSocket *)conn->data);
    ws->receive_websocket_message(arg);
    /*
    if (!wslay_is_ctrl_frame(arg->opcode)) {
        struct wslay_event_msg msgarg = {arg->opcode, arg->msg, arg->msg_length};
        wslay_event_queue_msg(conn->ws_ctx, &msgarg);
    }
    */
}

int on_websocket_req(h2o_handler_t *self, h2o_req_t *req) {
    const char *client_key;

    fprintf(stderr, "websock_req called...\n");
    if (h2o_is_websocket_handshake(req, &client_key) != 0 || client_key == NULL) {
        return -1;
    }
    h2o_upgrade_to_websocket(req, client_key, on_websocket_message);
    return 0;
}


ssize_t recv_callback(wslay_event_context_ptr ctx, uint8_t *buf, size_t len, int flags, void *_conn) {
    h2o_websocket_conn_t *conn = (h2o_websocket_conn_t *)_conn;

    /* return WOULDBLOCK if no data */
    if (conn->sock->input->size == 0) {
        wslay_event_set_error(conn->ws_ctx, WSLAY_ERR_WOULDBLOCK);
        return -1;
    }

    if (conn->sock->input->size < len)
        len = conn->sock->input->size;
    memcpy(buf, conn->sock->input->bytes, len);
    h2o_buffer_consume(&conn->sock->input, len);
    return len;
}


ssize_t send_callback(wslay_event_context_ptr ctx, const uint8_t *data, size_t len, int flags, void *_conn) {
    h2o_websocket_conn_t *conn = (h2o_websocket_conn_t *) _conn;
    h2o_iovec_t *buf;

    /* return WOULDBLOCK if pending or no buffer available */
    if (h2o_socket_is_writing(conn->sock) ||
        conn->_write_buf.cnt == sizeof(conn->_write_buf.bufs) / sizeof(conn->_write_buf.bufs[0])) {
        wslay_event_set_error(conn->ws_ctx, WSLAY_ERR_WOULDBLOCK);
        return -1;
    }

    buf = &conn->_write_buf.bufs[conn->_write_buf.cnt];

    /* copy data */
    buf->base = (char *)h2o_mem_alloc(len);
    buf->len = len;
    memcpy(buf->base, data, len);
    ++conn->_write_buf.cnt;
    return len;
}

static void on_msg_callback(wslay_event_context_ptr ctx,
                            const struct wslay_event_on_msg_recv_arg *arg,
                            void *_conn) {
    h2o_websocket_conn_t *conn = (h2o_websocket_conn_t *)_conn;
    (*conn->cb)(conn, arg);
}

void on_websocket_complete(void *user_data, h2o_socket_t *sock, size_t reqsize) {
    h2o_websocket_conn_t *conn = (h2o_websocket_conn_t *) user_data;

    /* close the connection on error */
    if (sock == NULL) {
        (*conn->cb)(conn, NULL);
        return;
    }

    conn->sock = sock;
    sock->data = conn;
    h2o_buffer_consume(&sock->input, reqsize);
    h2o_websocket_proceed(conn);
}

#define WS_GUID "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
void create_accept_key(char *dst, const char *client_key) {
    uint8_t sha1buf[20], key_src[60];

    memcpy(key_src, client_key, 24);
    memcpy(key_src + 24, WS_GUID, 36);
    SHA1(key_src, sizeof(key_src), sha1buf);
    h2o_base64_encode(dst, sha1buf, sizeof(sha1buf), 0);
    dst[28] = '\0';
}

static void free_write_buf(h2o_websocket_conn_t *conn) {
    size_t i;
    for (i = 0; i < conn->_write_buf.cnt; ++i)
        free(conn->_write_buf.bufs[i].base);
}

static void on_close(h2o_websocket_conn_t *conn) {
    (*conn->cb)(conn, NULL);
}

static void on_write_complete(h2o_socket_t *sock, const char *err) {
    h2o_websocket_conn_t *conn = (h2o_websocket_conn_t *)sock->data;

    if (err != NULL) {
        on_close(conn);
        return;
    }
    assert(conn->_write_buf.cnt > 0);
    free_write_buf(conn);
    conn->_write_buf.cnt = 0;

    h2o_websocket_proceed(conn);
}


static void on_recv(h2o_socket_t *sock, const char *err) {
    h2o_websocket_conn_t *conn = (h2o_websocket_conn_t *) sock->data;

    if (err != NULL) {
        on_close(conn);
        return;
    }
    h2o_websocket_proceed(conn);
}

h2o_websocket_conn_t *h2o_upgrade_to_websocket(h2o_req_t *req,
                                               const char *client_key,
                                               h2o_websocket_msg_callback cb) {
   
    h2o_websocket_handler *handler = (h2o_websocket_handler *)(req->handler);
    WebSocketRegistrationRecord *registration = handler->registration_record;
   
    
    
    h2o_websocket_conn_t *conn = (h2o_websocket_conn_t *)h2o_mem_alloc(sizeof(*conn));
    char accept_key[29];

    /* only for http1 connection */
    assert(req->version < 0x200);

    /* setup the context */
    memset(conn, 0, sizeof(*conn));
    // conn->sock = sock; set by on_complete
    conn->ws_callbacks.recv_callback = recv_callback;
    conn->ws_callbacks.send_callback = send_callback;
    conn->ws_callbacks.on_msg_recv_callback = on_msg_callback;
    conn->cb = cb;
    
    AppServerWebSocket *ws( registration->generator(registration->creation_record, conn));
    conn->data = ws;

    wslay_event_context_server_init(&conn->ws_ctx, &conn->ws_callbacks, conn);

    /* build response */
    create_accept_key(accept_key, client_key);
    req->res.status = 101;
    req->res.reason = "Switching Protocols";
    h2o_add_header(&req->pool, &req->res.headers, H2O_TOKEN_UPGRADE, NULL, H2O_STRLIT("websocket"));
    h2o_add_header_by_str(&req->pool, &req->res.headers, H2O_STRLIT("sec-websocket-accept"), 0, NULL, accept_key,
                          strlen(accept_key));

    /* send */
    h2o_http1_upgrade(req, NULL, 0, on_websocket_complete, conn);
    
    
    return conn;
}

int h2o_is_websocket_handshake(h2o_req_t *req, const char **ws_client_key) {
    ssize_t key_header_index;

    *ws_client_key = NULL;

    /* method */
    if (h2o_memis(req->input.method.base, req->input.method.len, H2O_STRLIT("GET"))) {
        /* ok */
    } else {
        return 0;
    }

    /* upgrade header */
    if (req->upgrade.base != NULL && h2o_lcstris(req->upgrade.base, req->upgrade.len, H2O_STRLIT("websocket"))) {
        /* ok */
    } else {
        return 0;
    }
    /* sec-websocket-key header */
    if ((key_header_index = h2o_find_header_by_str(&req->headers, H2O_STRLIT("sec-websocket-key"), -1)) != -1) {
        if (req->headers.entries[key_header_index].value.len != 24) {
            return -1;
        }
    } else {
        return 0;
    }

    *ws_client_key = req->headers.entries[key_header_index].value.base;
    return 0;
}

void h2o_websocket_close(h2o_websocket_conn_t *conn) {
    if (conn->sock != NULL)
        h2o_socket_close(conn->sock);
    free_write_buf(conn);
    wslay_event_context_free(conn->ws_ctx);
    free(conn);
}

void h2o_websocket_proceed(h2o_websocket_conn_t *conn) {
    int handled;

    /* run the loop until getting to a point where no more progress can be achieved */
    do {
        handled = 0;
        if (!h2o_socket_is_writing(conn->sock) && wslay_event_want_write(conn->ws_ctx)) {
            if (wslay_event_send(conn->ws_ctx) != 0) {
                goto Close;
            }
            /* avoid infinite loop when user want send more bufers count than ours in on_msg_callback() */
            if (conn->_write_buf.cnt < sizeof(conn->_write_buf.bufs) / sizeof(conn->_write_buf.bufs[0])) {
                handled = 1;
            }
        }
        if (conn->sock->input->size != 0 && wslay_event_want_read(conn->ws_ctx)) {
            if (wslay_event_recv(conn->ws_ctx) != 0) {
                goto Close;
            }
            handled = 1;
        }
    } while (handled);

    if (!h2o_socket_is_writing(conn->sock) && conn->_write_buf.cnt > 0) {
        /* write */
        h2o_socket_write(conn->sock, conn->_write_buf.bufs, conn->_write_buf.cnt, on_write_complete);
    }

    if (wslay_event_want_read(conn->ws_ctx)) {
        h2o_socket_read_start(conn->sock, on_recv);
    } else if (h2o_socket_is_writing(conn->sock) || wslay_event_want_write(conn->ws_ctx)) {
        h2o_socket_read_stop(conn->sock);
    } else {
        /* nothing is going on... close the socket */
        goto Close;
    }

    return;

Close:
    on_close(conn);
}

AppServerWebSocket::AppServerWebSocket(h2o_websocket_conn_t *_conn):conn(_conn) {
    
}


AppServerWebSocket::~AppServerWebSocket() {
    
}

void AppServerWebSocket::receive_websocket_message(const struct wslay_event_on_msg_recv_arg *arg) {
    
}
    
void AppServerWebSocket::send_websocket_message(uint8_t opcode,                         const uint8_t *msg, size_t msg_length) {

    struct wslay_event_msg msgarg = {opcode, (const uint8_t *)msg, msg_length};
    wslay_event_queue_msg(conn->ws_ctx, &msgarg);
    h2o_websocket_proceed(conn); // hmm... yuck?
}

void AppServerWebSocket::close_websocket() {
    h2o_websocket_close(conn);
}



AppServerEchoWebSocket::AppServerEchoWebSocket(h2o_websocket_conn_t *conn):AppServerWebSocket(conn) {}

AppServerEchoWebSocket::~AppServerEchoWebSocket() {}

void AppServerEchoWebSocket::receive_websocket_message(const struct wslay_event_on_msg_recv_arg *arg) {
    fprintf(stderr, "Opcode: %d msg:%s length: %ld\n", arg->opcode, arg->msg, arg->msg_length);
    send_websocket_message(arg->opcode,
                           arg->msg,
                           arg->msg_length);
};


AppServerWebSocket *EchoWebSocketGenerator(const WebSocketCreationRecord &creation_record, h2o_websocket_conn_t *conn) {
    return new AppServerEchoWebSocket(conn);
}
