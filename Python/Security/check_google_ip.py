# Checks a Google IP and determines whether it's in GCP or not.
import urllib
import ipaddress
import json
import requests
import argparse

google_services_url = "https://www.gstatic.com/ipranges/goog.json"
google_cloud_url = "https://www.gstatic.com/ipranges/cloud.json"


arg_parser = argparse.ArgumentParser(add_help=True)
arg_parser.add_argument("--ipv4", "-4", help="The IP to check.", required=True, dest="ipv4")
args = arg_parser.parse_args()
arg_vars = vars(args)

google_services_json = requests.get(google_services_url).json()
google_cloud_json = requests.get(google_cloud_url).json()

ip_to_check = ipaddress.ip_address(arg_vars["ipv4"])

for prefix_info in google_cloud_json["prefixes"]:
    if "ipv4Prefix" in prefix_info:
        if ip_to_check in ipaddress.ip_network(prefix_info["ipv4Prefix"]):
            print("Cloud IP (bad)")


for prefix_info in google_services_json["prefixes"]:
    if "ipv4Prefix" in prefix_info:
        if ip_to_check in ipaddress.ip_network(prefix_info["ipv4Prefix"]):
            print("Google operated IP (good)")
