#include "cputime.hpp"

// It's hard to believe, but they still don't seem to have a cross platform
// time implementation!?!
//
// see https://stackoverflow.com/questions/5167269/clock-gettime-alternative-in-mac-os-x

#ifdef __MACH__
#include <mach/clock.h>
#include <mach/mach.h>
#endif

void gettime(struct timespec &ts) {

#ifdef __MACH__ // OS X does not have clock_gettime, use clock_get_time
clock_serv_t cclock;
mach_timespec_t mts;
host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
clock_get_time(cclock, &mts);
mach_port_deallocate(mach_task_self(), cclock);
ts.tv_sec = mts.tv_sec;
ts.tv_nsec = mts.tv_nsec;

#else
clock_gettime(CLOCK_REALTIME, &ts);
#endif
}


float diff_time(struct timespec &start, struct timespec &end) {
    
    return(end.tv_sec - start.tv_sec) +
    (end.tv_nsec - start.tv_nsec)/1000000000.0;
}

    
SecondTimer::SecondTimer() {
    reset();
}

SecondTimer::~SecondTimer() {
};

void SecondTimer::reset() {
    gettime(start);
}


float SecondTimer::elapsed() {
    struct timespec now;
    gettime(now);
    
    return diff_time(start, now);
}