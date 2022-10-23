## Bastion Configuration

Bastion should be the only host in the entire infrastructure which has public IP address.  
The only purpose of this host is to provide SSH tunnel to other hosts.  
`provision_bastion` changes SSH port for this host to 22322.

All other `provision_*` tasks will use environment variable `ANSIBLE_SSH_COMMON_ARGS`. So you need to define it

`export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@<BASTION_IP> -p 22322"'`

### Socks Proxy

For working with the resources inside of cloud use SSH tunnel as a SOCKS proxy

```
ssh -D 1337 -f -C -q -N ubuntu@<BASTION_IP> -p 22322
```

For using socks5 proxy with local kubectl change kubeconfig

```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ...
    server: https://....:6443
    proxy-url: socks5://localhost:1337
  name: cluster.local
...
```