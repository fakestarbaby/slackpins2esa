require 'slack-ruby-client'
require "esa"

Slack.configure do |config|
  config.token = ENV["SLACK_API_TOKEN"]
end
slack_client = Slack::Web::Client.new

puts "Get slack pins"

body_md = []
ENV["SLACK_CHANNEL_NAMES"].split(",").each do |channel_name|
  pins_list = slack_client.pins_list(channel: channel_name)

  body_md << ["## #{channel_name}\n\n"]
  pins_list.items.each do |pin|
    next if pin.type != "file"
    next unless pin.file.is_external?

    body_md << "- [#{pin.file.title}](#{pin.file.url_private})\n"
  end
  body_md << "\n\n"
end

puts "Post esa"

esa_client = Esa::Client.new(access_token: ENV["ESA_ACCESS_TOKEN"], current_team: ENV["ESA_CURRENT_TEAM"])
response = esa_client.posts(q: "name:#{ENV["ESA_POST_NAME"]} category:#{ENV["ESA_POST_CATEGORY"]}")
if response.body['total_count'] == 0
  puts "Create post"
  esa_client.create_post(
    category: ENV["ESA_POST_CATEGORY"],
    name: ENV["ESA_POST_NAME"],
    body_md: body_md.join
  )
else
  puts "Update post"
  post_number = response.body['posts'].first['number']
  esa_client.update_post(post_number,
    body_md: body_md.join
  )
end
