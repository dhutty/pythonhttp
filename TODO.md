## Cleanup

- Parameterize keyfile/certfile

## RFE

Either (or both?) using parameterization (argparse or click) or a configuration file, support extra functionality:
- -`--responsecode=200`-
-  `--success 80` and it will return 200 (202 for POST) 80% of the time and something else (5xx?) 20% of the time?
- Or perhaps something that will intentionally respond slowly some percent of the time?
- override `do_POST()`.
- handle other HTTP verbs than GET/POST? (does BaseHTTPRequestHandler support this?)
