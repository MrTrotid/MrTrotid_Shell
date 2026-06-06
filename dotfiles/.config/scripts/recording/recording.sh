#!/usr/bin/env bash
# Screen recording helper for Hyprland (wf-recorder)
# Flameshot-style: select region → toolbar appears → pick audio → record
# Usage: recording.sh [mode]
# Modes: region, full, stop, status

DIR="$HOME/Videos/Recordings"
mkdir -p "$DIR"
PID_FILE="/tmp/wf-recorder.pid"
AUDIO_PID="/tmp/wf-recorder-audio.pid"
AUDIO_FILE="/tmp/wf-recorder-audio.wav"
NOTIFY="$HOME/.config/scripts/qs-notify"
REC_ID=""  # unique per-recording ID for temp files

# ── Get audio device names ──
get_device_audio_source() {
    local sink
    sink=$(pactl get-default-sink 2>/dev/null)
    if [[ -n "$sink" ]]; then
        echo "${sink}.monitor"
    fi
}

get_input_audio_source() {
    pactl get-default-source 2>/dev/null
}

# ── Pick audio mode via rofi, positioned near selection ──
pick_audio() {
    local geom="$1"
    local rx=50 ry=50

    if [[ -n "$geom" ]]; then
        local x y w h
        x=$(echo "$geom" | cut -d',' -f1)
        y=$(echo "$geom" | cut -d',' -f2 | cut -d' ' -f1)
        w=$(echo "$geom" | cut -d' ' -f2 | cut -d'x' -f1)
        h=$(echo "$geom" | cut -d' ' -f2 | cut -d'x' -f2)
        rx=$(( x + w + 10 ))
        ry=$(( y + h - 120 ))
    fi

    local choice
    choice=$(echo -e "\uf028  Device audio only\n\uf130  Input audio (mic)\n\uf0e4  Both (device + input)\n\uf026  No audio" | rofi -dmenu \
        -p "Audio" \
        -theme-str "window { location: northwest; x-offset: ${rx}px; y-offset: ${ry}px; width: 260px; }" \
        -theme-str 'listview { lines: 4; }' \
        -theme-str 'entry { padding: 8px 12px; }' \
        -config ~/.config/rofi/applets/message.rasi 2>/dev/null)

    case "$choice" in
        *"Device audio"*)     echo "device" ;;
        *"Input audio"*)      echo "mic" ;;
        *"Both"*)             echo "both" ;;
        *"No audio"*)         echo "none" ;;
        *)                    echo "device" ;;
    esac
}

# ── Start audio recording (called by do_record for mic/both) ──
start_audio_capture() {
    local mode="$1"
    local file="$2"

    case "$mode" in
        mic)
            local src
            src=$(get_input_audio_source)
            if [[ -n "$src" ]]; then
                ffmpeg -hide_banner -loglevel error -y \
                    -f pulse -i "$src" \
                    -ac 2 -ar 48000 "$file" &
                echo $! > "$AUDIO_PID"
            fi
            ;;
        both)
            local dev_src mic_src
            dev_src=$(get_device_audio_source)
            mic_src=$(get_input_audio_source)

            if [[ -n "$dev_src" && -n "$mic_src" ]]; then
                ffmpeg -hide_banner -loglevel error -y \
                    -f pulse -i "$dev_src" \
                    -f pulse -i "$mic_src" \
                    -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[aout]" \
                    -map "[aout]" -ac 2 -ar 48000 "$file" &
                echo $! > "$AUDIO_PID"
            elif [[ -n "$dev_src" ]]; then
                ffmpeg -hide_banner -loglevel error -y \
                    -f pulse -i "$dev_src" \
                    -ac 2 -ar 48000 "$file" &
                echo $! > "$AUDIO_PID"
            elif [[ -n "$mic_src" ]]; then
                ffmpeg -hide_banner -loglevel error -y \
                    -f pulse -i "$mic_src" \
                    -ac 2 -ar 48000 "$file" &
                echo $! > "$AUDIO_PID"
            fi
            ;;
    esac
}

# ── Stop and cleanup ──
stop_audio_capture() {
    if [[ -f "$AUDIO_PID" ]]; then
        local pid
        pid=$(cat "$AUDIO_PID")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
        fi
        rm -f "$AUDIO_PID"
    fi
}

stop_recording() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        local vid_pid
        vid_pid=$(cat "$PID_FILE")

        # Stop video recording
        kill "$vid_pid" 2>/dev/null
        wait "$vid_pid" 2>/dev/null
        rm -f "$PID_FILE"

        # Stop audio capture and wait for file to flush
        stop_audio_capture
        sleep 0.3

        # Find the video file (most recent mp4 in DIR)
        local latest_vid
        latest_vid=$(ls -t "$DIR"/Recording_*.mp4 2>/dev/null | head -1)

        if [[ -n "$latest_vid" && -f "$AUDIO_FILE" ]]; then
            # Merge video + audio
            local merged="${latest_vid%.mp4}_merged.mp4"
            ffmpeg -hide_banner -loglevel error -y \
                -i "$latest_vid" -i "$AUDIO_FILE" \
                -c:v copy -c:a aac -b:a 192k \
                -shortest "$merged" && \
                mv "$merged" "$latest_vid"
            rm -f "$AUDIO_FILE"
            $NOTIFY "Recording stopped" "Saved to $latest_vid" "success"
        elif [[ -n "$latest_vid" ]]; then
            $NOTIFY "Recording stopped" "Saved to $latest_vid" "success"
        else
            $NOTIFY "Recording stopped" "Saved to $DIR" "success"
        fi
    else
        $NOTIFY "Recording" "No active recording" "error"
    fi
}

# ── Start recording ──
do_record() {
    local geometry="$1"
    local monitor_flag="$2"

    local audio_mode
    audio_mode=$(pick_audio "$geometry")
    if [[ -z "$audio_mode" ]]; then
        return 0
    fi

    REC_ID=$(date +%s)
    FILE="$DIR/Recording_${REC_ID}.mp4"

    # Build wf-recorder command
    local -a cmd=(wf-recorder -f "$FILE"
        -c libx264rgb -p crf=20 -p preset=superfast -p tune=zerolatency)

    if [[ -n "$geometry" ]]; then
        cmd+=(-g "$geometry")
    fi
    if [[ -n "$monitor_flag" ]]; then
        cmd+=(-o "$monitor_flag")
    fi

    # For device-only or mic-only, wf-recorder can handle audio directly
    case "$audio_mode" in
        device)
            local dev_src
            dev_src=$(get_device_audio_source)
            if [[ -n "$dev_src" ]]; then
                cmd+=(-a="$dev_src")
            fi
            ;;
        mic)
            local mic_src
            mic_src=$(get_input_audio_source)
            if [[ -n "$mic_src" ]]; then
                cmd+=(-a="$mic_src")
            fi
            ;;
        both)
            # wf-recorder can't mix two sources, so record video only
            # and capture mixed audio separately with ffmpeg
            start_audio_capture both "$AUDIO_FILE"
            ;;
        none)
            ;;
    esac

    "${cmd[@]}" &
    echo $! > "$PID_FILE"

    local desc=""
    case "$audio_mode" in
        device) desc="Device audio only" ;;
        mic)    desc="Input audio (mic)" ;;
        both)   desc="Device + Input audio" ;;
        none)   desc="No audio" ;;
    esac
    $NOTIFY "Recording started" "$desc" "recording"
}

# ── Region recording ──
start_region() {
    local region
    region=$(slurp -d -c '#81d5caAA' -b '#1a212080')
    if [[ -z "$region" ]]; then
        return 0
    fi
    do_record "$region" ""
}

# ── Full screen recording ──
start_full() {
    MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
    do_record "" "$MONITOR"
}

case "${1:-}" in
    region)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            stop_recording
        else
            start_region
        fi
        ;;
    full)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            stop_recording
        else
            start_full
        fi
        ;;
    stop)
        stop_recording
        ;;
    status)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "Recording (PID: $(cat "$PID_FILE"))"
        else
            echo "Not recording"
        fi
        ;;
    *)
        echo "Usage: $0 {region|full|stop|status}"
        exit 1
        ;;
esac
