Do you have a place where you have to create AWS IAM user credentials and use in your code? Do you have applications you aren't running in AWS but need the ability to
perform AWS API operations? 

This repo provide AWS credential providers that do some wrapping around the OIDC assume-role-with-web-identity-calls that AWS provides.

Now instead of creating IAM users directly, we can create identites directly in our IDP and use them as the credentials in our apps. Those identities can then
be authenticated against the IDP, and the resulting token exchanged to AWS to access an AWS role.

Why these libraries?

AWS provides the ability to do this out of the box, but the tools expect you to have a WebIdentityTokenFile written to disk and that file passed as an argument to 
the tools. This means you need an out of band process to update that file in the backend with new tokens periodically.

These libraries just thinly wrap that and instead keep the token in-process in memory, and refresh the token automatically as part of the credential refresh process
as needed.

The reality of this is you are trading the use of one set of hard coded credentials (AWS access key/secret key) for another (IDP client id/client secret). We prefer this
approach for a variety of reasons:

* Added logging/auditing of use in our IDP alongside our other identities
* Credential rotation only has to occur in the IDP, not the end application
* If the IDP credentials are leaked, they are much less useful to an attacker who likely will have no idea what they can be used for
* It follows along with our other tooling, like Github Actions OIDC auth
