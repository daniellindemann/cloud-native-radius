# Frequently asked questions

## Login for Azure Cloud not working because of network erroor

Error message example:

```
Building app.bicep...
Deploying template 'app.bicep' for application 'todolist' and environment '/planes/radius/local/resourcegroups/default/providers/Applications.Core/environments/default' from workspace 'default'...

Deployment In Progress... 

Error: {
  "code": "AuthenticationFailed",
  "message": "ClientSecretCredential authentication failed: Retry failed after 4 tries. Retry settings can be adjusted in ClientOptions.Retry or by configuring a custom retry policy in ClientOptions.RetryPolicy. (Network unreachable (login.microsoftonline.com:443)) (Network unreachable (login.microsoftonline.com:443)) (Network unreachable (login.microsoftonline.com:443)) (Network unreachable (login.microsoftonline.com:443))"
}

TraceId:  4da6a8528ee41af53dd8813df96f0afe
```

Solution:

It's because somewhere in the network chain a dns query tries to resolve to an IPv6 address.  
You can test it by connecting to radius deployment engine pod:

```bash
kubectl exec -n radius-system -it bicep-de-65b777f4dd-tclkl -- sh
wget -S -O /dev/null https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration
```

If you can an wget errror. It's not working:

```
Connecting to login.microsoftonline.com ([2603:1027:1:d8::5]:443)
wget: can't connect to remote host: Network unreachable
```

If it works, you get the HTML of the page.

**To resolve this error, disable IPv6 on you clients network adapter.**
