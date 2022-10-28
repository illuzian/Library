import ipaddress
import requests

uuid = "generated your own unique guid"
microsoft_office_endpoint = f"https://endpoints.office.com/endpoints/Worldwide?ClientRequestId={uuid}&NoIPv6=true"
office_data = requests.get(microsoft_office_endpoint)

ips_to_check = [
    "1.2.3.4",
    "5.6.7.8"
    
]

found_ips = []

for ms_office_item in office_data.json():
    if 'ips' in ms_office_item:
        for ip_to_check in ips_to_check:
            as_ip_address = ipaddress.ip_address(ip_to_check)
            for network in ms_office_item['ips']:
                if as_ip_address in ipaddress.ip_network(network):
                    print(f'Found network for {ip_to_check} for service {ms_office_item["serviceAreaDisplayName"]}')
                    found_ips.append(ip_to_check)

                    
still_unknown = list(set(ips_to_check) - set(found_ips))
print(f"unknown items: {','.join(still_unknown)}" )
