require "securerandom"
require "digest"
require "base64"

module Oauth
  class PkceHelper
    def self.generate_code_verifier_and_challenge
      code_verifier = Base64.urlsafe_encode64(SecureRandom.random_bytes(32)).gsub(/[^a-zA-Z0-9\-_.~]/, "")
      code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).gsub(/[^a-zA-Z0-9\-_.~]/, "")
      [code_verifier, code_challenge]
    end
  end
end