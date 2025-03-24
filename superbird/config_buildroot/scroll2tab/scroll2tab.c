#include <linux/input.h>
#include <linux/uinput.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DEVICE "/dev/input/event1"

int emit(int fd, int type, int code, int val) {
    struct input_event ie = {0};
    ie.type = type;
    ie.code = code;
    ie.value = val;
    gettimeofday(&ie.time, NULL);
    return write(fd, &ie, sizeof(ie));
}

void send_tab(int ufd) {
    emit(ufd, EV_KEY, KEY_TAB, 1);
    emit(ufd, EV_KEY, KEY_TAB, 0);
    emit(ufd, EV_SYN, SYN_REPORT, 0);
}

void send_shift_tab(int ufd) {
    emit(ufd, EV_KEY, KEY_LEFTSHIFT, 1);
    emit(ufd, EV_KEY, KEY_TAB, 1);
    emit(ufd, EV_KEY, KEY_TAB, 0);
    emit(ufd, EV_KEY, KEY_LEFTSHIFT, 0);
    emit(ufd, EV_SYN, SYN_REPORT, 0);
}

int main() {
    int fd = open(DEVICE, O_RDONLY);
    if (fd < 0) {
        perror("Unable to open input device");
        return 1;
    }

    int ufd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (ufd < 0) {
        perror("Unable to open /dev/uinput");
        return 1;
    }

    ioctl(ufd, UI_SET_EVBIT, EV_KEY);
    ioctl(ufd, UI_SET_KEYBIT, KEY_TAB);
    ioctl(ufd, UI_SET_KEYBIT, KEY_LEFTSHIFT);

    struct uinput_setup usetup = {
        .id = {
            .bustype = BUS_USB,
            .vendor  = 0x1234,
            .product = 0x5678,
        },
        .name = "scroll2tab",
    };

    ioctl(ufd, UI_DEV_SETUP, &usetup);
    ioctl(ufd, UI_DEV_CREATE);

    printf("Listening for horizontal scroll on %s...\n", DEVICE);

    struct input_event ev;
    while (1) {
        if (read(fd, &ev, sizeof(ev)) == sizeof(ev)) {
            if (ev.type == EV_REL && ev.code == REL_HWHEEL) {
                if (ev.value > 0) {
                    printf("Scroll →\n");
                    send_tab(ufd);
                } else if (ev.value < 0) {
                    printf("Scroll ←\n");
                    send_shift_tab(ufd);
                }
            }
        }
    }

    ioctl(ufd, UI_DEV_DESTROY);
    close(ufd);
    close(fd);
    return 0;
}

