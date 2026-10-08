#!/usr/bin/env python3
"""Add the first subscription and its group to the existing app review draft.

This never sets submitted=true and never sends the draft to App Review.
"""
import json
from pathlib import Path
from asc_request import request

REVIEW = 'bd1c9172-9404-43c1-a99b-20784c83c46c'
assert request('/v1/reviewSubmissions/' + REVIEW)['data']['attributes']['submittedDate'] is None
expected = [
    ('subscriptionGroupVersion', 'subscriptionGroupVersions', '7085fcd1-0303-46b2-962d-4e9c05077ff2'),
    ('subscriptionVersion', 'subscriptionVersions', '2cb3890d-b8b1-4905-ae2c-ee20736f5f00'),
]
for relationship, kind, identifier in expected:
    items = request(f'/v1/reviewSubmissions/{REVIEW}/items?include=appStoreVersion,subscriptionVersion,subscriptionGroupVersion')['data']
    if any((item.get('relationships', {}).get(relationship, {}).get('data') or {}).get('id') == identifier for item in items):
        print(json.dumps({'item': relationship, 'alreadyAdded': True}), flush=True)
        continue
    result = request('/v1/reviewSubmissionItems', 'POST', {'data': {
        'type': 'reviewSubmissionItems', 'relationships': {
            'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': REVIEW}},
            relationship: {'data': {'type': kind, 'id': identifier}}
        }}})['data']
    print(json.dumps({'item': relationship, 'id': result['id'], 'state': result['attributes']['state']}), flush=True)
proof = request(f'/v1/reviewSubmissions/{REVIEW}/items?include=appStoreVersion,subscriptionVersion,subscriptionGroupVersion')
Path('/private/tmp/larpy-combined-review-20261007.json').write_text(json.dumps(proof, indent=2))
assert len(proof['data']) == 3
assert request('/v1/reviewSubmissions/' + REVIEW)['data']['attributes']['submittedDate'] is None
print(json.dumps({'items': 3, 'reviewSubmitted': False, 'evidence': '/private/tmp/larpy-combined-review-20261007.json'}), flush=True)
