#include "uvlogconsumer.hpp"

UvLogConsumer::UvLogConsumer(uv_loop_t &_loop):loop(_loop) {
    int rv=uv_timer_init(&loop, &timer); // TODO: errors?
    
    timer.data=this;
}

UvLogConsumer::~UvLogConsumer() {
    // Make sure we don't get called again...
    stop();
}

void UvLogConsumer::stop() {
    int rv = uv_timer_stop(&timer); // TODO: errors?
}

void UvLogConsumer::start(uint64_t timeout, uint64_t repeat) {
    int rv= uv_timer_start(&timer, timer_cb, timeout, repeat);
}



void UvLogConsumer::timer_cb(uv_timer_t* handle) {
    UvLogConsumer *self = (UvLogConsumer *) handle->data;
    
    self->consume();
}

