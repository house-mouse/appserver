#ifndef __LOGGER_HPP__
#define __LOGGER_HPP__

#include <sstream>

// Super simple logger for doing things at the moment...

#define LOG_TRACE 1
#define LOG_DEBUG 2
#define LOG_INFO  3
#define LOG_WARN  4
#define LOG_ERROR 5
#define LOG_FATAL 6

#define log_msg(log_level, msg) real_log_msg(__LINE__, __FILE__, __PRETTY_FUNCTION__, log_level, msg)

//#define log_trace(msg) log_messsage(LOG_TRACE, msg)
#define log_trace(msg)
#define log_debug(msg) log_messsage(LOG_DEBUG, msg)
#define log_info(msg)  log_messsage(LOG_INFO,  msg)
#define log_warn(msg)  log_messsage(LOG_WARN,  msg)
#define log_error(msg) log_messsage(LOG_ERROR, msg)
#define log_fatal(msg) log_messsage(LOG_FATAL, msg)

#define _I(thing) " " #thing " = " << thing

#if 0
#define log_messsage(log_level, msg)

#else
#define log_messsage(log_level, msg) {\
    std::ostringstream __real_s; \
    __real_s << msg; \
    log_msg(log_level, __real_s.str().c_str()); \
}
#endif

void real_log_msg(int line, const char *file, const char *func, int log_level, const char *message);

#endif // __LOGGER_HPP__
