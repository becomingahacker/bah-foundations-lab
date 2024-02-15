#!/usr/bin/env python3

from ipaddress import IPv4Address

for i in range(0, 33, 1):
    print("\"" + str(IPv4Address(int(IPv4Address._make_netmask(str(i))[0])^(2**32-1)))+"\",")
    
