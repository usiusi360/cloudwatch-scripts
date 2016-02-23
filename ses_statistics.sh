#!/bin/bash
 
log() {
  echo $1 | logger
}
 
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
 
usage=`aws --region us-east-1 ses get-send-statistics|jq '.SendDataPoints' | jq 'sort_by(.Timestamp)|.[length-1]'`

Timestamp=`echo ${usage}|jq '.Timestamp'`
Bounces=`echo ${usage}|jq '.Bounces'`
Complaints=`echo ${usage}|jq '.Complaints'`

log "cloudwatch put-metrics-data SES Bounces:${Bounces} Complaints:${Complaints}"

ses_put_metrics=("--metric-name Bounces --unit Count --value ${Bounces}"
                 "--metric-name Complaints --unit Count --value ${Complaints}")
 
sleep $(($RANDOM % 15))

IFS_bak=$IFS
IFS=$'\n'
 
i=0
for options in ${ses_put_metrics[@]}; do

  j=0
  MAX_RETRY=3
  RETRY_INTERVAL=1
 
  while :; do
    eval "aws cloudwatch put-metric-data --namespace SES --region ${region} --timestamp ${Timestamp} ${options}"
    if [ $? -ne 0 ]; then
      if [ "${j}" -ge "${MAX_RETRY}" ]; then
        log "cloudwatch put-metrics-data SES failed to put metrics."
        IFS=$IFS_bak
        exit 1
      fi
    else
      break
    fi
    let j++
    sleep ${RETRY_INTERVAL}
  done
  let i++
done

IFS=$IFS_bak
 
exit 0
