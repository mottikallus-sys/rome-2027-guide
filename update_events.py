#!/usr/bin/env python3
"""Update an optional dated Rome event feed using a Ticketmaster developer key.
This does not cover all Rome events. It preserves curated leads if key is not configured.
"""
import json, os, pathlib, urllib.parse, urllib.request, datetime
root=pathlib.Path(__file__).resolve().parents[1]
p=root/'events.json'; old=json.loads(p.read_text()); key=os.getenv('TICKETMASTER_API_KEY','').strip()
if not key:
 print('No TICKETMASTER_API_KEY secret: keeping curated leads; no false freshness claim.')
 raise SystemExit(0)
q={'apikey':key,'city':'Rome','countryCode':'IT','startDateTime':'2026-12-31T00:00:00Z','endDateTime':'2027-01-07T00:00:00Z','size':'100','sort':'date,asc'}
url='https://app.ticketmaster.com/discovery/v2/events.json?'+urllib.parse.urlencode(q)
req=urllib.request.Request(url,headers={'User-Agent':'RomeTravelGuide/1.0'})
with urllib.request.urlopen(req,timeout=25) as r:data=json.load(r)
events=[]
for x in data.get('_embedded',{}).get('events',[]):
 d=x.get('dates',{}).get('start',{}).get('localDate','')
 if not ('2026-12-31'<=d<='2027-01-06'):continue
 venue=next(iter(x.get('_embedded',{}).get('venues',[])),{}).get('name','Rome')
 events.append({'date':d,'title':x.get('name','Event'),'venue':venue,'description':'Ticketing listing — check event details and availability.','url':x.get('url','https://www.ticketmaster.it/')})
curated=old.get('events',[])
for x in curated:
 if x.get('url') and not any(y['title']==x['title'] for y in events):events.append(x)
new={'updated':datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='minutes'),'automatic':True,'events':sorted(events,key=lambda x:x['date'])}
p.write_text(json.dumps(new,ensure_ascii=False,indent=2)+'\n')
print('Saved',len(events),'events')
