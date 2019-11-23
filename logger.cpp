#include "logger.hpp"
#include <unistd.h>
#include "cputime.hpp"
#include "uvmutex.hpp"
#include <list>
#include <iostream>
#include <set>

// The requirements here are straight forward... multithreaded producers
// can log messages at any time.
//
// A single thread is allowed to serialize and dequeue the threaded messages
// in order to write them to a file or stdout or ... whatever...
//
// Each thread gets it's own lockless queue which it can write to.  The single
// consumer thread has acces to read (consume) all of the lockless queues
// and must "sort" from the list of lockless queues.  Sorting is done by
// timestamp, which is assumed to be "fast".  Hopefully it's just a read from
// a global variable somewhere and not a system call.
//
// If you create and delete a lot of threads, this could be the wrong logger
// for you.  It's meant to be used in a worker based environment where the
// worker threads are largely allocate and then left...
//
// thread_local requires c++11

// Global mutex and loggers index...
UvMutex logger_mutex;  // Mutex to protect the logger list:
std::list<ThreadLogger *> loggers;

ThreadLogger::ThreadLogger():close(false) {}

ThreadLogger::~ThreadLogger() {
}

class LogCloser {
    ThreadLogger *logger;
public:
    LogCloser(ThreadLogger *_logger):logger(_logger) {}
    ~LogCloser() {logger->close=true;}
};

// Create and destroy thread-specific logger
ThreadLogger *get_thread_logger() {
    thread_local ThreadLogger *logger;
    thread_local bool initialized(false);
    
    if (!initialized) {
        // Create the new logger, but not as thread_local...
        // We may want to get the data from this structure even if
        // the thread that logged it is deleted.
        
        logger=new ThreadLogger();
        
        // The following class's destructor will set the "close" flag
        // on the logger we just created when the thread is destroyed.
        thread_local LogCloser closer(logger);

        // Get a lock so we can modify structures seen by all threads...
        // We did not need the lock before, as we were only playing
        // with the thread_local structures of our thread
        
        ScopedMutexLock mutex(logger_mutex);
        
        loggers.push_back(logger);

        initialized=true;
        // Send the first log message:
        log_info("New logger for thread with pid " << getpid() << " started");
    }
    
    return logger;
}

LogMessage::LogMessage(const char *_filename,
                       const char *_function,
                       int _line_no,
                       int _log_level):filename(_filename), function(_function), line_no(_line_no), log_level(_log_level) {}

LogMessage::LogMessage(const LogMessage &orig):filename(orig.filename),
                    function(orig.function),
                    line_no(orig.line_no),
                    log_level(orig.log_level),
                    items(orig.items)   // TODO: this is a potentially expensive copy
{}

void LogMessage::set(const char *_filename,
                     const char *_function,
                     int _line_no,
                     int _log_level) {
    filename  = _filename;
    function  = _function;
    line_no   = _line_no;
    log_level = _log_level;
}

void real_log_msg(LogMessage &item) {

    ThreadLogger *logger(get_thread_logger());
    
    gettime(item.when);
    
    // TODO: replace this wiht something way better...
    // like memory pools...
    std::shared_ptr<LogMessage> newmsg(new LogMessage(item));
    
    logger->messages.enqueue(newmsg);
    
#ifdef IMMEDITELY_CERR_LOGS
    std::stringstream o;
    o<< item;
    std::cout << o.str();
#endif
}

LogMessage &operator<<(LogMessage &lm, const char *m) {
    LogItem msg("msg");
    msg.data = m;
    lm.items.push_back(msg);
    
    return lm;
}

LogMessage &operator<<(LogMessage &lm, int m) {
    LogItem msg("msg");
    std::ostringstream s;
    s << m;
    msg.data = s.str();
    lm.items.push_back(msg);
    
    return lm;
}

std::ostream &operator <<(std::ostream &os, LogMessage &lm) {
    
    os << lm.when.tv_sec << "." << lm.when.tv_nsec << ": " << lm.filename << ":" << lm.line_no << " ";
    for (auto &i:lm.items) {
        os << i << " ";
    }
    os << "\n";
return os;
}
    
std::ostream &operator <<(std::ostream &os, LogItem &li) {
    os << li.name << " " << li.data;
    
    return os;
}

// All of the above is to allow a single thread to
// consume the logs...
    
    

LogConsumer::LogConsumer() {}
LogConsumer::~LogConsumer() {}

// Consume and order logs in the thread queues until there are no more...

struct pair_compare {
    bool operator()(const std::pair<std::shared_ptr<LogMessage>, ThreadLogger * > &a,
                    const std::pair<std::shared_ptr<LogMessage>, ThreadLogger * > &b) {
        return (a.first->when < b.first->when);
    }
};

typedef std::pair<std::shared_ptr<LogMessage>, ThreadLogger * > MsgLoggerPair;
void LogConsumer::consume() {
    std::set<MsgLoggerPair> ordered_next;
    
    // We may hold this lock for a long time to process data, but this only
    // restricts new threads from registering and coming online, so it's not
    // a significant problem...
    ScopedMutexLock lock(logger_mutex);
    
    // Grab the first item in each queue and order it in the set:
    std::set<ThreadLogger *> check_loggers;

    for (auto logger:loggers) {
        std::shared_ptr<LogMessage> msg;
    // TODO: use peek instead of try_dequeue so that we aren't required
    // to do something with every log message befor returning...
        bool success = logger->messages.try_dequeue(msg);  // Returns false if the queue was empty
        if (success) {
            ordered_next.insert(MsgLoggerPair(msg, logger));
        } else {
            // Check the empty ones for new messages later
            check_loggers.insert(logger);
        }

    // Peel off the first item from the set and replace it with the next item
    // in the queue that was first...

        while (!ordered_next.empty()) {
            auto first=ordered_next.begin();
            ordered_log(first->first, first->second);
            check_loggers.insert(first->second);
            ordered_next.erase(first);

            for (auto i=check_loggers.begin(); i!=check_loggers.end();) {
                auto &logger=*i;
                i++;
                std::shared_ptr<LogMessage> msg;
                bool success = logger->messages.try_dequeue(msg);  // Returns false if the queue was empty
                if (success) {
                    ordered_next.insert(MsgLoggerPair(msg, logger));
                    check_loggers.erase(logger);
                }
            }
        }
    }
}


void LogConsumer::ordered_log(std::shared_ptr<LogMessage> msg, ThreadLogger *logger) {
    // Default behavior for now is just stderr...
    
    std::stringstream o;
    o << *(msg);
    std::cerr << o.str();
    
}


