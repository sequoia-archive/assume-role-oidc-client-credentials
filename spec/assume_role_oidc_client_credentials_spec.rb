# frozen_string_literal: true

require_relative 'spec_helper'
require 'aws-sdk-core'
require 'assume_role_oidc_client_credentials'

#Aws::AssumeRoleOIDCClientCredentials

module Aws
  describe AssumeRoleOIDCClientCredentials do

    let(:client) {
      STS::Client.new(
        region: 'us-west-2',
        credentials: credentials,
        stub_responses: true
      )
    }

    let(:in_one_hour) { Time.now + 60 * 60 }

    let(:expiration) { in_one_hour }

    let(:credentials) {
      double('credentials',
        access_key_id: 'akid',
        secret_access_key: 'secret',
        session_token: 'session',
        expiration: expiration,
      )
    }

    let(:client_id) {
      "12345678"
    }

    let(:client_secret) {
      "client-secret"
    }

    let(:token_url) {
      "https://token.url/v1/token"
    }

    let(:scopes) {
      ["awstest"]
    }

    let(:uuid) {
      "2d931510-d99f-494a-8c67-87feb05e1594"
    }

    let(:generate_name) {
      Base64.strict_encode64(uuid)
    }

    let(:resp_body) {
      '{"token_type":"Bearer","expires_in":3600,"access_token":"eyJraWQiOiJnemkzNlBVTmJQbjFSeHFQWnlyZnBtR000M0kxei1YS28xMklUaXA2emQ0IiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULjFFeTlRN00tYnZkWXA0Y0NBVFM3UUc5cEtla0ZKWmEyQUJhM1I5anpTdU0iLCJpc3MiOiJodHRwczovL3NlcXVvaWEub2t0YXByZXZpZXcuY29tL29hdXRoMi9hdXN5czk5N3d2bGJvVHo0WTBoNyIsImF1ZCI6ImF1ZHRlc3QiLCJpYXQiOjE2NDg2MDY1MzUsImV4cCI6MTY0ODYxMDEzNSwiY2lkIjoiMG9hMTZpdjZvOWRlNzNMYVEwaDgiLCJzY3AiOlsiYXdzdGVzdCJdLCJzdWIiOiIwb2ExNml2Nm85ZGU3M0xhUTBoOCIsInNvdXJjZV9pZGVudGl0eSI6IjBvYTE2aXY2bzlkZTczTGFRMGg4In0.Cy_nAjHaYPYdZ6Nb96qCeHtqoI93mBv19rMNW0J9JMzIg1WFD1Vik_QoLKrobG97_veogBTKz0cGp5vedyHxB22rBJMkKmfL5I6WgrBENbqGgTaALSfEbmXzjEOqthwVL5VWv6R9HugHhlAUyr_mmoxCewFjz3VBf1KU5faawPMHF5iRmNGGsqQpRAqD0oZr7J4q-6qgoAhJZO7cm4wkjBsu5qaO_sTRVnEz0ZbWnwdmoqwMWjPMenoD6cbC9ehcuK08kE62m4QovA-CJkIfXMQp7qUAdseVMqixxkJtO90p3mgOXjqK_zwiziVn-qv97ZG1hL0oZKZ0-FM__3m-eQ","scope":"awstest"}'
    }

    let(:resp) {double('client-resp', credentials: credentials)}

    before(:each) do
      allow(STS::Client).to receive(:new).and_return(client)
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      allow(client).to receive(:assume_role_with_web_identity).and_return(resp)
      stub_request(:post, token_url).to_return(status: 200, body: resp_body)
    end

    it 'properly creates an STS client with assume_role_with_web_identity' do
      expect(client).to receive(:assume_role_with_web_identity).with({
        role_arn: 'arn',
        web_identity_token: JSON(resp_body)["access_token"],
        role_session_name: "session-name"
      })
      AssumeRoleOIDCClientCredentials.new(
        role_arn: 'arn',
        client_id: client_id,
        client_secret: client_secret,
        token_url: token_url,
        scopes: scopes, 
        role_session_name: "session-name"
      )
    end

    context 'token url returns a non-200 status code' do
      before do 
        stub_request(:post, token_url).to_return(status: 401, body: resp_body)
      end

      it 'raises an exception' do
        expect { 
          Aws::AssumeRoleOIDCClientCredentials.new(
          role_arn: 'arn',
          client_id: client_id,
          client_secret: client_secret,
          token_url: token_url,
          scopes: scopes,
          role_session_name: "session-name"
        )
        }.to raise_error(AssumeRoleOIDCClientCredentials::TokenRetrievalError)
      end
    end
  end
end


=begin
    it 'auto populates :session_name when not provided' do
      expect(client).to receive(:assume_role_with_web_identity).with({
        role_arn: 'arn',
        web_identity_token: '',
        role_session_name: generate_name
      })
      AssumeRoleWebIdentityCredentials.new(
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
      )
    end

    it 'populates :web_identity_token from file when valid' do
      expect {
        AssumeRoleWebIdentityCredentials.new(
          role_arn: 'arn')
      }.to raise_error(Aws::Errors::MissingWebIdentityTokenFile)
      expect {
        AssumeRoleWebIdentityCredentials.new(
          role_arn: 'arn',
          web_identity_token_file: '/not/exist/file/foo',
        )
      }.to raise_error(Aws::Errors::MissingWebIdentityTokenFile)

      token_file.write('token')
      token_file.flush
      token_file.close

      expect(client).to receive(:assume_role_with_web_identity).with({
        role_arn: 'arn',
        web_identity_token: 'token',
        role_session_name: "session-name"
      })
      AssumeRoleWebIdentityCredentials.new(
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
        role_session_name: "session-name"
      )
    end

    it 'accepts a client' do
      creds = AssumeRoleWebIdentityCredentials.new(
        client: client,
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
      )
      expect(creds.client).to be(client)
    end

    it 'accepts client options' do
      expected_client = STS::Client.new(
        credentials: false, stub_responses: true)
      expect(STS::Client).to receive(:new).
        with({region: 'region-name', credentials: false}).
        and_return(expected_client)
      creds = AssumeRoleWebIdentityCredentials.new(
        region: 'region-name',
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
      )
      expect(creds.client).to be(expected_client)
    end

    it 'assumes role with web identity using the client' do
      expect(client).to receive(:assume_role_with_web_identity).with({
        role_arn: 'arn',
        web_identity_token: '',
        role_session_name: "session-name",
        provider_id: "urlType",
        policy: "sessionPolicyDocumentType"
      })
      AssumeRoleWebIdentityCredentials.new(
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
        role_session_name: "session-name",
        provider_id: "urlType",
        policy: "sessionPolicyDocumentType"
      )
    end

    it 'extracts credentials from response' do
      c = AssumeRoleWebIdentityCredentials.new(
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
      )
      expect(c).to be_set
      expect(c.credentials.access_key_id).to eq('akid')
      expect(c.credentials.secret_access_key).to eq('secret')
      expect(c.credentials.session_token).to eq('session')
      expect(c.expiration).to eq(in_one_hour)
    end

    it 'refreshes asynchronously' do
      # expiration 6 minutes out, within the async exp time window
      allow(credentials).to receive(:expiration).and_return(Time.now + (6*60))
      expect(client).to receive(:assume_role_with_web_identity).exactly(2).times
      expect(File).to receive(:read).with(token_file_path).exactly(2).times
      expect(Thread).to receive(:new).and_yield

      c = AssumeRoleWebIdentityCredentials.new(
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
        role_session_name: 'session')
      c.credentials
    end

    it 'auto refreshes credentials when near expiration' do
      allow(credentials).to receive(:expiration).and_return(Time.now)
      expect(client).to receive(:assume_role_with_web_identity).exactly(4).times
      expect(File).to receive(:read).with(token_file_path).exactly(4).times

      c = AssumeRoleWebIdentityCredentials.new(
        role_arn: 'arn',
        web_identity_token_file: token_file_path,
        role_session_name: 'session')
      c.credentials
      c.credentials
      c.credentials
    end
=end
