# frozen_string_literal: true

require 'base64'
require 'rest_client'
require 'aws-sdk-core'

# See the README
# a role via {Aws::STS::Client#assume_role_with_web_identity}.
#
#     role_credentials = Aws::AssumeRoleOIDCClientCredentials.new(
#       client: Aws::STS::Client.new(...),
#       client_id: "client-id-string",
#       client_secret: "client-id-secret-string",
#       token_url: "https://token.url/v1/token",
#       scopes: ["customscope1"],
#       role_session_name: "session-name"
#       ...
#     )
#     For full list of parameters accepted
#     @see Aws::STS::Client#assume_role_with_web_identity
#
# If you omit `:client` option, a new {STS::Client} object will be
# constructed.
module Aws
    class AssumeRoleOIDCClientCredentials < Aws::AssumeRoleWebIdentityCredentials

    class TokenRetrievalError < RuntimeError; end

    # @param [Hash] options
    # @option options [required, String] :role_arn the IAM role
    #   to be assumed
    #
    # @option options [required, String] :client_id
    #   The OIDC app client id
    #
    # @option options [required, String] :client_secret
    #   The OIDC app client secret
    #
    # @option options [required, String] :token_url
    #   The OIDC URL to get the web identity token
    #
    # @option options [Array] :scopes
    #   An array of OIDC scopes to pass in to the token endpoint
    #
    # @option options [String] :role_session_name the IAM session
    #   name used to distinguish session, when not provided, base64
    #   encoded UUID is generated as the session name
    #
    # @option options [STS::Client] :client
    #
    # @option options [Callable] before_refresh Proc called before
    #   credentials are refreshed. `before_refresh` is called
    #   with an instance of this object when
    #   AWS credentials are required and need to be refreshed.
    def initialize(options = {})
        @client_id = options.delete(:client_id)
        @client_secret = options.delete(:client_secret)
        @token_url = options.delete(:token_url)
        @scopes = options.delete(:scopes)
        super
    end

    def inspect
        "#<#{self.class.name} client_id=#{@client_id.inspect}>"
    end

    private

    # Override the _token_from_file
    def _token_from_file(filename)
        _get_token
    end

    def _get_token
        #RestClient.log = STDOUT
        begin
            resp = RestClient.post(@token_url, 
                { grant_type: "client_credentials", scope: @scopes ? URI.encode_www_form(@scopes) : nil, },
                { accept: :json, "cache-control": "no-cache", "Authorization": "Basic " + Base64.strict_encode64(@client_id.to_s + ":" + @client_secret.to_s) }
            )

            if resp.code != 200
                raise TokenRetrievalError.new
            end

            return JSON.parse(resp.body)["access_token"]
        rescue RestClient::Unauthorized, RestClient::BadRequest, JSON::ParserError
            raise TokenRetrievalError.new
        end
    end

    end
end
