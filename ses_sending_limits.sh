#!/bin/bash
 
log() {
  echo $1 | logger
}
 
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
 
usage=`aws --region us-east-1 ses get-send-quota`

SentLast24Hours=`echo ${usage}|jq .SentLast24Hours`
MaxSendRate=`echo ${usage}|jq .MaxSendRate`

log SentLast24hours:${SentLast24Hours}
log MaxSendRate:${MaxSendRate}

ses_put_metrics=("--metric-name SentLast24Hours --unit Count --value ${SentLast24Hours}"
                 "--metric-name MaxSendRate --unit Count --value ${MaxSendRate}")
 
sleep $(($RANDOM % 15))

IFS_bak=$IFS
IFS=$'\n'
 
i=0
for options in ${ses_put_metrics[@]}; do

  j=0
  MAX_RETRY=3
  RETRY_INTERVAL=1
 
  while :; do
    eval "aws cloudwatch put-metric-data --namespace SES --region ${region} ${options}"
    if [ $? -ne 0 ]; then
      if [ "${j}" -ge "${MAX_RETRY}" ]; then
        log "failed to put metrics."
        IFS=$IFS_bak
        exit 1
      fi
    else
      break
    fi
    #j=$((j + 1))
    let j++
    sleep ${RETRY_INTERVAL}
  done
  let i++
done

IFS=$IFS_bak
 
exit 0
