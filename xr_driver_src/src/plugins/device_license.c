#include "curl.h"
#include "files.h"
#include "logging.h"
#include "memory.h"
#include "plugins/device_license.h"
#include "runtime_context.h"
#include "strings.h"
#include "system.h"

#include <curl/curl.h>
#include <json-c/json.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <pthread.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>

#define SECONDS_PER_DAY 86400

const char* DEVICE_LICENSE_FILE_NAME = "%.8s_license.json";
const char* DEVICE_LICENSE_TEMP_FILE_NAME = "license.tmp.json";

// Declare mutexes early so they can be used in helper functions
pthread_mutex_t refresh_license_lock = PTHREAD_MUTEX_INITIALIZER;

// Helper function to check if all requested features are present in the license
bool all_features_in_license(char** requested_features, int requested_count) {
    return true;
}

void refresh_license(bool force, char** requested_features, int requested_features_count) {
    pthread_mutex_lock(&refresh_license_lock);
    
    // Free existing features
    free_string_array(state()->granted_features, state()->granted_features_count);
    free_string_array(state()->license_features, state()->license_features_count);

    // Hardcode granted features
    state()->granted_features_count = 4;
    state()->granted_features = malloc(sizeof(char*) * 4);
    state()->granted_features[0] = strdup("productivity_basic");
    state()->granted_features[1] = strdup("productivity_pro");
    state()->granted_features[2] = strdup("smooth_follow");
    state()->granted_features[3] = strdup("sbs");

    // Also set them as available license features
    state()->license_features_count = 4;
    state()->license_features = malloc(sizeof(char*) * 4);
    state()->license_features[0] = strdup("productivity_basic");
    state()->license_features[1] = strdup("productivity_pro");
    state()->license_features[2] = strdup("smooth_follow");
    state()->license_features[3] = strdup("sbs");

    pthread_mutex_unlock(&refresh_license_lock);
    log_message("All features manually granted (license check bypassed).\n");
}

void device_license_start_func() {
    refresh_license(false, NULL, 0);
}

void device_license_handle_control_flag_line_func(char* key, char* value) {
    if (strcmp(key, "refresh_device_license") == 0) {
        if (strcmp(value, "true") == 0) refresh_license(true, NULL, 0);
    } else if (strcmp(key, "request_features") == 0) {
        // No need to refresh since we hardcoded them
    }
}

void device_license_handle_device_connect_func() {
    refresh_license(false, NULL, 0);
}

const plugin_type device_license_plugin = {
    .id = "device_license",
    .start = device_license_start_func,
    .handle_control_flag_line = device_license_handle_control_flag_line_func,
    .handle_device_connect = device_license_handle_device_connect_func
};
