require 'lita/adapters/slack/chat_service'
require 'lita/adapters/slack/rtm_connection'
require 'net/http'

module Lita
  module Adapters
    # A Slack adapter for Lita.
    # @api private
    class Slack < Adapter
      # Required configuration attributes.
      config :token, type: String, required: true
      config :proxy, type: String
      config :parse, type: [String]
      config :link_names, type: [true, false]
      config :unfurl_links, type: [true, false]
      config :unfurl_media, type: [true, false]

      # Provides an object for Slack-specific features.
      def chat_service
        ChatService.new(config)
      end

      def mention_format(name)
        "@#{name}"
      end

      # Starts the connection.
      def run(&block)
        return if rtm_connection
        Lita.logger.debug("Starting to build RTM connection")
        @rtm_connection = RTMConnection.build(robot, config)

        Lita.logger.debug("Done building RTM connection")

        lita_ssl_verification = ENV.fetch("LITA_SLACK_WS_CONNECTION_VERIFY_SSL", "true") == "true"
        unless lita_ssl_verification
          Lita.logger.info("SLL connection is going to be verified by Net::HTTP and OpenSSL")
          verify_ssl_connection
        end

        rtm_connection.run(nil, { tls: { verify_peer: lita_ssl_verification }  }, &block)
      end



      # Returns UID(s) in an Array or String for:
      # Channels, MPIMs, IMs
      def roster(target)
        api = API.new(config)
        room_roster target.id, api
      end

      # @param [Array] messages list of String messages
      # messages starting with the ellipsis character will start a new thread
      def send_messages(target, messages)
        api = API.new(config)
        channel = channel_for(target)

        timestamp = target.timestamp if target.respond_to?(:timestamp)
        thread_ts = target.thread_ts if target.respond_to?(:thread_ts)

        if messages[0] && messages[0][0] == '…'
          thread_ts = timestamp
          messages[0] = messages[0][1..-1]
        end

        if thread_ts
          api.reply_in_thread(channel, messages, thread_ts)
        else
          api.send_messages(channel, messages)
        end
      end

      def set_topic(target, topic)
        channel = target.room
        Lita.logger.debug("Setting topic for channel #{channel}: #{topic}")
        API.new(config).set_topic(channel, topic)
      end

      def shut_down
        return unless rtm_connection

        rtm_connection.shut_down
        robot.trigger(:disconnected)
      end

      private

      attr_reader :rtm_connection

      def channel_for(target)
        if target.private_message?
          rtm_connection.im_for(target.user.id)
        else
          target.room
        end
      end

      def channel_roster(room_id, api)
        response = api.channels_info room_id
        response['channel']['members']
      end

      # Returns the members of a group, but only can do so if it's a member
      def group_roster(room_id, api)
        response = api.groups_list
        group = response['groups'].select { |hash| hash['id'].eql? room_id }.first
        group.nil? ? [] : group['members']
      end

      # Returns the members of a mpim, but only can do so if it's a member
      def mpim_roster(room_id, api)
        response = api.mpim_list
        mpim = response['groups'].select { |hash| hash['id'].eql? room_id }.first
        mpim.nil? ? [] : mpim['members']
      end

      # Returns the user of an im
      def im_roster(room_id, api)
        response = api.mpim_list
        im = response['ims'].select { |hash| hash['id'].eql? room_id }.first
        im.nil? ? '' : im['user']
      end

      def room_roster(room_id, api)
        case room_id
        when /^C/
          channel_roster room_id, api
        when /^G/
          # Groups & MPIMs have the same room ID pattern, check both if needed
          roster = group_roster room_id, api
          roster.empty? ? mpim_roster(room_id, api) : roster
        when /^D/
          im_roster room_id, api
        end
      end

      def verify_ssl_connection(host = "wss-primary.slack.com", max_retries = 10, wait_time = 5)
        ok = false
        ssl_retry = 0
        while !ok && ssl_retry < max_retries
          begin
            Net::HTTP.start(host, '443', use_ssl: true) { |http| http.peer_cert }
            Lita.logger.info("SSL connection is verified")
            ok = true
          rescue OpenSSL::SSL::SSLError => e
            Lita.logger.info("SSL connection is not verified. Retry #{ssl_retry+1}. Error: #{e.message}. Backtrace: #{e.backtrace}")
            raise if ssl_retry == max_retries
            ok = false
            sleep(wait_time)
          end
        end
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
