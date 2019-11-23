#ifndef __UV_LOG_CONSUMER_HPP__
#define __UV_LOG_CONSUMER_HPP__

#include "uv.h"
#include "logger.hpp"

class UvLogConsumer:public LogConsumer {
    uv_loop_t &loop;
    uv_timer_t timer;
public:
    UvLogConsumer(uv_loop_t &loop);
    ~UvLogConsumer();
    
    void stop();
    void start(uint64_t timeout, uint64_t repeat);


    static void timer_cb(uv_timer_t* handle);

};

#endif // __UV_LOG_CONSUMER_HPP__
