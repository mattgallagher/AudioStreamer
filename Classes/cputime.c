//
//  cputime.c
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/24/13.
//
//

#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach_init.h>
#include <mach/mach_host.h>
#include <mach/mach_port.h>
#include <mach/mach_traps.h>
#include <mach/task_info.h>
#include <mach/thread_info.h>
#include <mach/thread_act.h>
#include <mach/vm_region.h>
#include <mach/vm_map.h>
#include <mach/task.h>

#include "cputime.h"

int get_cpu_time(CPUTime *rpd, boolean_t thread_only)
{
    task_t task;
    kern_return_t error;
    mach_msg_type_number_t count;
    thread_array_t thread_table;
    thread_basic_info_t thi;
    thread_basic_info_data_t thi_data;
    unsigned table_size;
    struct task_basic_info ti;
    
    if (thread_only) {
        // just get time of this thread
        count = THREAD_BASIC_INFO_COUNT;
        thi = &thi_data;
        error = thread_info(mach_thread_self(), THREAD_BASIC_INFO, (thread_info_t)thi, &count);
        rpd->utime = thi->user_time.seconds + thi->user_time.microseconds * 1e-6;
        rpd->stime = thi->system_time.seconds + thi->system_time.microseconds * 1e-6;
        return 0;
    }
    
    
    // get total time of the current process
    
    task = mach_task_self();
    count = TASK_BASIC_INFO_COUNT;
    error = task_info(task, TASK_BASIC_INFO, (task_info_t)&ti, &count);
//    assert(error == KERN_SUCCESS);
    { /* calculate CPU times, adapted from top/libtop.c */
        unsigned i;
        // the following times are for threads which have already terminated and gone away
        rpd->utime = ti.user_time.seconds + ti.user_time.microseconds * 1e-6;
        rpd->stime = ti.system_time.seconds + ti.system_time.microseconds * 1e-6;
        error = task_threads(task, &thread_table, &table_size);
//        assert(error == KERN_SUCCESS);
        thi = &thi_data;
        // for each active thread, add up thread time
        for (i = 0; i != table_size; ++i) {
            count = THREAD_BASIC_INFO_COUNT;
            error = thread_info(thread_table[i], THREAD_BASIC_INFO, (thread_info_t)thi, &count);
//            assert(error == KERN_SUCCESS);
            if ((thi->flags & TH_FLAGS_IDLE) == 0) {
                rpd->utime += thi->user_time.seconds + thi->user_time.microseconds * 1e-6;
                rpd->stime += thi->system_time.seconds + thi->system_time.microseconds * 1e-6;
            }
            error = mach_port_deallocate(mach_task_self(), thread_table[i]);
//            assert(error == KERN_SUCCESS);
        }
        error = vm_deallocate(mach_task_self(), (vm_offset_t)thread_table, table_size * sizeof(thread_array_t));
//        assert(error == KERN_SUCCESS);
    }
    if (task != mach_task_self()) {
        mach_port_deallocate(mach_task_self(), task);
//        assert(error == KERN_SUCCESS);
    }
    return 0;
}
