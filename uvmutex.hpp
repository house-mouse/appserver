#ifndef __UVMUTEX_HPP__
#define __UVMUTEX_HPP__

#include "uv.h"

class UvMutex {
    uv_mutex_t mutex;
public:
    UvMutex();
    ~UvMutex();

    void lock();
    void unlock();
};

class ScopedMutexLock {
    UvMutex &mutex;
public:
    ScopedMutexLock(UvMutex &mutex);
    ~ScopedMutexLock();
};

#endif // __UVMUTEX_HPP__
