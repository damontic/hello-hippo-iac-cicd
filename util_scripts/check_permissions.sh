#! /bin/bash

export AWS_PROFILE=hellohippo

aws iam list-attached-user-policies --user-name david
