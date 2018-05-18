# responsible for safely parsing json
class SafeJsonParser
  def self.parse(json, default_value = nil)
    return default_value unless json.is_a?(String)
    JSON.parse(json)
  rescue JSON::ParserError
    default_value
  end
end
