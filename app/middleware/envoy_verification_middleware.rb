# Middleware to verify requests come through Envoy sidecar
# Blocks direct access to Rails API by requiring Envoy-specific headers
class EnvoyVerificationMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    # Allow health check endpoint without verification
    return @app.call(env) if request.path == "/up"

    # Check if request has Envoy verification header
    if envoy_request?(request)
      @app.call(env)
    else
      # Block direct access - return 403 Forbidden
      [
        403,
        { "Content-Type" => "application/json" },
        [ { error: "Forbidden: Direct access not allowed. Requests must go through Envoy sidecar." }.to_json ]
      ]
    end
  end

  private

  def envoy_request?(request)
    # Check for Envoy-specific header
    # This header is added by Envoy when forwarding requests
    request.headers["X-Internal-Secret"] == expected_secret ||
      # Fallback: Check for Envoy's standard headers
      request.headers["X-Envoy-Expected-Request-Id"].present? ||
      request.headers["X-Forwarded-For"].present?
  end

  def expected_secret
    # Get secret from credentials or environment variable
    Rails.application.credentials.dig(:envoy, :internal_secret) ||
      ENV.fetch("ENVOY_INTERNAL_SECRET", "default-secret-change-in-production")
  end
end
