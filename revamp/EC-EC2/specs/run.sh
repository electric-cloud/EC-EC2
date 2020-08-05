#!/usr/bin/env bash


#  Environment Variables - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

export AWS_ACCESS_KEY_ID=AKIAJPPSLYZ76QHDQJ5Q
export AWS_SECRET_ACCESS_KEY=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
export AWS_REGION_NAME=us-east-2

export HTTP_PROXY=https://10.200.1.180:3128
export HTTP_PROXY_USER=user2
export HTTP_PROXY_PASS=user2

 export RECREATE_CONFIG=true
gradle test -PcommanderServer=vivarium --tests *RunInstances