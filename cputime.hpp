#ifndef __CPUTIME_HPP__
#define __CPUTIME_HPP__

#include <time.h>
#include <sys/time.h>

void gettime(struct timespec &ts);

float diff_time(struct timespec &start, struct timespec &end);

class SecondTimer {
public:
    struct timespec start;
    
    SecondTimer();
    ~SecondTimer();

    void reset();
    float elapsed();
};


#endif //__CPUTIME_HPP__
