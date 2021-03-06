#!/usr/bin/env bash

#
set -e 
START_TIME=`date +%s`

set -e
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}INFO${Font_color_suffix}]"
ERROR="[${Red_font_prefix}ERROR${Font_color_suffix}]"
TMATE_SOCK="/tmp/tmate.sock"
SERVERPUSH_LOG="/tmp/wechat.log"
CONTINUE_FILE="/tmp/continue"


echo -e "${INFO} change root password"
echo "root:$ROOT_PWD" | sudo chpasswd
echo -e "${INFO} enable root ssh login and restart the sshd"
echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd.service


echo -e "${INFO} install the tailscale -- add gpg"

curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -

echo -e "${INFO} install the tailscale -- add list"
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list

echo -e "${INFO} install the tailscale -- apt update"
sudo apt-get update

echo -e "${INFO} install the tailscale -- apt install"
sudo apt-get install tailscale

echo -e "${INFO} enable system ipforward"
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

echo -e "${INFO} replace the tailscaled.state"
echo "$TAILSCALEDSTATE" | sudo tee /var/lib/tailscale/tailscaled.state
echo -e "${INFO} restart the tailscaled service"
sudo systemctl restart tailscaled.service
echo -e "${INFO} join my network -- tailscale up"
sudo tailscale up --advertise-exit-node --accept-dns=false 


echo -e "${INFO} Now the github action machine has been joined into your tailscale network! Enjoy it!"

# Install tmate on Ubuntu
#echo -e "${INFO} Setting up tmate ..."
#if [[ -n "$(uname | grep Linux)" ]]; then
#    curl -fsSL git.io/tmate.sh | bash
#elif [[ -x "$(command -v brew)" ]]; then
#    brew install tmate
#else
#    echo -e "${ERROR} This system is not supported!"
#    exit 1
#fi

# Generate ssh key if needed
#[[ -e ~/.ssh/id_rsa ]] || ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ""

# Run deamonized tmate
#echo -e "${INFO} Running tmate..."
#tmate -S ${TMATE_SOCK} new-session -d
#tmate -S ${TMATE_SOCK} wait tmate-ready

# Print connection info
#TMATE_SSH=$(tmate -S ${TMATE_SOCK} display -p '#{tmate_ssh}')
#TMATE_WEB=$(tmate -S ${TMATE_SOCK} display -p '#{tmate_web}')

#MSG="
#*GitHub Actions - Tailscale:*

#*GitHub Actions - tmate session info:*

#⚡ *CLI:*
#\`${TMATE_SSH}\`

#🔗 *URL:*
#${TMATE_WEB}

#🔔 *TIPS:*
#Run '\`touch ${CONTINUE_FILE}\`' to continue to the next step.
#"

#if [[ -n "${SERVERPUSHKEY}" ]]; then
#    echo -e "${INFO} Sending message to Wechat..."
#    curl -sSX POST "${ServerPush_API_URL:-https://sc.ftqq.com}/${SERVERPUSHKEY}.send" \
#        -d "text=GAisOK" \
#        -d "desp=${MSG}" >${SERVERPUSH_LOG}
#    SERVERPUSH_STATUS=$(cat ${SERVERPUSH_LOG} | jq -r .errno)
#    if [[ ${SERVERPUSH_STATUS} != 0 ]]; then
#        echo -e "${ERROR} Wechat message sending failed: $(cat ${SERVERPUSH_LOG})"
#    else
#        echo -e "${INFO} Wechat message sent successfully!"
#    fi
#fi

#while ((${PRT_COUNT:=1} <= ${PRT_TOTAL:=10})); do
#    SECONDS_LEFT=${PRT_INTERVAL_SEC:=10}
#    while ((${PRT_COUNT} > 1)) && ((${SECONDS_LEFT} > 0)); do
#        echo -e "${INFO} (${PRT_COUNT}/${PRT_TOTAL}) Please wait ${SECONDS_LEFT}s ..."
#        sleep 1
#        SECONDS_LEFT=$((${SECONDS_LEFT} - 1))
#    done
#    echo "-----------------------------------------------------------------------------------"
#    echo "To connect to this session copy and paste the following into a terminal or browser:"
#    echo -e "CLI: ${Green_font_prefix}${TMATE_SSH}${Font_color_suffix}"
#    echo -e "URL: ${Green_font_prefix}${TMATE_WEB}${Font_color_suffix}"
#    echo -e "TIPS: Run 'touch ${CONTINUE_FILE}' to continue to the next step."
#    echo "-----------------------------------------------------------------------------------"
#    PRT_COUNT=$((${PRT_COUNT} + 1))
#done


while true; do
    sleep 300
    set -e
    NOW_TIME=`date +%s`
    RUNNER_TIME=`echo $START_TIME $NOW_TIME | awk '{print $2-$1}'`
    
    echo -e "${INFO} RUNNER_TIME is  ... ${RUNNER_TIME}"
    
    if [[ -e ${CONTINUE_FILE} ]] || ((${RUNNER_TIME} > 21500)); then

        if [[ -n "${SERVERPUSHKEY}" ]]; then
            echo -e "${INFO} Sending message to Wechat..."
            curl -sSX POST "${ServerPush_API_URL:-https://sctapi.ftqq.com}/${SERVERPUSHKEY}.send" \
                -d "title=前一设备已下线！" \
                -d "desp=前一设备已下线！" >${SERVERPUSH_LOG}
            SERVERPUSH_STATUS=$(cat ${SERVERPUSH_LOG} | jq -r .errno)
            if [[ ${SERVERPUSH_STATUS} != 0 ]]; then
                echo -e "${ERROR} Wechat message sending failed: $(cat ${SERVERPUSH_LOG})"
            else
                echo -e "${INFO} Wechat message sent successfully!"
            fi
        fi
    
        echo -e "${INFO} Continue to the next step."
        exit 0
    fi
done

if [[ -n "${SERVERPUSHKEY}" ]]; then
    echo -e "${INFO} Sending message to Wechat..."
    curl -sSX POST "${ServerPush_API_URL:-https://sctapi.ftqq.com}/${SERVERPUSHKEY}.send" \
        -d "title=前一设备已下线！" \
        -d "desp=前一设备已下线！" >${SERVERPUSH_LOG}
    SERVERPUSH_STATUS=$(cat ${SERVERPUSH_LOG} | jq -r .errno)
    if [[ ${SERVERPUSH_STATUS} != 0 ]]; then
        echo -e "${ERROR} Wechat message sending failed: $(cat ${SERVERPUSH_LOG})"
    else
        echo -e "${INFO} Wechat message sent successfully!"
    fi
fi

