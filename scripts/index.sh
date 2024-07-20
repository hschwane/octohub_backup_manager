#!/bin/bash

set -efu

init_environment

main_drive="/dev/sdc1"
backup_path="/home/hendrik/sherver/test"
temp_state_file="/tmp/octohub_backup_state.tmp"
temp_progress_file="/tmp/octohub_progress.tmp"

if [ "$REQUEST_METHOD" = 'POST' ]; then

	read -r command parameters <<< "$REQUEST_BODY"

	if [ "$command" = "reboot" ]; then
	    reeboot
		add_header 'Content-Type' 'text/plain'
		send_response 200 "Command executed successfully!"
	elif [ "$command" = "shutdown" ]; then
	    shutdown -h now
		add_header 'Content-Type' 'text/plain'
		send_response 200 "Command executed successfully!"
	elif [ "$command" = "start_backup" ]; then
		backup_file="${backup_path}/octohub_backup_$(date +"%Y-%m-%d_%H-%M-%S").gz"
		size=$(blockdev --getsize64 $main_drive)
		echo "1" >> $temp_state_file && \
		dd if=$main_drive bs=16M conv=sync,noerror | pv -f -s $size -F '%t %b %a %e' 2>$temp_progress_file | pigz -c > $backup_file && sync && \
		rm $temp_state_file &
		add_header 'Content-Type' 'text/plain'
		send_response 200 "Command executed successfully!"
	elif [ "$command" = "remove_backup" ]; then
		rm ${backup_path}/${parameters}
		add_header 'Content-Type' 'text/plain'
		send_response 200 "removed ${backup_path}/${parameters}"
	elif [ "$command" = "restore_backup" ]; then
		backup_file="${backup_path}/${parameters}"
		size=$(stat -c%s "$backup_file")
		echo "2" >> $temp_state_file && \
		pigz -cdk $backup_file | pv -f -s $size -F '%t %b %a %e' 2>$temp_progress_file | dd of=$main_drive bs=16M && sync && \
		rm $temp_state_file &
		add_header 'Content-Type' 'text/plain'
		send_response 200 "Command executed successfully!"
	else
		add_header 'Content-Type' 'text/plain'
		send_error 500
	fi


elif [ "$REQUEST_METHOD" != 'GET' ]; then
	send_error 405
fi

HEAD_TEMPLATE=" <title>octohub backup service</title>
				<meta name=\"description\" content=\"octohub backup service\">"

BODY_TEMPLATE="<h2>octohub backup service</h2>"

show_reboot="true"
if [ -e "$temp_state_file" ]; then
	content=$(cat "$temp_state_file")
	if [ "$content" == "1" ]; then
		progress=$(sed 's/\r/\n/g' $temp_progress_file | tail -n1)
		BODY_TEMPLATE+="
			<p>Creating new backup, please wait...</p>
			<p>${progress}</p>
			<script>setTimeout(()=>location.reload(), 2000)</script>"
		show_reboot="false"
	elif [ "$content" == "2" ]; then
		progress=$(sed 's/\r/\n/g' $temp_progress_file | tail -n1)
		BODY_TEMPLATE+="
			<p>Restoring backup, please wait...</p>
			<p>${progress}</p>
			<script>setTimeout(()=>location.reload(), 2000)</script>"
		show_reboot="false"
	else
		BODY_TEMPLATE+="
			<p>Something went wrong with the temp file, please restart the system</p>
		"
	fi
else
	if [ ! -d "$backup_path" ]; then
		BODY_TEMPLATE+="<p>The folder ${backup_path} does not exist.</p>"
	else
		BODY_TEMPLATE+="
			<div>
				<button onclick='makeBackup()'>Create Backup</button>
			</div>
		"

		available_backups=$(ls -1 "$backup_path" | sort)

		BODY_TEMPLATE+="<table>"
		OLDIFS=$IFS
		IFS=$'\n'
		for file in $available_backups; do
		    BODY_TEMPLATE+="
				<tr>
					<th>$file</th>
					<th>$(ls -lh ${backup_path}/${file} | awk '{print $5}' )</th>
					<th><button onclick='restoreBackup(\"${file}\")'>restore</button><th>
					<th><button onclick='removeBackup(\"${file}\")'>remove</button><th>
				</tr>"
		done
		IFS=$OLDIFS
		BODY_TEMPLATE+="</table>"
	fi
fi

if [ "$show_reboot" == "true" ]; then
	BODY_TEMPLATE+="
	<div>
		<button onclick='reboot()'>Reboot</button>
		<button onclick='shutdown()'>Shutdown</button>
	</div>
	"
fi

export HEAD_TEMPLATE BODY_TEMPLATE

html=$(envsubst < 'templates/template.html')

add_header 'Content-Type' 'text/html; charset=utf-8'
send_response 200 "$html"