#ifndef __LOGGER_HPP__
#define __LOGGER_HPP__

#include <sstream>
#include <vector>

#include "readerwriterqueue.h"
#include <memory>

using namespace moodycamel;

#define LOG_TRACE 1
#define LOG_DEBUG 2
#define LOG_INFO  3
#define LOG_WARN  4
#define LOG_ERROR 5
#define LOG_FATAL 6

#define log_msg(log_level, msg) real_log_msg(__FILE__, __PRETTY_FUNCTION__, __LINE__, log_level, msg)

//#define log_trace(msg) log_messsage(LOG_TRACE, msg)
#define log_trace(msg)
#define log_debug(msg) log_messsage(LOG_DEBUG, msg)
#define log_info(msg)  log_messsage(LOG_INFO,  msg)
#define log_warn(msg)  log_messsage(LOG_WARN,  msg)
#define log_error(msg) log_messsage(LOG_ERROR, msg)
#define log_fatal(msg) log_messsage(LOG_FATAL, msg)

// This convenience macro allows for logging of "things" and
// including the thing name
#define _I(thing) (LogItem(#thing) << thing)

#define log_messsage(log_level, msg) {\
    LogMessage __real_s(__FILE__, __PRETTY_FUNCTION__, __LINE__, log_level); \
    __real_s << msg; \
    real_log_msg(__real_s); \
}

// The LogItem structure allows us to use operator overloading similar
// to the way ostreams work to log data while retaining context for latter
// sorting and automated signature detection.  Every item you would like
// to log should have an << overloaded function to convert it to a LogItem.

struct LogItem {
    const char *name;   // expected to always be a static with infinite lifetime
    std::string data;
    LogItem(const char *_name=""):name(_name) {}
};
std::ostream &operator <<(std::ostream &, LogItem &);

struct LogMessage {
    // These few items are "automatic" because they are expected to be
    // highly re-used static constants (pointers) provided by the compiler, so no
    // need to be copying all the time...
    const char *filename;   // __FILE__
    const char *function;   // __PRETTY_FUNCTION__
    int line_no;            // __LINE__
    //
    int log_level;          // This could also be done with different queues
    struct timespec when;   // when this message hit the logger
    
    std::vector<LogItem> items;
    LogMessage() {}
    LogMessage(const LogMessage &orig);

    LogMessage(const char *filename,
               const char *function,
               int line_no,
               int log_level);
    void set(const char *filename,
             const char *function,
             int line_no,
             int log_level);
};

std::ostream &operator <<(std::ostream &, LogMessage &);

LogMessage &operator<<(LogMessage &, const char *);
LogMessage &operator<<(LogMessage &, int);

// The thread-specific log structures...
struct ThreadLogger {
    bool close; // true if the thread is gone and we're done...
    BlockingReaderWriterQueue<std::shared_ptr<LogMessage> > messages;
    ThreadLogger();
    ~ThreadLogger();
};

// The logging macros are expanded to include the __FILE__, __PRETTY_FUNCTION__,
// and __LINE__
void real_log_msg(LogMessage &item);

struct LogConsumer {
    LogConsumer();
    ~LogConsumer();
    void consume();
    virtual void ordered_log(std::shared_ptr<LogMessage>, ThreadLogger *);
};

#endif // __LOGGER_HPP__
