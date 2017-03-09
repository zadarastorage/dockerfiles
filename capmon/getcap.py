#!/usr/bin/env python
# Test script

import json, requests ### pip install requests

vpsaurl='https://ccvm-aws-eu1.zadarastorage.com:8888/clouds/awseu1/vpsas/155/pt/api/volumes.json?access_key=XEBDXQEBHIHXL0BHWAMT'
dburl = 'http://localhost:8086/write?db=MONITORING'

r = requests.get(vpsaurl)
data = json.loads(r.text)

## Tags    'pool_display_name','name','virtual_capacity','tenant_id'
## fields  'allocated_capacity' ,read_mbps_limit=0,read_iops_limit=0,write_iops_limit=0,write_mbps_limit=0'

### curl -i -XPOST 'http://localhost:8086/write?db=MONITORING&precision=s' --data-binary 'monitor,cloud_id=aws-eu1,vpsa_id=155,vpsa_name=awseu1-andytest,pool_display_name=pool01,name=volume-0000001 virtual_capacity=100,allocated_capacity=0.115234377'

tags =  [ 'pool_name', 'pool_display_name', 'name' ]
#fields =  [ 'virtual_capacity', 'allocated_capacity', 'read_mbps_limit', 'read_iops_limit', 'write_iops_limit' , 'write_mbps_limit' ]
fields =  [ 'virtual_capacity', 'allocated_capacity' ]

for entry in data['response']['volumes']:
    #print entry['name']
    outline1="monitor,cloud_id=aws-eu1,vpsa_id=123,vpsa_name=andytest2,"
    for k,v in entry.items():
        if k in tags:
            outline1 += ("%s=%s," % (k,v))
    outline = outline1.rstrip(",")
    outline += (" ")
    outline2 = ""
    for k,v in entry.items():
        if k in fields:
            outline2 += ("%s=%s," % (k,v))
    outline += outline2.rstrip(",")
    print outline.rstrip(",")
    i = requests.post(dburl , data=outline.rstrip(",") )
    print(i.url)
    print 'Status {0}'.format(i.status_code)
