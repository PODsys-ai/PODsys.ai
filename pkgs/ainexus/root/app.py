from flask import Flask, render_template, jsonify, request, abort
from datetime import datetime
from functions import (
    count_access,
    count_dnsmasq,
    generation_monitor_temple,
    update_installing_status,
    update_logname,
    update_diskstate,
    update_gpustate,
    update_ibstate,
    update_finished_status,
    install_timeout,
    parse_config,
    get_len_iprange,
)
import os
import psutil
import time
import csv
import re

app = Flask(__name__)

app.config["isGetStartTime"] = False
app.config["startTime"] = None
app.config["endTime"] = 0
app.config["installTime"] = 0

app.config["isGetFirstEndtag"] = False
app.config["newEndtagTime"] = None
app.config["firstInstallTime"] = None
app.config["installTimeDiff"] = None
app.config["finishedCount"] = 0

# counts of receive_serial_e
app.config["counts_receive_serial_e"] = 0
app.config["isFinished"] = False


# generation monitor.txt temple and Count the total number of machines to be installed
app.config["countMachines"] = generation_monitor_temple()

current_year = datetime.now().year

# Network Speed DHCP config.yaml
config_data = parse_config('/var/www/html/workspace/config.yaml')

interface = config_data['manager_nic']
dhcp_s = config_data['dhcp_s']
dhcp_e = config_data['dhcp_e']
manger_ip = config_data['manager_ip']
compute_storage = config_data['compute_storage']
compute_passwd = config_data['compute_passwd']


total_ips = get_len_iprange(dhcp_s, dhcp_e)


@app.route("/updateusedip")
def updateusedip():
    with open("/var/lib/misc/dnsmasq.leases", "r") as file:
        lines = file.readlines()
    return jsonify({"usedip": len(lines)})


@app.route("/speed")
def get_speed():
    net_io = psutil.net_io_counters(pernic=True)
    if interface in net_io:
        rx_old = net_io[interface].bytes_recv
        tx_old = net_io[interface].bytes_sent
        time.sleep(1)
        net_io = psutil.net_io_counters(pernic=True)
        rx_new = net_io[interface].bytes_recv
        tx_new = net_io[interface].bytes_sent
        rx_speed = (rx_new - rx_old) / 1024 / 1024
        tx_speed = (tx_new - tx_old) / 1024 / 1024
        return jsonify({"rx_speed": rx_speed, "tx_speed": tx_speed})
    return jsonify({"rx_speed": 0, "tx_speed": 0})


# Install time
@app.route("/time")
def get_time():

    if not app.config["isGetStartTime"]:
        if os.path.exists("/var/www/html/workspace/log/dnsmasq.log"):
            with open("/var/www/html/workspace/log/dnsmasq.log", "r") as file:
                for line in file:
                    if "ipxe_ubuntu2204/ubuntu2204.cfg" in line:
                        time_regex = r"(\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})"
                        matched = re.search(time_regex, line)
                        time_str = matched.group(1)
                        log_time = datetime.strptime(
                            f"{time_str} {current_year}", "%b %d %H:%M:%S %Y"
                        )
                        app.config["startTime"] = log_time
                        app.config["isGetStartTime"] = True
                        break

    if app.config["isGetStartTime"]:
        if app.config["countMachines"] != app.config["counts_receive_serial_e"]:
            app.config["installTime"] = (
                datetime.now().replace(microsecond=0) - app.config["startTime"]
            )
        else:
            app.config["installTime"] = app.config["endTime"] - app.config["startTime"]

    if app.config["isGetFirstEndtag"] and (not app.config["isFinished"]):
        time1 = app.config["newEndtagTime"]
        time2 = datetime.now().replace(microsecond=0)
        app.config["installTimeDiff"] = time2 - time1
        time3 = app.config["firstInstallTime"]
        time4 = app.config["installTimeDiff"]
        if time3 < time4:
            app.config["isFinished"] = True
            install_timeout()

    temp = app.config["installTime"]
    if app.config["installTime"] == 0:
        return jsonify({"installTime": 0})
    seconds = int(temp.total_seconds())
    return jsonify({"installTime": seconds})


# favicon.ico
@app.route("/favicon.ico")
def favicon():
    return "", 204

# debug mode
@app.route("/debug", methods=["POST"])
def debug():
    serial_number = request.form.get("serial")
    lsblk_output = request.form.get("lsblk")
    ipa_output = request.form.get("ipa")

    if serial_number:
        with open(f"/var/www/html/workspace/log/{serial_number}_debug.log", "a") as log_file:
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            log_file.write(current_time + "\n")
            log_file.write("---------------Debug-info---------------" + "\n" + "\n")
            if lsblk_output:
                log_file.write("--------lsblk-------" + "\n")
                log_file.write(lsblk_output + "\n" + "\n")
            if ipa_output:
                log_file.write("--------ip a-------" + "\n")
                log_file.write(ipa_output + "\n" + "\n")
            log_file.write("---------------Debug-end---------------" + "\n" + "\n")

    return "Get Debug Info", 200


# get POST
@app.route("/receive_serial_s", methods=["POST"])
def receive_serial_s():
    serial_number = request.form.get("serial")
    if serial_number:
        update_installing_status(serial_number)
        return "Get Serial number", 200
    else:
        return "No serial number.", 400


@app.route("/updatelog", methods=["POST"])
def updatelog():
    serial_number = request.form.get("serial")
    log_name = request.form.get("log")
    if serial_number and log_name:
        update_logname(serial_number, log_name)
        return "Get Serial number", 200
    else:
        return "No serial number.", 400


@app.route("/diskstate", methods=["POST"])
def diskstate():
    serial_number = request.form.get("serial")
    diskstate = request.form.get("diskstate")
    if serial_number and diskstate:
        update_diskstate(serial_number, diskstate)
        return "Get diskstate", 200
    else:
        return "No diskstate", 400


@app.route("/gpustate", methods=["POST"])
def gpustate():
    serial_number = request.form.get("serial")
    gpustate = request.form.get("gpustate")
    if serial_number and gpustate:
        update_gpustate(serial_number, gpustate)
        return "Get gpustate", 200
    else:
        return "No gpustate", 400


@app.route("/ibstate", methods=["POST"])
def ibstate():
    serial_number = request.form.get("serial")
    ibstate = request.form.get("ibstate")
    if serial_number and ibstate:
        update_ibstate(serial_number, ibstate)
        return "Get ibstate", 200
    else:
        return "No ibstate", 400


@app.route("/receive_serial_e", methods=["POST"])
def receive_serial_e():

    if not app.config["isGetStartTime"]:
        if os.path.exists("/var/www/html/workspace/log/dnsmasq.log"):
            with open("/var/www/html/workspace/log/dnsmasq.log", "r") as file:
                for line in file:
                    if "ipxe_ubuntu2204/ubuntu2204.cfg" in line:
                        time_regex = r"(\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})"
                        matched = re.search(time_regex, line)
                        time_str = matched.group(1)
                        log_time = datetime.strptime(
                            f"{time_str} {current_year}", "%b %d %H:%M:%S %Y"
                        )
                        app.config["startTime"] = log_time
                        app.config["isGetStartTime"] = True
                        break

    app.config["counts_receive_serial_e"] = app.config["counts_receive_serial_e"] + 1

    if app.config["countMachines"] == app.config["counts_receive_serial_e"]:
        app.config["endTime"] = datetime.now().replace(microsecond=0)

    if not app.config["isGetFirstEndtag"]:
        app.config["isGetFirstEndtag"] = True
        app.config["firstInstallTime"] = (
            datetime.now().replace(microsecond=0) - app.config["startTime"]
        )

    if app.config["isGetFirstEndtag"]:
        app.config["newEndtagTime"] = datetime.now().replace(microsecond=0)

    serial_number = request.form.get("serial")
    if serial_number:
        update_finished_status(serial_number)
        return "Get Serial number", 200
    else:
        return "No serial number", 400


# READ file
@app.route("/<path:file_path>")
def open_file(file_path):
    try:
        with open("/var/www/html/workspace/log/" + file_path, "r") as f:
            file_content = f.read()
        return render_template(
            "file.html", file_path=file_path, file_content=file_content
        )
    except FileNotFoundError:
        abort(404, description="no log generation")


@app.route("/refresh_count")
def refresh_data():
    cnt_start_tag = count_dnsmasq()

    (
        cnt_Initrd,
        cnt_vmlinuz,
        cnt_ISO,
        cnt_userdata,
        cnt_preseed,
        cnt_common,
        cnt_ib,
        cnt_nvidia,
        cnt_cuda,
    ) = count_access()

    cnt_end_tag = app.config["counts_receive_serial_e"]

    data = {
        "cnt_start_tag": cnt_start_tag,
        "cnt_Initrd": cnt_Initrd,
        "cnt_vmlinuz": cnt_vmlinuz,
        "cnt_ISO": cnt_ISO,
        "cnt_userdata": cnt_userdata,
        "cnt_preseed": cnt_preseed,
        "cnt_common": cnt_common,
        "cnt_ib": cnt_ib,
        "cnt_nvidia": cnt_nvidia,
        "cnt_cuda": cnt_cuda,
        "cnt_end_tag": cnt_end_tag,
    }
    return jsonify(data)


@app.route("/get_state_table")
def get_state_table():
    with open("monitor.txt", "r", encoding="utf-8") as file:
        reader = csv.DictReader(file, delimiter=" ")
        data = list(reader)
    table_content = render_template("state.html", data=data)
    return table_content


@app.route("/")
def index():
    return render_template("monitor.html", interface=interface, total_ips=total_ips)


if __name__ == "__main__":
    app.run("0.0.0.0", 5000)
