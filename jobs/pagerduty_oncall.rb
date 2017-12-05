require 'faraday'
require 'json'

url = ENV['PAGERDUTY_URL']
api_key = ENV['PAGERDUTY_APIKEY']
env_schedules = ENV['PAGERDUTY_SCHEDULES']
parsed_data = JSON.parse(env_schedules)

schedules = {}

parsed_data['schedules'].each do |key, value|
  schedules[key] = value
end

SCHEDULER.every '30s' do
  schedules.each do |key, value|
    conn = Faraday.new(url: "#{url}") do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-type'] = 'application/vnd.pagerduty+json;version=2'
      faraday.headers['Authorization'] = "Token token=#{api_key}"
      faraday.params['since'] = Time.now.utc.iso8601
      faraday.params['until'] = (Time.now.utc + 60).iso8601
    end

    response = conn.get "/schedules/#{value}/"
    if response.status == 200
      schedule_result = JSON.parse(response.body)
      user_name = schedule_result['entries'][0]['user']['name']
    else
      user_name = 'Shanthan Neelagiri'
    end

    send_event("#{key}-name", text: user_name)
  end
end
