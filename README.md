# Hono on Lambda Web Functions and classic Lambda

The Hono API from our blog post comparing AWS Lambda Web Functions with classic Lambda. One app, two entry points:

| Target | Entry | Build output | Runs as |
|---|---|---|---|
| `web` | `src/index.ts` | `dist.zip` (`index.js`) | Lambda Web Function, Node.js 24, Arm64 |
| `lambda` | `src/lambda.ts` | `dist-lambda.zip` (`index.mjs`, handler `index.handler`) | Classic Lambda, `nodejs24.x`, Arm64, Function URL |

Both bundle the same routes from `src/app.ts` into a single minified file with no `node_modules`.

## Routes

| Route | What it does |
|---|---|
| `GET /json` | Returns about 1 KB of JSON |
| `GET /io?ms=N` | Waits N ms on a timer (0-5000, default 50). Stands in for a database or API call |
| `GET /cpu?n=K` | Runs K chained SHA-256 rounds (default 1000). On Graviton, K = 35272 is about 100 ms of CPU |
| `GET /meta` | Process info: environment ID, uptime, request count, CPU used |

Every response carries `x-env-id`, `x-req-n`, `x-import-ms`, `x-boot-ms` and `x-uptime-ms` headers. A cold request has `x-req-n: 1`.

## Build

Needs Node.js 24, pnpm and `zip`.

```bash
pnpm install
pnpm run build          # both targets
pnpm run build:web      # dist.zip only
pnpm run build:lambda   # dist-lambda.zip only
```

## Run locally

A Web Function passes its listen address in `AWS_LAMBDA_HTTP_ENDPOINT` (`host:port`). Without it the server listens on `127.0.0.1:3000`.

```bash
pnpm run build:web
pnpm start
curl "localhost:3000/io?ms=50"
```

## Deploy

Web Function (the AWS CLI creates a default S3 bucket and execution role unless you pass `--bucket-name` and `--execution-role-arn`):

```bash
pnpm run build:web
aws lambda-web deploy --name hono-web --code dist --create --region eu-west-1
```

Classic Lambda with a public Function URL (`ROLE_ARN` is an execution role with basic Lambda permissions):

```bash
pnpm run build:lambda
aws lambda create-function --function-name hono-classic \
  --runtime nodejs24.x --architectures arm64 --handler index.handler \
  --memory-size 1024 --timeout 30 --role "$ROLE_ARN" \
  --zip-file fileb://dist-lambda.zip --region eu-west-1
aws lambda create-function-url-config --function-name hono-classic --auth-type NONE --region eu-west-1
aws lambda add-permission --function-name hono-classic --statement-id public-url \
  --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE --region eu-west-1
aws lambda add-permission --function-name hono-classic --statement-id public-url-invoke \
  --action lambda:InvokeFunction --principal '*' --invoked-via-function-url --region eu-west-1
```

A public endpoint can be called by anyone. Delete the functions when you're done.
