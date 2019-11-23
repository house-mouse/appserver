#include "logger.hpp"
#include <unistd.h>
#include "cputime.hpp"

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

LogMessage::LogMessage(const char *_filename,
                       const char *_function,
                       int _line_no,
                       int _log_level):filename(_filename), function(_function), line_no(_line_no), log_level(_log_level) {}


void real_log_msg(const char *file, const char *func, int line, int log_level, const char *message) {

    thread_local void *write_ptr = 0; // each thread has a pointer to the lockless queue...
    if (!write_ptr) {
        // This is the first time this thread has started logging.  We have to setup structures
        // for logging and register them, so this is the first only code path where we need to
        // do some locking.
        
    }

    
    LogMessage log(file, func, line, log_level);
    gettime(log.when);
    
}
// We want a thread-safe logger..



