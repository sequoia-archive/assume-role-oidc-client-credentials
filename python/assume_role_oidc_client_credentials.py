import requests
import base64
#from requests_toolbelt.utils import dump
import logging
from copy import deepcopy 


from botocore.credentials import BaseAssumeRoleCredentialFetcher, CredentialProvider, AssumeRoleWithWebIdentityCredentialFetcher, DeferredRefreshableCredentials, Config, CredentialRetrievalError
from botocore import UNSIGNED

class WebIdentityTokenLoader(object):
    def __init__(self, client_id, client_secret, token_url, scopes):
        self._client_id = client_id
        self._client_secret = client_secret
        self._token_url = token_url
        self._scopes = scopes

    def __call__(self):
        auth_string = self._client_id + ":" + self._client_secret

        message_bytes = auth_string.encode('ascii')
        base64_bytes = base64.b64encode(message_bytes)
        base64_message = base64_bytes.decode('ascii')

        params = {'grant_type': 'client_credentials', 'scope': " ".join(self._scopes) }
        headers = {"Accept": "application/json",
                   "Authorization": "Basic " + base64_message,
                   "Content-Type": "application/x-www-form-urlencoded" }

        # Uncomment this to debug the request transaction
        #logging.basicConfig()
        #logging.getLogger().setLevel(logging.DEBUG)
        #requests_log = logging.getLogger("requests.packages.urllib3")
        #requests_log.setLevel(logging.DEBUG)
        #requests_log.propagate = True

        r = requests.post(self._token_url, params=params, headers=headers)
        if r.status_code != 200:
            raise CredentialRetrievalError(
                provider=self.method,
                error_msg="Error retrieving OIDC token",
            )

        return r.json()['access_token']


class AssumeRoleWithOIDCClientCredentialsProvider(CredentialProvider):
    METHOD = 'assume-role-with-web-identity'
    CANONICAL_NAME = None

    def __init__(
            self,
            client_creator,
            client_id,
            client_secret,
            token_url,
            scopes,
            role_arn,
            cache=None,
            token_loader_cls=None,
    ):
        self.cache = cache
        self._client_creator = client_creator
        self._client_id = client_id
        self._client_secret = client_secret
        self._token_url = token_url
        self._role_arn = role_arn
        self._scopes = scopes

        if token_loader_cls is None:
            token_loader_cls = WebIdentityTokenLoader
        self._token_loader_cls = token_loader_cls

    def load(self):
        print("hi")
        return self._assume_role_with_web_identity()

    def _assume_role_with_web_identity(self):
        token_loader = self._token_loader_cls(self._client_id, self._client_secret, self._token_url, self._scopes)

        role_arn = self._role_arn
        if not role_arn:
            error_msg = (
                'The provided profile or the current environment is '
                'configured to assume role with web identity but has no '
                'role ARN configured. Ensure that the profile has the role_arn'
                'configuration set or the AWS_ROLE_ARN env var is set.'
            )
            raise InvalidConfigError(error_msg=error_msg)

        extra_args = {}
        role_session_name = "role-session-name"
        if role_session_name is not None:
            extra_args['RoleSessionName'] = role_session_name

        fetcher = AssumeRoleWithWebIdentityCredentialFetcher(
            client_creator=self._client_creator,
            web_identity_token_loader=token_loader,
            role_arn=role_arn,
            extra_args=extra_args,
            cache=self.cache,
        )
        # The initial credentials are empty and the expiration time is set
        # to now so that we can delay the call to assume role until it is
        # strictly needed.
        return DeferredRefreshableCredentials(
            method=self.METHOD,
            refresh_using=fetcher.fetch_credentials,
        )
