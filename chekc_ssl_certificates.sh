#!/bin/bash

# Function to display help
function display_help {
    echo "Usage: $0 [-c | -t] url_list_file"
    echo "  -c   Output results in CSV format"
    echo "  -t   Output results in table format (default)"
    echo "url_list_file: A file containing one URL per line"
    exit 1
}

# Check for input arguments
if [ $# -lt 1 ]; then
    display_help
fi

# Set default format to table
output_format="table"

# Process command line options
while getopts ":ct:" option; do
    case $option in
        c) output_format="csv" ;;
        t) output_format="table" ;;
        \?) display_help ;;
    esac
done

shift $((OPTIND -1))

# Ensure a file is provided
if [ -z "$1" ]; then
    display_help
fi

url_file="$1"

# Check if the file exists
if [ ! -f "$url_file" ]; then
    echo "File not found!"
    exit 1
fi

# Output headers based on the format
if [ "$output_format" == "csv" ]; then
    echo "URL,Expiration Date,Days Until Expiration,Renewal Date"
else
    printf "%-50s %-25s %-20s %-25s\n" "URL" "Expiration Date" "Days Until Expiration" "Renewal Date"
    printf "%-50s %-25s %-20s %-25s\n" "----" "----------------" "-----------------------" "-------------"
fi

# Loop through each URL in the file
while IFS= read -r url; do
    # Ignore comments and empty lines
    [[ -z "$url" || "$url" =~ ^# ]] && continue

    # Extract host and port
    if [[ $url =~ ^https?:// ]]; then
        # Extract the FQDN and port (if specified) from the URL
        host=$(echo "$url" | sed -E 's#https?://([^/:]+).*#\1#')
        port=$(echo "$url" | sed -nE 's#https?://[^/:]+:([0-9]+).*#\1#p')

        # Default to port 443 if no port is specified
        if [ -z "$port" ]; then
            port=443
        fi

        # Get the expiration date using OpenSSL
        expiration_date=$(echo | openssl s_client -connect "$host:$port" -servername "$host" 2>/dev/null | openssl x509 -noout -dates | grep 'notAfter=' | cut -d'=' -f2)

        # If expiration date is found, process it
        if [ -n "$expiration_date" ]; then
            # Convert to seconds since epoch for calculation
            expiration_epoch=$(date -d "$expiration_date" +%s)
            current_epoch=$(date +%s)
            days_until_expiration=$(( (expiration_epoch - current_epoch) / 86400 ))
            warning_date=$(date -d @"$(( expiration_epoch - 30*86400 ))" '+%Y-%m-%d')

            # Format output based on the chosen format
            if [ "$output_format" == "csv" ]; then
                echo "$url,$expiration_date,$days_until_expiration,$warning_date"
            else
                printf "%-50s %-25s %-20d %-25s\n" "$url" "$expiration_date" "$days_until_expiration" "$warning_date"
            fi
        else
            if [ "$output_format" == "csv" ]; then
                echo "$url,Certificate not found,,-"
            else
                printf "%-50s %-25s %-20s %-25s\n" "$url" "Certificate not found" "-" "-"
            fi
        fi
    else
        if [ "$output_format" == "csv" ]; then
            echo "$url,Invalid URL,,-"
        else
            printf "%-50s %-25s %-20s %-25s\n" "$url" "Invalid URL" "-" "-"
        fi
    fi
done < "$url_file"
