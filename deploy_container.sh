#!/usr/bin/env bash
# Deploy multiple or one LXD containers from template container.
# For each one generate network config, set parent bridge and mirror repository for updates
# Author: Jan Polák

set -euo pipefail

file_eth0=eth0.network
file_eth1=eth1.network

container_prefix="my-cont"
ip_prefix_eth0="X.X.X"
ip_prefix_eth1="Y.Y.Y"

deploy_container() {
        local vrf="$1"

        # prepare IP adress
        ip_eth1=$((vrf * 4 -2))
        ip_eth0=$((ip_eth1-1))

        printf "Create container for VRF: %s eth0 IP: %s eth1 IP: %s\n" "$vrf" "$ip_eth0" "$ip_eth1"

        # new LXC container name
        new_cont=""
        printf -v new_cont "${container_prefix}-%02d" "$vrf"
		echo "$new_cont"
		
        # eth templates
        eth0=(
        "[Match]"
        "Name=eth0"
        ""
        "[Network]"
        "Address=${ip_prefix_eth0}.${ip_eth1}/30"
        "Gateway=${ip_prefix_eth0}.${ip_eth0}"
        )

        eth1=(
        "[Match]"
        "Name=eth1"
        ""
        "[Network]"
        "Address=${ip_prefix_eth1}.${ip_eth1}/24"
        )

        # export templates to files
        printf "%s\n" "${eth0[@]}" > "$file_eth0"
        printf "%s\n" "${eth1[@]}" > "$file_eth1"

        # create containert from template image
        lxc copy "${container_prefix}-template" "$new_cont"

        # edit eth0
        lxc config device set "$new_cont" eth0 host_name "veth-zbx${vrf}"
        lxc config device set "$new_cont" eth0 parent "br${vrf}"

        # edit eth1
        lxc config device set "$new_cont" eth1 host_name "veth-conzbx${vrf}"

        # copy network config
        lxc file push eth0.network eth1.network "${new_cont}/etc/systemd/network/"

        # start container
        lxc start "$new_cont"

        # add mirror repo, zabbix repo and update (no upgrade!)
        lxc exec "$new_cont" -- /mnt/source/deploy.sh


}



while [[ $# -gt 0 ]]
do
    case "$1" in

        -b|--begin-range)
            begin="$2"
            shift
            ;;
        -e|--end-range)
            end="$2"
            shift
            ;;
        -o|--one-container)
            one="$2"
            deploy_container "$one"
            exit
            ;;

        --help|*)
            help=(
            "Usage:"
            "Deploy range of containers or one container"
            " --begin-range \"value\" - start of range"
            " --end-range \"value\" - end of range"
            " --one-container - deploy one container"
            " --help - print help")
            printf "%s\n" "${help[@]}"
            exit 1
            ;;
    esac
    shift
done



for i in $(seq "$begin" "$end"); do

        deploy_container "$i"

done


