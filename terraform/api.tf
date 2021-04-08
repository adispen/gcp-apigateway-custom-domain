resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = "api"
}

resource "google_api_gateway_gateway" "api_gateway" {
  provider   = google-beta
  gateway_id = "api-gateway"
  api_config = google_api_gateway_api_config.api_config.name
}

resource "google_api_gateway_api_config" "api_config" {
  provider             = google-beta
  api                  = google_api_gateway_api.api.api_id
  api_config_id_prefix = "api-config"

  openapi_documents {
    document {
      path     = "spec.yaml"
      contents = filebase64("openapi.yaml")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}