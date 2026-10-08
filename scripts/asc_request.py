#!/usr/bin/env python3
"""App Store Connect requests using the existing local key. Never logs credentials."""
import json, subprocess, urllib.request, urllib.error
from pathlib import Path

def request(path, method='GET', body=None):
    signer = """
const fs=require('fs'), crypto=require('crypto'), os=require('os');
const c=JSON.parse(fs.readFileSync(os.homedir()+'/.appstoreconnect/asc_key.json','utf8'));
const b=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const now=Math.floor(Date.now()/1000);
const data=b({alg:'ES256',kid:c.key_id,typ:'JWT'})+'.'+b({iss:c.issuer_id,iat:now,exp:now+600,aud:'appstoreconnect-v1'});
process.stdout.write(data+'.'+crypto.sign('sha256',Buffer.from(data),{key:c.key,dsaEncoding:'ieee-p1363'}).toString('base64url'));
"""
    token = subprocess.run(['node','-e',signer],capture_output=True,text=True,check=True).stdout
    req = urllib.request.Request('https://api.appstoreconnect.apple.com'+path, method=method,
          headers={'Authorization':'Bearer '+token,'Content-Type':'application/json'},
          data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req,timeout=30) as response:
            return json.load(response) if response.status!=204 else {}
    except urllib.error.HTTPError as error:
        detail=json.loads(error.read())
        raise RuntimeError(json.dumps({'http':error.code,'errors':detail.get('errors',[])})) from None

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('path')
    args=parser.parse_args()
    print(json.dumps(request(args.path),indent=2))
