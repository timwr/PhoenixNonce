#include <stdbool.h>
#include <unistd.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>

#include "arch.h"
#include "exploit64.h"
#include "nvpatch.h"
#include "set.h"

bool set_generator(const char *gen)
{
    bool ret = false;

    CFStringRef str = CFStringCreateWithCStringNoCopy(NULL, gen, kCFStringEncodingUTF8, kCFAllocatorNull);
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if(!str || !dict)
    {
        LOG("Failed to allocate CF objects");
    }
    else
    {
        CFDictionarySetValue(dict, CFSTR("com.apple.System.boot-nonce"), str);
        CFRelease(str);

        io_service_t nvram = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODTNVRAM"));
        if(!MACH_PORT_VALID(nvram))
        {
            LOG("Failed to get IODTNVRAM service");
        }
        else
        {
            int r = 0;
            if(getuid() != 0) // Skip if we got root already
            {
                r = -1;
                vm_address_t kbase = 0;
                task_t kernel_task = get_kernel_task(&kbase);
                LOG("kernel_task: 0x%x", kernel_task);
                if(MACH_PORT_VALID(kernel_task))
                {
                    r = nvpatch(kernel_task, kbase, "com.apple.System.boot-nonce");
                    if(ret == 0)
                    {

                    }
                }
            }

            if(r == 0)
            {
                kern_return_t kret = IORegistryEntrySetCFProperties(nvram, dict);
                LOG("IORegistryEntrySetCFProperties: %s", mach_error_string(kret));
                if(kret == KERN_SUCCESS)
                {
                    ret = true;
                }
            }
        }

        CFRelease(dict);
    }

    return ret;
}
