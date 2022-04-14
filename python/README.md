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

Sample initialiazation:

```
from assume_role_oidc_client_credentials import AssumeRoleWithOIDCClientCredentialsProvider

import boto3.session
import botocore

sess = botocore.session.Session()

cc = botocore.credentials._get_client_creator(sess, "us-west-2")
p = AssumeRoleWithOIDCClientCredentialsProvider(cc, CLIENT_ID, CLIENT_SECRET, TOKEN_URL_ENDPOINT, ["CUSTOM_SCOPE"], AWS_ROLE_ARN)

cred_provider = sess.get_component('credential_provider')
cred_provider.insert_before('env', p)


boto3_session = boto3.session.Session(botocore_session=sess)
```

Upon credential refresh time, this will make the external call to the OIDC token provider and get the JWT needed for the
traditional AssumeRoleWithWebIdentity call. Then it does that call and populates the credentials.

Any error in the JWT refresh process raises the exception CredentialRetrievalError.
