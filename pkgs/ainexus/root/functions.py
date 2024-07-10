import fcntl
import ipaddress


def get_len_iprange(start_ip, end_ip):
    network_start = ipaddress.ip_network(f"{start_ip}/32")
    network_end = ipaddress.ip_network(f"{end_ip}/32")
    end_ip_addr = network_end.broadcast_address
    total_ips = int(end_ip_addr) - int(network_start[0]) + 1
    return total_ips


# count for ipxe
def count_access():
    Initrd_count = 0
    vmlinuz_count = 0
    iso_count = 0
    userdata_count = 0
    preseed_count = 0
    common_count = 0
    ib_count = 0
    nvidia_count = 0
    cuda_count = 0

    with open("/log/access.log", "r") as file:
        for line in file:
            if "initrd" in line:
                Initrd_count += 1
            if "vmlinuz" in line:
                vmlinuz_count += 1
            if "ubuntu-22.04.4-live" in line:
                iso_count += 1
            if "user-data" in line:
                userdata_count += 1
            if "preseed.sh" in line:
                preseed_count += 1
            if "common.tgz" in line:
                common_count += 1
            if "ib.tgz" in line:
                ib_count += 1
            if "nvidia.tgz" in line:
                nvidia_count += 1
            if "cuda" in line:
                cuda_count += 1

    return (
        Initrd_count // 2,
        vmlinuz_count // 2,
        iso_count // 2,
        userdata_count // 2,
        preseed_count // 2,
        common_count // 2,
        ib_count // 2,
        nvidia_count // 2,
        cuda_count // 2,
    )


# for ipxe
def count_dnsmasq():
    starttag_count = 0
    with open("/log/dnsmasq.log", "r") as file:
        for line in file:
            if "ipxe_ubuntu2204/ubuntu2204.cfg" in line:
                starttag_count += 1
    return starttag_count


# generation monitor.txt temple and count lens
def generation_monitor_temple():
    with open(
        "/var/www/html/workspace/iplist.txt", "r", encoding="utf-8"
    ) as original_file:
        lines = original_file.readlines()
    processed_lines = [
        "{} {} {} F F F F F click\n".format(
            line.strip().split()[2], line.strip().split()[0], line.strip().split()[1]
        )
        for line in lines
    ]

    with open("monitor.txt", "w", encoding="utf-8") as new_file:
        new_file.write(
            "IP Serial_Number HostName Installing Disk IB GPU Finished log\n"
        )
        new_file.writelines(processed_lines)
    return len(lines)


def update_installing_status(serial_number):
    with open("monitor.txt", "r+") as file:
        try:
            fd = file.fileno()
            fcntl.flock(fd, fcntl.LOCK_EX)
            lines = file.readlines()

            found = False
            for i, line in enumerate(lines):
                parts = line.strip().split()
                if len(parts) >= 4 and parts[1] == serial_number and parts[3] == "F":
                    lines[i] = " ".join(parts[:3]) + " T " + " ".join(parts[4:]) + "\n"
                    found = True

            if found:
                file.seek(0)
                file.writelines(lines)
                file.truncate()
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)


def update_logname(serial, logname):

    with open("monitor.txt", "r+") as file:
        fd = file.fileno()
        fcntl.flock(fd, fcntl.LOCK_EX)
        try:
            lines = file.readlines()
            updated_lines = []
            for line in lines:
                parts = line.strip().split()
                if len(parts) >= 2 and parts[1] == serial:
                    parts[-1] = logname
                updated_line = " ".join(parts) + "\n"
                updated_lines.append(updated_line)

            file.seek(0)
            file.truncate()
            file.writelines(updated_lines)
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)


def update_diskstate(serial_number, diskstate):
    with open("monitor.txt", "r+") as file:
        fd = file.fileno()
        fcntl.flock(fd, fcntl.LOCK_EX)

        try:
            lines = file.readlines()

            found = False
            for i, line in enumerate(lines):
                parts = line.strip().split()
                if (
                    len(parts) >= 5
                    and parts[1] == serial_number
                    and (parts[4] == "F" or parts[4] == "W" or parts[4] == "M")
                ):
                    if diskstate == "ok":
                        lines[i] = (
                            " ".join(parts[:4]) + " T " + " ".join(parts[5:]) + "\n"
                        )
                    elif diskstate == "nomatch":
                        lines[i] = (
                            " ".join(parts[:4]) + " M " + " ".join(parts[5:]) + "\n"
                        )
                    else:
                        lines[i] = (
                            " ".join(parts[:4]) + " W " + " ".join(parts[5:]) + "\n"
                        )
                    found = True

            if found:
                file.seek(0)
                file.truncate()
                file.writelines(lines)
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)


def update_ibstate(serial_number, ibstate):
    with open("monitor.txt", "r+") as file:
        fd = file.fileno()
        fcntl.flock(fd, fcntl.LOCK_EX)

        try:
            lines = file.readlines()
            found = False
            for i, line in enumerate(lines):
                parts = line.strip().split()
                if (
                    len(parts) >= 7
                    and parts[1] == serial_number
                    and (parts[5] == "F" or parts[5] == "W")
                ):
                    if ibstate == "ok":
                        lines[i] = (
                            " ".join(parts[:5]) + " T " + " ".join(parts[6:]) + "\n"
                        )
                    else:
                        lines[i] = (
                            " ".join(parts[:5]) + " W " + " ".join(parts[6:]) + "\n"
                        )
                    found = True

            if found:
                file.seek(0)
                file.truncate()
                file.writelines(lines)
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)


def update_gpustate(serial_number, gpustate):

    with open("monitor.txt", "r+") as file:
        fd = file.fileno()
        fcntl.flock(fd, fcntl.LOCK_EX)

        try:
            lines = file.readlines()

            found = False
            for i, line in enumerate(lines):
                parts = line.strip().split()
                if (
                    len(parts) >= 7
                    and parts[1] == serial_number
                    and (parts[6] == "F" or parts[6] == "W")
                ):
                    if gpustate == "ok":
                        lines[i] = (
                            " ".join(parts[:6]) + " T " + " ".join(parts[7:]) + "\n"
                        )
                    else:
                        lines[i] = (
                            " ".join(parts[:6]) + " W " + " ".join(parts[7:]) + "\n"
                        )
                    found = True

            if found:
                file.seek(0)
                file.truncate()

                file.writelines(lines)
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)


def update_finished_status(serial_number):
    with open("monitor.txt", "r+") as file:
        fd = file.fileno()
        fcntl.flock(fd, fcntl.LOCK_EX)

        try:
            lines = file.readlines()

            found = False
            for i, line in enumerate(lines):
                parts = line.strip().split()
                if (
                    len(parts) >= 7
                    and parts[1] == serial_number
                    and (parts[7] == "F" or parts[7] == "W")
                ):
                    lines[i] = " ".join(parts[:7]) + " T " + " ".join(parts[8:]) + "\n"
                    found = True

            if found:
                file.seek(0)
                file.truncate()

                file.writelines(lines)

        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)


# Installation Timeout
def install_timeout():
    with open("monitor.txt", "r+") as file:
        fd = file.fileno()
        fcntl.flock(fd, fcntl.LOCK_EX)
        try:
            lines = file.readlines()
            for i, line in enumerate(lines):
                parts = line.strip().split()
                if parts[7] == "F":
                    lines[i] = " ".join(parts[:7]) + " W " + " ".join(parts[8:]) + "\n"
            file.seek(0)
            file.truncate()
            file.writelines(lines)
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
