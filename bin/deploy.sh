#!/bin/bash

gzip -9k $1
aws s3 cp --content-encoding gzip $2 $1.gz s3://qanonposts.com/$1
rm $1.gz
