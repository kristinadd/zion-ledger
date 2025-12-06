# Provides methods that automatically include the internal secret header
# required by EnvoyVerificationMiddleware
module ApiHelpers
  def api_post(path, params: {}, headers: {}, **options)
    post path,
         params: params,
         headers: internal_headers.merge(headers),
         as: :json,
         **options
  end

  def api_get(path, params: {}, headers: {}, **options)
    get path,
        params: params,
        headers: internal_headers.merge(headers),
        **options
  end

  private

  # Returns the headers required by EnvoyVerificationMiddleware
  def internal_headers
    { "X-Internal-Secret" => internal_secret }
  end

  # The secret value that matches what the middleware expects
  # Uses the same fallback as the middleware for consistency
  def internal_secret
    ENV.fetch("ENVOY_INTERNAL_SECRET", "zion-internal-secret-2024")
  end
end
