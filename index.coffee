#!/usr/bin/env coffee

AWS = require 'aws-sdk'

AWS.config.update
  region: process.env['AWS_DEFAULT_REGION'] or 'us-east-1'

cloudwatch = new AWS.CloudWatch()
action  = process.argv[2]

unless action? and process.argv[3]?
  console.log "Usage: #{process.argv[1]} <enable|disable> <name>"
  process.exit 1

name_expression = new RegExp(process.argv.slice(3).join(' '),'i')

sendRequest = (alarmNamesChunk)->
  if action == 'disable'
    cloudwatch.disableAlarmActions { AlarmNames: alarmNamesChunk }, (err, res) ->
      if err
        console.log "Error disabling #{alarmNamesChunk.length} alarm(s) matching '#{name_expression}'"
      else
        alarmNames.map (alarm) ->
          console.log "DISABLED: #{alarm}"
  else
    cloudwatch.enableAlarmActions { AlarmNames: alarmNamesChunk }, (err, res) ->
      if err
        console.log "Error enabling #{alarmNamesChunk.length} alarm(s) matching '#{name_expression}'"
      else
        alarmNames.map (alarm) ->
          console.log "ENABLED: #{alarm}"

alarmNames = []

modifyAlarms = (NextToken) ->
  params = {}
  params.NextToken = NextToken if NextToken
  
  cloudwatch.describeAlarms params, (err, res) ->
    for alarm in res.MetricAlarms
      if alarm.AlarmName.match name_expression
        if action == 'disable' && alarm.ActionsEnabled
          alarmNames.push alarm.AlarmName
        else unless alarm.ActionsEnabled
          alarmNames.push alarm.AlarmName

    if res.NextToken
      modifyAlarms res.NextToken
    else
      i=0
      while i < alarmNames.length
        alarmNamesChunk = alarmNames.slice(i, i + 100)
        i += 100
        sendRequest(alarmNamesChunk)
      
do modifyAlarms
