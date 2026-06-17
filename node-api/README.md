```{bash}
$ make log
docker logs -f node-api
s6-rc: info: service s6rc-oneshot-runner: starting
s6-rc: info: service s6rc-oneshot-runner successfully started
s6-rc: info: service fix-attrs: starting
s6-rc: info: service fix-attrs successfully started
s6-rc: info: service legacy-cont-init: starting
cont-init: info: running /etc/cont-init.d/50-api-init
[api-init] api.env criado em /config/api.env — edite para customizar
cont-init: info: /etc/cont-init.d/50-api-init exited 0
s6-rc: info: service legacy-cont-init successfully started
s6-rc: info: service legacy-services: starting
services-up: info: copying legacy longrun node-api (no readiness notification)
[node-api] iniciando na porta 3000
s6-rc: info: service legacy-services successfully started
[api] rodando em http://0.0.0.0:3000
```

```{bash}
$ make test-
test-create  test-health  test-list
$ make test-health
curl -s http://localhost:3000/health | python3 -m json.tool
{
    "status": "ok",
    "ts": "2026-06-17T07:28:36.851Z"
}
$ make test-create
curl -s -X POST http://localhost:3000/items \
	-H "Content-Type: application/json" \
	-d '{"name":"teste","value":"123"}' | python3 -m json.tool
{
    "id": 1
}
$ make test-list
curl -s http://localhost:3000/items | python3 -m json.tool
[
    {
        "id": 1,
        "name": "teste",
        "value": "123",
        "created_at": "2026-06-17 07:28:51"
    }
]
```

