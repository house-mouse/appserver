#include "uv.h"

#include "webserver.hpp"


#include <curl/curl.h>

int main(int argc, char *argv[]) {
    // Turn off sigpipe
    signal(SIGPIPE, SIG_IGN);
    
    // Libuv is our event handler, and everything
    // should be able to use it:
    uv_loop_t loop;
    
    int rv=uv_loop_init(&loop);
    if (rv) {
        fprintf(stderr, "Unable to initialize uv loop!");
    } else {
        H2O_Webserver server(loop);
        
        rv = webserver_demo(server);
        if (rv) {
            fprintf(stderr, "rv_demo gave error %d", rv);

        } else {
            uv_run(&loop, UV_RUN_DEFAULT);
        }
    }
    uv_loop_close(&loop);
    return rv;
}


