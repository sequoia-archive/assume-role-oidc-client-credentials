An AWS credential provider for doing OIDC authentication to an AWS role.

AWS provides the AssumeRoleWithWebIdentityCredentials provider, which requires a file containing a JWT
to be provided that the API uses to trade for AWS STS credentials. However, *something* has to populate 
the JWT into that file.

This provider is a thin wrapper around that, where we specify some OIDC parameters and let the
class dymamically grab the JWT from the OIDC token endpoint, instead of having to do it in the
background.

This is tested again Okta, but will likely work against any OIDC provider. Each one seems to have
slightly different argument requirements to their token endpoint, so small tweak may be necessary.

Create an okta OIDC application that uses the client_credentials flow. You will get a client id and a client secret.

You will also need an authorization server that defines at least a single custom scope.

Initalize the credentials:

```
      AssumeRoleOIDCClientCredentials.new(
        role_arn: 'arn',
        client_id: YOUR_CLIENT_ID,
        client_secret: YOUR_CLIENT_SECRET,
        token_url: YOUR_AUTHORIZATION_SERVER_TOKEN_URL,
        scopes: YOUR_OIDC_SCOPES,
        role_session_name: "session-name"
      )
```

Upon credential refresh time, this will make the external call to the OIDC token provider and get the JWT needed for the
traditional AssumeRoleWithWebIdentity call. Then it does that call and populates the credentials.

Any error in the JWT refresh process raises the exception AssumeRoleOIDCClientCredentials::TokenRetrievalError.
