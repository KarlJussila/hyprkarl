#!/bin/bash

read_cpu() {
  read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
  cpu_idle=$((idle + iowait))
  cpu_total=$((user + nice + system + cpu_idle + irq + softirq + steal))
}

find_cpu_temp() {
  local dir name label
  for dir in /sys/class/hwmon/hwmon*; do
    read -r name < "$dir/name" 2>/dev/null || continue
    [[ $name == k10temp || $name == coretemp ]] || continue
    if [[ -r $dir/temp2_label ]] && read -r label < "$dir/temp2_label" && [[ $label == Tdie ]]; then
      cpu_temp_file=$dir/temp2_input
    else
      cpu_temp_file=$dir/temp1_input
    fi
    return
  done
  cpu_temp_file=/dev/null
}

read_gpu() {
  local card status total best_total=-1 control delay boot now_ms
  gpu_card=
  for card in /sys/class/drm/card[0-9]*; do
    [[ -r $card/device/vendor ]] || continue
    read -r status < "$card/device/power/runtime_status" 2>/dev/null || status=active
    [[ $status != suspended ]] || continue
    read -r total < "$card/device/mem_info_vram_total" 2>/dev/null || total=0
    if ((total > best_total)); then
      best_total=$total
      gpu_card=$card
    fi
  done

  if [[ -n $gpu_card ]]; then
    read -r control < "$gpu_card/device/power/control" 2>/dev/null || control=on
    read -r delay < "$gpu_card/device/power/autosuspend_delay_ms" 2>/dev/null || delay=0
    read -r boot < "$gpu_card/device/boot_vga" 2>/dev/null || boot=0
    now_ms=${EPOCHREALTIME/./}
    now_ms=${now_ms:0:13}

    # Live sensor reads re-arm runtime suspend on a discrete GPU. Replay the
    # last sample until twice its autosuspend delay has elapsed so this monitor
    # cannot keep an otherwise idle card awake.
    if [[ $gpu_card == "$last_gpu_card" && $control == auto && $boot != 1 && $delay =~ ^[0-9]+$ ]] \
      && ((delay > 0 && now_ms - last_gpu_read_ms < delay * 2)); then
      return
    fi

    read -r gpu_usage < "$gpu_card/device/gpu_busy_percent" 2>/dev/null || gpu_usage=0
    read -r gpu_vram_used < "$gpu_card/device/mem_info_vram_used" 2>/dev/null || gpu_vram_used=0
    read -r gpu_vram_total < "$gpu_card/device/mem_info_vram_total" 2>/dev/null || gpu_vram_total=0
    last_gpu_card=$gpu_card
    last_gpu_read_ms=$now_ms
  else
    gpu_usage=0
    gpu_vram_used=0
    gpu_vram_total=0
  fi
}

find_cpu_temp
last_gpu_card=
last_gpu_read_ms=0
gpu_usage=0
gpu_vram_used=0
gpu_vram_total=0
read_cpu
previous_idle=$cpu_idle
previous_total=$cpu_total

while true; do
  sleep 2
  read_cpu
  idle_delta=$((cpu_idle - previous_idle))
  total_delta=$((cpu_total - previous_total))
  if ((total_delta > 0)); then
    cpu_usage=$((100 * (total_delta - idle_delta) / total_delta))
  else
    cpu_usage=0
  fi
  previous_idle=$cpu_idle
  previous_total=$cpu_total

  mem_total=0
  mem_available=0
  swap_total=0
  swap_free=0
  while read -r key value _; do
    case $key in
      MemTotal:) mem_total=$value ;;
      MemAvailable:) mem_available=$value ;;
      SwapTotal:) swap_total=$value ;;
      SwapFree:) swap_free=$value ;;
    esac
  done < /proc/meminfo
  mem_used=$((mem_total - mem_available))
  swap_used=$((swap_total - swap_free))
  if ((mem_total > 0)); then
    mem_percent=$((100 * mem_used / mem_total))
  else
    mem_percent=0
  fi

  read -r cpu_temp_raw < "$cpu_temp_file" 2>/dev/null || cpu_temp_raw=0
  read_gpu

  recording=false
  recording_file=${XDG_RUNTIME_DIR:-/tmp}/hyprkarl/screenrecording.pid
  if [[ -r $recording_file ]] && read -r recording_pid < "$recording_file" && [[ -d /proc/$recording_pid ]]; then
    recording=true
  fi

  printf '{"cpuUsage":%d,"cpuTemp":%d,"gpuUsage":%d,"gpuVramUsed":%d,"gpuVramTotal":%d,"ramUsedPercent":%d,"ramUsed":%d,"ramTotal":%d,"swapUsed":%d,"swapTotal":%d,"recording":%s}\n' \
    "$cpu_usage" "$((cpu_temp_raw / 1000))" "$gpu_usage" "$gpu_vram_used" "$gpu_vram_total" \
    "$mem_percent" "$((mem_used * 1024))" "$((mem_total * 1024))" "$((swap_used * 1024))" "$((swap_total * 1024))" "$recording"
done
