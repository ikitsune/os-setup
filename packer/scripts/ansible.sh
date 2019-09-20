#!/bin/bash

# Add the ansible repository debian based
apt-get update -y
apt-get install software-properties-common -y
apt-add-repository ppa:ansible/ansible

# Install the ansible package
apt-get update -y
apt-get install ansible -y