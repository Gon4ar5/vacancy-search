require "uri"

module ApplicationHelper
  def safe_external_url(value)
    uri = URI.parse(value.to_s)
    uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end
