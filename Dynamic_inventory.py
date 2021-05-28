#!/usr/bin/python3
import os
import boto3
import pprint
import json

def getgroupofhosts(ec2):
    allgroups = {}
    for each in ec2.instances.filter(Filters=[{'Name': 'instance-state-name', 'Values': ["running"]}]):
        for tag in each.tags:
            # if tag["Key"] in allgroups:
            #     hosts = allgroups.get(tag["Key"])
            #     hosts.append(each.public_ip_address)
            #     allgroups[tag["Key"]] = hosts
            # else:
            #     hosts = [each.public_ip_address]
            #     allgroups[tag["Key"]] = hosts
            
            if tag["Value"] in allgroups:
                hosts - allgroups.get(tag["Value"])
                hosts.append((each.public_ip_address))
                allgroups[tag["Value"]] = hosts
            else:
                hosts = [each.private_ip_address]
                allgroups[tag["Value"]] = hosts
    return allgroups

def main():
    ec2 = boto3.resource("ec2")
    all_groups = getgroupofhosts(ec2)
    inventory = {}
    for key, value in all_groups.items():
        hostsobj = {"hosts": value}
        inventory[key] = hostsobj
    pprint.pprint(inventory)

if __name__ == "__main__":
    main()



