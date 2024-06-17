from flask import Flask, render_template, jsonify, request, abort

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
)
import os
import psutil
import time
import csv
import fcntl

app = Flask(__name__)


# generation monitor.txt temple
generation_monitor_temple()

# Network Speed Monitor
interface = os.getenv("manager_nic")


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


# favicon.ico
@app.route("/favicon.ico")
def favicon():
    return "", 204


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
        with open("/log/" + file_path, "r") as f:
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
        cnt_end_tag,
    ) = count_access()

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
    return render_template("monitor.html")


if __name__ == "__main__":
    app.run("0.0.0.0", 5000)
