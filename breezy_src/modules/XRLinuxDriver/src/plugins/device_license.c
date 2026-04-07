#include "plugins/device_license.h"
#include "plugins.h"

void device_license_start_func() {
}

void device_license_handle_control_flag_line_func(char* key, char* value) {
}

void device_license_handle_device_connect_func() {
}

const plugin_type device_license_plugin = {
    .id = "device_license",
    .start = device_license_start_func,
    .handle_control_flag_line = device_license_handle_control_flag_line_func,
    .handle_device_connect = device_license_handle_device_connect_func
};

