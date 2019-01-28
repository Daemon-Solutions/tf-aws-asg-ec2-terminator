"""
Terminator for EC2 instances.
"""

import boto3
import json
import logging
import os
import time

from botocore.exceptions import ClientError
from collections import OrderedDict
from datetime import datetime, timedelta
from dateutil.parser import parse
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

cloudwatch = boto3.client('cloudwatch')
asg_client = boto3.client('autoscaling')
ec2 = boto3.resource('ec2')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FAILURE_COLOUR = os.environ['FAILURE_COLOUR']
SLACK_EMOJI = os.environ['SLACK_EMOJI']
SLACK_SUBJECT = os.environ['SLACK_SUBJECT']
SLACK_TITLE = os.environ['SLACK_TITLE']
SLACK_URL = os.environ['SLACK_URL']
SUCCESS_COLOUR = os.environ['SUCCESS_COLOUR']

def lambda_handler(event, context):
    logger.info('Event: ' + str(event))
    data = json.loads(event['Records'][0]['Sns']['Message'])
    slack_data = check_instances(data)

    if SLACK_URL:
        send_slack(slack_data)

def terminate(asg_name, asg_min, asg_instances, terminate_instances):
    # Count in service instances
    asg_in_service_instances = []

    for i in asg_instances:
        if i['LifecycleState'] == 'InService':
            asg_in_service_instances.append(i)

    asg_instance_count = len(asg_in_service_instances)

    # Check in service instances is greater than the asg min before terminating
    if (asg_instance_count - len(terminate_instances)) >= asg_min:
        ec2.instances.filter(InstanceIds=terminate_instances).terminate()
        return True
    else:
        return False

def check_instances(data):
    alert_data = {}
    try:
        if 'NewStateValue' in data:
            new_state_value = data['NewStateValue']

            alert_data['description'] = data['AlarmDescription']
            alert_data['short_description'] = data['NewStateValue']

            alert_data['alarm_name'] = data['AlarmName']
            alert_data['asg_name'] = data['Trigger']['Dimensions'][0]['value']
            alert_data['aws_account'] = data['AWSAccountId']
            alert_data['evaluation_periods'] = data['Trigger']['EvaluationPeriods']
            alert_data['new_state_reason'] = data['NewStateReason']
            alert_data['period'] = data['Trigger']['Period']
            alert_data['threshold'] = data['Trigger']['Threshold']
            alert_data['region'] = data['Region']
            alert_data['state_change_time'] = data['StateChangeTime']

    except KeyError as e:
        raise Exception('Required key not found: ' + str(e))

    asg_response = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[alert_data['asg_name']])
    instance_ids = []

    for i in asg_response['AutoScalingGroups']:
        asg_min = i['MinSize']
        asg_instances = i['Instances']
        for k in i['Instances']:
            instance_ids.append(k['InstanceId'])

        terminate_instances = []

        # Grab CloudWatch stats for each instance
        state_change_time = parse(alert_data['state_change_time'])

        for instance in instance_ids:
            fail_count = 0

            response = cloudwatch.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[
                    {
                        'Name' : 'InstanceId',
                        'Value' : instance
                    }
                ],
                StartTime=state_change_time - timedelta(seconds=(alert_data['period'] * alert_data['evaluation_periods'])),
                EndTime=state_change_time,
                Period=alert_data['period'],
                Statistics=[
                    'Maximum'
                ]
            )

            # Search for offending instances
            for value in response['Datapoints']:
                if value['Maximum'] >= alert_data['threshold']:
                    fail_count = fail_count + 1
            if fail_count == alert_data['evaluation_periods']:
                terminate_instances.append(instance)

        if not terminate_instances:
            raise Exception('Function invoked, but no instances found to terminate.')

        alert_data['instances'] = terminate_instances

        # Terminate them if possible
        if terminate(alert_data['asg_name'], asg_min, asg_instances, terminate_instances):
            alert_data['terminate_success'] = "True"
            alert_data['colour'] = SUCCESS_COLOUR
        else:
            alert_data['terminate_success'] = "False"
            alert_data['colour'] = FAILURE_COLOUR

    return alert_data

def send_slack(data):
    data = {
        'username': SLACK_SUBJECT,
        'icon_emoji': SLACK_EMOJI,
        "attachments": [{
            "fallback": data['new_state_reason'],
            "color": data['colour'],
            "author_name": SLACK_TITLE,
            "title": data['description'],
            "text": data['new_state_reason'],
            "fields": [
		{
		    "title": "Instances",
		    "value": ",".join(data['instances']),
		    "short": "false"
		},
                {
                    "title": "Terminated",
                    "value": data['terminate_success'],
                    "short": "false"
                }
            ],
            "footer": "Account: " + data['aws_account'] + ", Region: " + data['region'],
            "ts": time.time()
        }]
    }

    post_data = json.dumps(data).encode('utf-8')
    req = Request(SLACK_URL, post_data)

    try:
        response = urlopen(req)
        response.read()
        logger.info('Message posted to %s', SLACK_URL)
    except HTTPError as e:
        logger.error('Request failed: %d %s', e.code, e.reason)
    except URLError as e:
        logger.error('Server connection failed: %s', e.reason)


