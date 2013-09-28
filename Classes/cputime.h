//
//  cputime.h
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/24/13.
//
//

#ifndef iPhoneStreamingPlayer_cputime_h
#define iPhoneStreamingPlayer_cputime_h

typedef struct {
    double utime, stime;
} CPUTime;

#ifdef __cplusplus
extern "C" {
#endif
    
    int get_cpu_time(CPUTime *rpd, boolean_t thread_only);

#ifdef __cplusplus
}
#endif

#endif
