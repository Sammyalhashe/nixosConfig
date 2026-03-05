#include "imu_protocol.h"
#include "hid_ids.h"
#include "device_imu.h"
#include "device.h"

#include <hidapi/hidapi.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "crc32.h"
#include "endian_compat.h"
#include <math.h>

#define DEVICE_IMU_MSG_GET_CAL_DATA_LENGTH 0x14
#define DEVICE_IMU_MSG_CAL_DATA_GET_NEXT_SEGMENT 0x15
#define DEVICE_IMU_MSG_ALLOCATE_CAL_DATA_BUFFER 0x16
#define DEVICE_IMU_MSG_WRITE_CAL_DATA_SEGMENT 0x17
#define DEVICE_IMU_MSG_FREE_CAL_BUFFER 0x18
#define DEVICE_IMU_MSG_START_IMU_DATA 0x19
#define DEVICE_IMU_MSG_GET_STATIC_ID 0x1A
#define DEVICE_IMU_MSG_UNKNOWN 0x1D

#ifndef NDEBUG
#define device_imu_error(msg) fprintf(stderr, "ERROR: %s\n", msg)
#else
#define device_imu_error(msg) (0)
#endif

static bool hid_open_impl(device_imu_type* device, const struct imu_hid_info* info) {
    int iface = xreal_imu_interface_id(info->product_id);
    if (iface != -1 && info->interface_number == iface) {
        #ifndef NDEBUG
            printf("[hid] Found IMU device pid=0x%x iface=%d\n", info->product_id, iface);
        #endif
        device->handle = hid_open_path(info->path);

        if (device->handle) {
            device->max_payload_size = xreal_imu_max_payload_size(info->product_id);
        }
    }

    return device->handle != NULL;
}

static void hid_close_impl(device_imu_type* device) {
    if (device->handle) {
        hid_close((hid_device*)device->handle);
        device->handle = NULL;
    }
    device_exit();
}

static bool send_payload(device_imu_type* device, uint16_t size, const uint8_t* payload) {
	int payload_size = size;
	if (payload_size > device->max_payload_size) {
		payload_size = device->max_payload_size;
	}
	
	int transferred = hid_write(device->handle, payload, payload_size);	
	if (transferred != payload_size) {
		device_imu_error("Sending payload failed");
		return false;
	}
	
	return (transferred == size);
}

static bool recv_payload(device_imu_type* device, uint16_t size, uint8_t* payload) {
	int payload_size = size;
	if (payload_size > device->max_payload_size) {
		payload_size = device->max_payload_size;
	}
	
	int transferred = hid_read(device->handle, payload, payload_size);
	
	if (transferred >= payload_size) {
		transferred = payload_size;
	}

	if (transferred == 0) {
		return false;
	}
	
	if (transferred != payload_size) {
		device_imu_error("Receiving payload failed");
		return false;
	}
	
	return (transferred == size);
}

struct __attribute__((__packed__)) payload_packet_t {
	uint8_t head;
	uint32_t checksum;
	uint16_t length;
	uint8_t msgid;
	uint8_t data [512 - 8];
};

typedef struct payload_packet_t payload_packet_type;

static bool send_payload_msg(device_imu_type* device, uint8_t msgid, uint16_t len, const uint8_t* data) {
	static payload_packet_type packet;

	const uint16_t packet_len = 3 + len;
	const uint16_t payload_len = 5 + packet_len;
	
	packet.head = 0xAA;
	packet.length = htole16(packet_len);
	packet.msgid = msgid;
	
	memcpy(packet.data, data, len);
	packet.checksum = htole32(
		crc32_checksum(
			(const uint8_t*) (&packet.length),
			packet.length
		)
	);
	
	return send_payload(device, payload_len, (uint8_t*) (&packet));
}

static bool send_payload_msg_signal(device_imu_type* device, uint8_t msgid, uint8_t signal) {
	return send_payload_msg(device, msgid, 1, &signal);
}

static bool recv_payload_msg(device_imu_type* device, uint8_t msgid, uint16_t len, uint8_t* data) {
	static payload_packet_type packet;
	
	packet.head = 0;
	packet.length = 0;
	packet.msgid = 0;
	
	const uint16_t packet_len = 3 + len;
	const uint16_t payload_len = 5 + packet_len;
	
	do {
		if (!recv_payload(device, payload_len, (uint8_t*) (&packet))) {
			return false;
		}
	} while (packet.msgid != msgid);
	
	memcpy(data, packet.data, len);
	return true;
}

static bool hid_start_stream(device_imu_type* dev) {
    return send_payload_msg_signal(dev, DEVICE_IMU_MSG_START_IMU_DATA, 0x1) && 
           recv_payload_msg(dev, DEVICE_IMU_MSG_START_IMU_DATA, 0, NULL);
}

static bool hid_stop_stream(device_imu_type* dev) {
    return send_payload_msg_signal(dev, DEVICE_IMU_MSG_START_IMU_DATA, 0x0) && 
           recv_payload_msg(dev, DEVICE_IMU_MSG_START_IMU_DATA, 0, NULL);
}

static bool hid_get_static_id(device_imu_type* dev, uint32_t* out_id) {
    return send_payload_msg(dev, DEVICE_IMU_MSG_GET_STATIC_ID, 0, NULL) &&
        recv_payload_msg(dev, DEVICE_IMU_MSG_GET_STATIC_ID, 4, (uint8_t*)out_id);
}

static bool hid_load_calibration_json(device_imu_type* dev, uint32_t* len, char** data) {
    if (!send_payload_msg(dev, DEVICE_IMU_MSG_GET_CAL_DATA_LENGTH, 0, NULL)) return false;
    *len = 0;
    if (!recv_payload_msg(dev, DEVICE_IMU_MSG_GET_CAL_DATA_LENGTH, 4, (uint8_t*)len)) return false;
    const uint16_t max_packet_size = (dev->max_payload_size - 8);
    *data = (char*)malloc(*len + 1);
    if (!*data) return false;
    uint32_t pos = 0;
    while (pos < *len) {
        if (!send_payload_msg(dev, DEVICE_IMU_MSG_CAL_DATA_GET_NEXT_SEGMENT, 0, NULL)) break;
        const uint16_t next = (uint16_t)((*len - pos) > max_packet_size ? max_packet_size : (*len - pos));
        if (!recv_payload_msg(dev, DEVICE_IMU_MSG_CAL_DATA_GET_NEXT_SEGMENT, next, (uint8_t*)(*data + pos))) break;
        pos += next;
    }
    (*data)[pos] = '\0';
    return true;
}

static int32_t pack32bit_signed(const uint8_t* data) {
    uint32_t unsigned_value = (data[0]) | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
    return ((int32_t) unsigned_value);
}

static int32_t pack24bit_signed(const uint8_t* data) {
    uint32_t unsigned_value = (data[0]) | (data[1] << 8) | (data[2] << 16);
    if ((data[2] & 0x80) != 0) unsigned_value |= (0xFF << 24);
    return ((int32_t) unsigned_value);
}

static int16_t pack16bit_signed(const uint8_t* data) {
    uint16_t unsigned_value = (data[1] << 8) | (data[0]);
    return (int16_t) unsigned_value;
}

static int32_t pack32bit_signed_swap(const uint8_t* data) {
    uint32_t unsigned_value = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | (data[3]);
    return ((int32_t) unsigned_value);
}

static int16_t pack16bit_signed_swap(const uint8_t* data) {
    uint16_t unsigned_value = (data[0] << 8) | (data[1]);
    return (int16_t) unsigned_value;
}

static int16_t pack16bit_signed_bizarre(const uint8_t* data) {
    uint16_t unsigned_value = (data[0]) | ((data[1] ^ 0x80) << 8);
    return (int16_t) unsigned_value;
}

static int hid_next_sample(device_imu_type* device, struct imu_sample* out, int timeout_ms) {
    struct device_imu_packet_t p = {0};
    int n = hid_read_timeout((hid_device*)device->handle, (unsigned char*)&p, sizeof(p), timeout_ms);
    if (n <= 0) return n; // 0 timeout, -1 error
    if (n != (int)sizeof(p)) return -1;

    // Special init packet
    if (p.signature[0] == 0xaa && p.signature[1] == 0x53) {
        memset(out, 0, sizeof(*out));
        out->flags = 1;
        out->timestamp_ns = le64toh(p.timestamp);
        out->temperature_c = NAN;
        out->mx = out->my = out->mz = NAN;
        return 1;
    }

    if ((p.signature[0] != 0x01) || (p.signature[1] != 0x02)) {
        return 0; // skip unknown
    }

    int32_t vel_m = pack16bit_signed(p.angular_multiplier);
    int32_t vel_d = pack32bit_signed(p.angular_divisor);
    int32_t vel_x = pack24bit_signed(p.angular_velocity_x);
    int32_t vel_y = pack24bit_signed(p.angular_velocity_y);
    int32_t vel_z = pack24bit_signed(p.angular_velocity_z);

    int32_t accel_m = pack16bit_signed(p.acceleration_multiplier);
    int32_t accel_d = pack32bit_signed(p.acceleration_divisor);
    int32_t accel_x = pack24bit_signed(p.acceleration_x);
    int32_t accel_y = pack24bit_signed(p.acceleration_y);
    int32_t accel_z = pack24bit_signed(p.acceleration_z);

    int32_t magnet_m = pack16bit_signed_swap(p.magnetic_multiplier);
    int32_t magnet_d = pack32bit_signed_swap(p.magnetic_divisor);
    int16_t magnet_x = pack16bit_signed_bizarre(p.magnetic_x);
    int16_t magnet_y = pack16bit_signed_bizarre(p.magnetic_y);
    int16_t magnet_z = pack16bit_signed_bizarre(p.magnetic_z);

    int16_t temperature = pack16bit_signed(p.temperature);

    memset(out, 0, sizeof(*out));
    out->gx = (float) vel_x * (float) vel_m / (float) vel_d;
    out->gy = (float) vel_y * (float) vel_m / (float) vel_d;
    out->gz = (float) vel_z * (float) vel_m / (float) vel_d;

    out->ax = (float) accel_x * (float) accel_m / (float) accel_d;
    out->ay = (float) accel_y * (float) accel_m / (float) accel_d;
    out->az = (float) accel_z * (float) accel_m / (float) accel_d;

    out->mx = (float) magnet_x * (float) magnet_m / (float) magnet_d;
    out->my = (float) magnet_y * (float) magnet_m / (float) magnet_d;
    out->mz = (float) magnet_z * (float) magnet_m / (float) magnet_d;

    out->temperature_c = ((float) temperature) / 132.48f + 25.0f;
    out->timestamp_ns = le64toh(p.timestamp);
    out->flags = 0;
    return 1;
}

const imu_protocol imu_protocol_hid = {
    .open = hid_open_impl,
    .close = hid_close_impl,
    .start_stream = hid_start_stream,
    .stop_stream = hid_stop_stream,
    .get_static_id = hid_get_static_id,
    .load_calibration_json = hid_load_calibration_json,
    .next_sample = hid_next_sample,
};
