#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/quickshell/weather"
ENV_FILE="$(dirname "$0")/.env"
JSON_FILE="${CACHE_DIR}/weather.json"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

KEY="$OPENWEATHER_KEY"
ID="$OPENWEATHER_CITY_ID"
UNIT="${OPENWEATHER_UNIT:-metric}"

case "$UNIT" in
    "imperial") UNIT_SYM="°F" ;;
    "standard") UNIT_SYM="K" ;;
    *) UNIT_SYM="°C" ;;
esac

mkdir -p "${CACHE_DIR}"

# Use UTF-8 for icon rendering, LC_ALL=C only for date commands
get_icon() {
    local code="$1"
    local icon=""
    local quote=""
    case $code in
        "50d"|"50n") icon=$(printf '\U000F0591'); quote="Mist" ;;
        "01d") icon=$(printf '\uf185'); quote="Sunny" ;;
        "01n") icon=$(printf '\uf186'); quote="Clear" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") icon=$(printf '\uf0c2'); quote="Cloudy" ;;
        "09d"|"09n"|"10d"|"10n") icon=$(printf '\U000F0597'); quote="Rainy" ;;
        "11d"|"11n") icon=$(printf '\uf0e7'); quote="Storm" ;;
        "13d"|"13n") icon=$(printf '\uf1dc'); quote="Snow" ;;
        *) icon=$(printf '\uf0c2'); quote="Unknown" ;;
    esac
    echo "$icon|$quote"
}

get_hex() {
    case $1 in
        "50d"|"50n") echo "#84afdb" ;;
        "01d") echo "#f9e2af" ;;
        "01n") echo "#cba6f7" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") echo "#bac2de" ;;
        "09d"|"09n"|"10d"|"10n") echo "#74c7ec" ;;
        "11d"|"11n") echo "#f9e2af" ;;
        "13d"|"13n") echo "#cdd6f4" ;;
        *) echo "#cdd6f4" ;;
    esac
}

write_dummy_data() {
    final_json="["
    for i in {0..4}; do
        future_date=$(LC_ALL=C date -d "+$i days")
        f_day=$(LC_ALL=C date -d "$future_date" "+%a")
        f_full_day=$(LC_ALL=C date -d "$future_date" "+%A")
        f_date_num=$(LC_ALL=C date -d "$future_date" "+%d %b")
        final_json="${final_json} {
            \"id\": \"${i}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"0.0\",
            \"min\": \"0.0\",
            \"feels_like\": \"0.0\",
            \"wind\": \"0\",
            \"humidity\": \"0\",
            \"pop\": \"0\",
            \"icon\": \"$(printf '\uf0c2')\",
            \"hex\": \"#cdd6f4\",
            \"desc\": \"No API Key\",
            \"hourly\": [{\"time\": \"00:00\", \"temp\": \"0.0\", \"icon\": \"$(printf '\uf0c2')\", \"hex\": \"#cdd6f4\"}]
        },"
    done
    final_json="${final_json%,}]"
    echo "{ \"current_temp\": \"0.0\", \"current_icon\": \"$(printf '\uf0c2')\", \"current_hex\": \"#cdd6f4\", \"current_desc\": \"Setup .env\", \"forecast\": ${final_json} }" > "${JSON_FILE}"
}

get_data() {
    if [[ -z "$KEY" || "$KEY" == "Skipped" || "$KEY" == "OPENWEATHER_KEY" ]]; then
        write_dummy_data
        return
    fi

    forecast_url="http://api.openweathermap.org/data/2.5/forecast?APPID=${KEY}&id=${ID}&units=${UNIT}"
    raw_api=$(curl -sf "$forecast_url" 2>/dev/null)
    weather_url="http://api.openweathermap.org/data/2.5/weather?APPID=${KEY}&id=${ID}&units=${UNIT}"
    raw_weather=$(curl -sf "$weather_url" 2>/dev/null)

    api_cod=$(echo "$raw_api" | jq -r '.cod' 2>/dev/null)

    if [ -z "$raw_api" ] || [ -z "$raw_weather" ] || [[ "$api_cod" != "200" ]]; then
        if [ ! -f "$JSON_FILE" ]; then write_dummy_data; fi
        return
    fi

    c_temp=$(echo "$raw_weather" | jq -r '.main.temp')
    c_temp=$(printf "%.1f" "$c_temp")
    c_code=$(echo "$raw_weather" | jq -r '.weather[0].icon')
    c_icon=$(get_icon "$c_code" | cut -d'|' -f1)
    c_hex=$(get_hex "$c_code")
    c_desc=$(echo "$raw_weather" | jq -r '.weather[0].description' | sed -e "s/\b\(.\)/\u\1/g")

    current_date=$(LC_ALL=C date +%Y-%m-%d)

    if [ ! -z "$raw_api" ]; then
        dates=$(echo "$raw_api" | jq -r '.list[].dt_txt | split(" ")[0]' | sort -u | head -n 5)
        final_json="["
        counter=0

        for d in $dates; do
            day_data=$(echo "$raw_api" | jq "[.list[] | select(.dt_txt | startswith(\"$d\"))]")
            raw_max=$(echo "$day_data" | jq '[.[].main.temp_max] | max')
            f_max_temp=$(printf "%.1f" "$raw_max")
            raw_min=$(echo "$day_data" | jq '[.[].main.temp_min] | min')
            f_min_temp=$(printf "%.1f" "$raw_min")
            raw_feels=$(echo "$day_data" | jq '[.[].main.feels_like] | max')
            f_feels_like=$(printf "%.1f" "$raw_feels")
            f_pop=$(echo "$day_data" | jq '[.[].pop] | max')
            f_pop_pct=$(echo "$day_data" | jq '[.[].pop] | max * 100 | floor')
            f_wind=$(echo "$day_data" | jq '[.[].wind.speed] | max | round')
            f_hum=$(echo "$day_data" | jq '[.[].main.humidity] | add / length | round')
            f_code=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].icon')
            f_desc=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].description' | sed -e "s/\b\(.\)/\u\1/g")
            f_icon_data=$(get_icon "$f_code")
            f_icon=$(echo "$f_icon_data" | cut -d'|' -f1)
            f_hex=$(get_hex "$f_code")
            f_day=$(LC_ALL=C date -d "$d" "+%a")
            f_full_day=$(LC_ALL=C date -d "$d" "+%A")
            f_date_num=$(LC_ALL=C date -d "$d" "+%d %b")

            hourly_json="["
            count_slots=$(echo "$day_data" | jq '. | length')
            count_slots=$((count_slots-1))
            for i in $(seq 0 1 $count_slots); do
                slot_item=$(echo "$day_data" | jq ".[$i]")
                raw_s_temp=$(echo "$slot_item" | jq ".main.temp")
                s_temp=$(printf "%.1f" "$raw_s_temp")
                s_dt=$(echo "$slot_item" | jq ".dt")
                s_time=$(LC_ALL=C date -d @$s_dt "+%H:%M")
                s_code=$(echo "$slot_item" | jq -r ".weather[0].icon")
                s_hex=$(get_hex "$s_code")
                s_icon=$(get_icon "$s_code" | cut -d'|' -f1)
                hourly_json="${hourly_json} {\"time\": \"${s_time}\", \"temp\": \"${s_temp}\", \"icon\": \"${s_icon}\", \"hex\": \"${s_hex}\"},"
            done
            hourly_json="${hourly_json%,}]"

            final_json="${final_json} {
                \"id\": \"${counter}\",
                \"day\": \"${f_day}\",
                \"day_full\": \"${f_full_day}\",
                \"date\": \"${f_date_num}\",
                \"max\": \"${f_max_temp}\",
                \"min\": \"${f_min_temp}\",
                \"feels_like\": \"${f_feels_like}\",
                \"wind\": \"${f_wind}\",
                \"humidity\": \"${f_hum}\",
                \"pop\": \"${f_pop_pct}\",
                \"icon\": \"${f_icon}\",
                \"hex\": \"${f_hex}\",
                \"desc\": \"${f_desc}\",
                \"hourly\": ${hourly_json}
            },"
            ((counter++))
        done
        final_json="${final_json%,}]"
        echo "{ \"current_temp\": \"${c_temp}\", \"current_icon\": \"${c_icon}\", \"current_hex\": \"${c_hex}\", \"current_desc\": \"${c_desc}\", \"forecast\": ${final_json} }" > "${JSON_FILE}"
    fi
}

if [[ "$1" == "--json" ]]; then
    CACHE_LIMIT=900
    if [ -f "$JSON_FILE" ]; then
        file_time=$(stat -c %Y "$JSON_FILE")
        current_time=$(LC_ALL=C date +%s)
        diff=$((current_time - file_time))
        if [ $diff -gt $CACHE_LIMIT ]; then
            touch "$JSON_FILE"
            get_data &
        fi
        cat "$JSON_FILE"
    else
        get_data
        cat "$JSON_FILE"
    fi
elif [[ "$1" == "--refresh" ]]; then
    get_data
    cat "$JSON_FILE"
fi
