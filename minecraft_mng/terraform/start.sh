#!/bin/bash
INSTANCE_ID=$(terraform output -raw instance_id)
aws ec2 start-instances --instance-ids "$INSTANCE_ID"
