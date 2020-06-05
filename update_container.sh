#!/usr/bin/env bash
# Run update & upgrade on all running LXD containers (Ubuntu or Debian)
# Author: Jan Polák

set -euo pipefail

update_container () {

  list_of_containers="$(lxc list -c ns --format=csv)"
  readarray -t cont_arr <<< "$list_of_containers"

  for i in "${cont_arr[@]}";do
          name="$(cut -d',' -f1 <<<"$i")"
          state="$(cut -d',' -f2 <<<"$i")"
		  
      
          if [[ "$state" = "RUNNING" ]];
          then
            echo "upgrade $name"
            lxc exec "$name" -- bash -c "apt update && apt upgrade -y"
            echo "container ${name} -> upgrade complete"
          fi


  done

}

update_container




