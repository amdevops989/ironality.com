import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 30 },
    { duration: '3m', target: 100 },
    { duration: '3m', target: 200 },
    { duration: '2m', target: 0 },
  ],
};

const url = 'http://frontend.localdev.me/';

export default function () {
//  const headers = { 'x-canary': 'true' };  for canary

//  let res = http.get(url, { headers }); for canary
    let res = http.get(url);	

  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
  });
}

