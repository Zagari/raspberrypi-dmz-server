#!/bin/bash
INSTANCE_ID=$(terraform output -raw instance_id)
aws ec2 stop-instances --instance-ids "$INSTANCE_ID"
