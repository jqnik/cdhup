#!/bin/bash

FQDN=$1

sed -i 's/127.0.0.1.*/127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4/' /etc/hosts
