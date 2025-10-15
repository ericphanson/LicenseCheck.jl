/*
 * C Wrapper for Go licensecheck library
 *
 * This wrapper saves and restores signal handlers around Go library initialization
 * to prevent conflicts between Go's runtime and Julia's signal handling.
 *
 * The issue: Go's runtime installs signal handlers without SA_ONSTACK flag,
 * which conflicts with Julia's expectations and causes crashes.
 *
 * The solution: Save Julia's signal handlers before loading Go, then restore them
 * after Go initializes, allowing both runtimes to coexist.
 */

#include <dlfcn.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

// Go types from the generated header
typedef signed char GoInt8;
typedef unsigned char GoUint8;
typedef short GoInt16;
typedef unsigned short GoUint16;
typedef int GoInt32;
typedef unsigned int GoUint32;
typedef long long GoInt64;
typedef unsigned long long GoUint64;
typedef GoInt64 GoInt;
typedef GoUint64 GoUint;
typedef size_t GoUintptr;
typedef float GoFloat32;
typedef double GoFloat64;

// Return type for License function (from licensecheck_go.h)
struct License_return {
    char** r0;    // licenses array
    GoInt r1;     // count
    GoFloat64 r2; // percent
};

// The actual Go function signature
typedef struct License_return (*LicenseFn)(char*);

static void* go_handle = NULL;
static LicenseFn go_license_fn = NULL;

// Array to store original signal handlers
#define NUM_SIGNALS 32
static struct sigaction original_handlers[NUM_SIGNALS];
static int saved_signals[] = {
    SIGHUP, SIGINT, SIGQUIT, SIGILL, SIGTRAP, SIGABRT, SIGEMT, SIGFPE,
    SIGBUS, SIGSEGV, SIGSYS, SIGPIPE, SIGALRM, SIGTERM, SIGURG, SIGSTOP,
    SIGTSTP, SIGCONT, SIGCHLD, SIGTTIN, SIGTTOU, SIGIO, SIGXCPU, SIGXFSZ,
    SIGVTALRM, SIGPROF, SIGWINCH, SIGINFO, SIGUSR1, SIGUSR2
};
static int num_saved_signals = sizeof(saved_signals) / sizeof(saved_signals[0]);

/*
 * Save all current signal handlers
 */
static int save_signal_handlers(void) {
    for (int i = 0; i < num_saved_signals; i++) {
        int sig = saved_signals[i];
        if (sigaction(sig, NULL, &original_handlers[i]) < 0) {
            // Some signals may not be valid on this system, continue
            continue;
        }
    }
    return 0;
}

/*
 * Restore all saved signal handlers
 */
static int restore_signal_handlers(void) {
    for (int i = 0; i < num_saved_signals; i++) {
        int sig = saved_signals[i];
        // Only restore if we successfully saved it
        if (original_handlers[i].sa_handler != NULL ||
            original_handlers[i].sa_sigaction != NULL) {
            sigaction(sig, &original_handlers[i], NULL);
        }
    }
    return 0;
}

/*
 * Initialize the wrapper and load the Go library
 * This should be called once before any License calls
 */
int wrapper_init(const char* lib_path) {
    if (go_handle != NULL) {
        // Already initialized
        return 0;
    }

    // Save Julia's signal handlers
    save_signal_handlers();

    // Load the Go shared library
    go_handle = dlopen(lib_path, RTLD_NOW | RTLD_LOCAL);
    if (!go_handle) {
        fprintf(stderr, "Failed to load Go library: %s\n", dlerror());
        return -1;
    }

    // Small delay to let Go runtime initialize
    // This ensures Go's signal handlers are installed
    struct timespec ts = {0, 10000000}; // 10ms
    nanosleep(&ts, NULL);

    // Restore Julia's signal handlers, overwriting Go's handlers
    restore_signal_handlers();

    // Get the License function pointer
    go_license_fn = (LicenseFn)dlsym(go_handle, "License");
    if (!go_license_fn) {
        fprintf(stderr, "Failed to find License symbol: %s\n", dlerror());
        dlclose(go_handle);
        go_handle = NULL;
        return -1;
    }

    return 0;
}

/*
 * Wrapper for the Go License function
 * This is what Julia will actually call
 * Returns the same struct as the Go function
 */
struct License_return License(char* text) {
    struct License_return result = {NULL, 0, 0.0};

    if (!go_license_fn) {
        fprintf(stderr, "Error: wrapper not initialized. Call wrapper_init first.\n");
        return result;
    }

    // Call the actual Go function
    result = go_license_fn(text);
    return result;
}

/*
 * Cleanup function (optional)
 */
void wrapper_cleanup(void) {
    if (go_handle) {
        dlclose(go_handle);
        go_handle = NULL;
        go_license_fn = NULL;
    }
}
