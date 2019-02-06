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
sts = boto3.client('sts')
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
    terminated = terminate_instances(event)

    if SLACK_URL and terminated:
        send_slack(terminated)

def terminate_instances(data):
    data['aws_account'] = sts.get_caller_identity()["Account"]

    asg_response = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[data['asg_name']])
    instance_ids = []

    for asg in asg_response['AutoScalingGroups']:
        asg_min = asg['MinSize']
        asg_instances = asg['Instances']
        for instance in asg_instances:
            instance_ids.append(instance['InstanceId'])

        terminate_instances = []

        # Get current time
        current_time = datetime.utcnow()

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
                StartTime=current_time - timedelta(seconds=(int(data['period']) * int(data['evaluation_periods']))),
                EndTime=current_time,
                Period=int(data['period']),
                Statistics=[
                    'Maximum'
                ]
            )

            # Search for offending instances
            for value in response['Datapoints']:
                if value['Maximum'] >= int(data['threshold']):
                    fail_count = fail_count + 1
            if fail_count >= int(data['datapoints_to_alarm']):
                terminate_instances.append(instance)

        if terminate_instances:
            data['instances'] = terminate_instances
            asg_in_service_instances = []

            for i in asg_instances:
                if i['LifecycleState'] == 'InService':
                    asg_in_service_instances.append(i)

            asg_instance_count = len(asg_in_service_instances)

            # Check in service instances is greater than the asg min before terminating
            if (asg_instance_count - len(terminate_instances)) >= asg_min:
                ec2.instances.filter(InstanceIds=terminate_instances).terminate()
                data['terminate_success'] = "Terminated"
                data['colour'] = SUCCESS_COLOUR
            else:
                data['terminate_success'] = "Failed to terminate"
                data['colour'] = FAILURE_COLOUR

            return data
        else:
            print('Function invoked, but no instances found to terminate.')
            return False

def send_slack(data):
    data = {
        'username': SLACK_SUBJECT,
        'icon_emoji': SLACK_EMOJI,
        "attachments": [{
            "color": data['colour'],
            "author_name": SLACK_TITLE,
            "title": data['customer'] + ' ' + data['asg_name'] + ' max CPU threshold reached',
            "text": 'Threshhold of ' + data['threshold'] + '% CPU crossed for: ' + data['datapoints_to_alarm'] + ' datapoints in ' + data['evaluation_periods'],
            "fields": [
                {
                    "title": "Instances",
                    "value": ",".join(data['instances']),
                    "short": "false"
                },
                {
                    "title": "Status",
                    "value": data['terminate_success'],
                    "short": "false"
                }
            ],
            "footer": "Account: " + data['aws_account'] + ", Customer: " + data['customer'],
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


