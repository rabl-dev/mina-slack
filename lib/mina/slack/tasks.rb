require 'json'
require 'net/http'


# Slack tasks
namespace :slack do
  desc 'Announcing deployment to Slack'
  task :starting do
    puts 'Starting Slack announcement'
    if slack_url && slack_room
      announcement = "#{announced_deployer} is deploying #{announced_application_name} to #{announced_stage}"

      post_slack_message(announcement)
      set(:start_time, Time.now)
    else
      print_local_status "Unable to create Slack Announcement, no slack details provided."
    end
  end

  desc 'Announcing finished deployment to Slack'
  task :finished do
    puts 'Finished Slack announcement'
    if slack_url && slack_room
      end_time = Time.now
      start_time = fetch(:start_time)
      elapsed = end_time.to_i - start_time.to_i

      announcement = "#{announced_deployer} successfully deployed #{announced_application_name} in #{elapsed} seconds."

      post_slack_message(announcement)
    else
      print_local_status "Unable to create Slack Announcement, no slack details provided."
    end
  end

  def announced_stage
    slack_stage
  end

  def announced_deployer
    deployer
  end

  def short_revision
    deployed_revision[0..7] if deployed_revision
  end

  def announced_application_name
    "".tap do |output|
      output << slack_application if slack_application
      output << " `#{branch}`" if branch
      output << " (`#{short_revision}`)" if short_revision
    end
  end

  def post_slack_message(message)
    # Parse the URI and handle the https connection
    uri = URI.parse(slack_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    payload = {
      "parse"       => "full",
      "channel"     => slack_room,
      "username"    => slack_username,
      "text"        => message,
      "icon_emoji"  => slack_emoji
    }

    # Create the post request and setup the form data
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(:payload => payload.to_json)

    # Make the actual request to the API
    http.request(request)
  end
end
