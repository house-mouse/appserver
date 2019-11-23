#include "uvmutex.hpp"


UvMutex::UvMutex() {
    //int rv =
    uv_mutex_init(&mutex);
    // TODO: handle errors
}

UvMutex::~UvMutex() {
    uv_mutex_destroy(&mutex);
}

void UvMutex::lock() {
    uv_mutex_lock(&mutex);
}

void UvMutex::unlock() {
    uv_mutex_unlock(&mutex);
}


ScopedMutexLock::ScopedMutexLock(UvMutex &_mutex):mutex(_mutex) {
    mutex.lock();
}

ScopedMutexLock::~ScopedMutexLock() {
    mutex.unlock();
}

