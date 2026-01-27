import http from 'k6/http';
import { sleep, check } from 'k6';

// K6 options
export let options = {
  vus: 100,          // 100 virtual users
  duration: '10m',   // 10 minutes test
};

// Target URL
const url = 'http://frontend.localdev.me/';

export default function () {
  // Add x-canary header
  const headers = { 'x-canary': 'true' };

  // Simulate normal latency (0-2s)
  sleep(Math.random() * 2);

  // Simulate high-latency spikes (~20% of requests)
  if (Math.random() < 0.2) {  
    sleep(3 + Math.random() * 2); // 3-5s spike
  }

  // Optionally simulate errors (~5% of requests)
  const simulateError = Math.random() < 0.05;
  const targetUrl = simulateError ? url + '/not-found' : url;

  // Send request
  let res = http.get(targetUrl, { headers });

  // Check for 2xx success
  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
  });

  // Optional: log response time
  console.log(`Status: ${res.status}, Latency: ${res.timings.duration}ms`);
}
