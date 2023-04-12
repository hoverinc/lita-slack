require 'thread'
require 'faraday'

require 'lita/adapters/slack/team_data'
require 'lita/adapters/slack/slack_im'
require 'lita/adapters/slack/slack_user'
require 'lita/adapters/slack/slack_source'
require 'lita/adapters/slack/slack_channel'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class API
        DEFAULT_PAGE_SIZE = 1000
        DEFAULT_RATE_LIMITED_WAIT_TIME = 65
        DEFAULT_MAX_RATE_LIMITED_WAIT_TIME = 600

        def initialize(config, stubs = nil)
          @config = config
          @stubs = stubs
          @post_message_config = {}
          @post_message_config[:parse] = config.parse unless config.parse.nil?
          @post_message_config[:link_names] = config.link_names ? 1 : 0 unless config.link_names.nil?
          @post_message_config[:unfurl_links] = config.unfurl_links unless config.unfurl_links.nil?
          @post_message_config[:unfurl_media] = config.unfurl_media unless config.unfurl_media.nil?
        end

        def im_open(user_id)
          response_data = call_api('conversations.open', users: user_id)

          SlackIM.new(response_data["channel"]["id"], user_id)
        end

        def channels_info(channel_id)
          call_api("channels.info", channel: channel_id)
        end

        def channels_list(params: {})
          conversations_list(types: ["public_channel"], params: params)
        end

        def groups_list(params: {})
          response = conversations_list(types: ["private_channel"], params: params)
          response['groups'] = response['channels']
          response
        end

        def mpim_list(params: {})
          response = conversations_list(types: ["mpim"], params: params)
          response['groups'] = response['channels']
          response
        end

        def im_list(params: {})
          response = conversations_list(types: ["im"], params: params)
          response['ims'] = response['channels']
          response
        end

        def conversations_list(types: ["public_channel"], params: {})
          params.merge!({
            types: types.join(',')
          })
          params[:limit] = DEFAULT_PAGE_SIZE unless params[:limit]
          call_paginated_api(method: 'conversations.list', params: params, result_field: 'channels')
        end

        def call_paginated_api(method:, params:, result_field:)
          Lita.logger.debug("Start #{method} paginated API call with parameters #{params}. Callers: #{caller.join(', ')}")

          page = 1
          result = call_api(
            method,
            params,
            page
          )

          next_cursor = fetch_cursor(result)
          old_cursor = nil
          page += 1
          while !next_cursor.nil? && !next_cursor.empty? && next_cursor != old_cursor
            old_cursor = next_cursor
            params[:cursor] = next_cursor
            next_page = call_api(
              method,
              params,
              page
            )
            next_cursor = fetch_cursor(next_page)
            result[result_field] += next_page[result_field]
            Lita.logger.debug("#{method} API call page #{page} obtained successfully (#{next_page[result_field].size} items returned)")
            page += 1
          end
          result
        end

        def send_attachments(room_or_user, attachments)
          call_api(
            "chat.postMessage",
            as_user: true,
            channel: room_or_user.id,
            attachments: MultiJson.dump(attachments.map(&:to_hash)),
          )
        end

        def open_dialog(dialog, trigger_id)
          call_api(
            "dialog.open",
            dialog: MultiJson.dump(dialog),
            trigger_id: trigger_id,
          )
        end

        def send_messages(channel_id, messages)
          call_api(
            "chat.postMessage",
            **post_message_config,
            as_user: true,
            channel: channel_id,
            text: messages.join("\n"),
          )
        end

        def reply_in_thread(channel_id, messages, thread_ts)
          call_api(
            "chat.postMessage",
            as_user: true,
            channel: channel_id,
            text: messages.join("\n"),
            thread_ts: thread_ts
          )
        end

        def delete(channel, ts)
          call_api("chat.delete", channel: channel, ts: ts)
        end

        def update_attachments(channel, ts, attachments)
          call_api(
            "chat.update",
            channel: channel,
            ts: ts,
            attachments: MultiJson.dump(attachments.map(&:to_hash))
          )
        end

        def set_topic(channel, topic)
          call_api("channels.setTopic", channel: channel, topic: topic)
        end

        def rtm_start
          Lita.logger.debug("Starting `rtm_connect` method")
          connect_response_data = call_api("rtm.connect")
          Lita.logger.debug("Started building TeamData")

          users_list_response_data = nil
          conversations_response_data = nil

          threads = []
          threads << Thread.new {
            users_list_response_data = users_list
          }
          threads << Thread.new {
            conversations_response_data = conversations_list(params: {exclude_archived: true})
          }
          threads.each(&:join)

          channels = conversations_response_data['channels'].select do |conversation|
            conversation['is_channel']
          end
          groups = conversations_response_data['channels'].select do |conversation|
            conversation['is_group']
          end
          ims = conversations_response_data['channels'].select do |conversation|
            conversation['is_im']
          end

          Lita.logger.debug("Obtained #{users_list_response_data["members"].size} users")
          Lita.logger.debug("Obtained #{channels.size} channels")
          Lita.logger.debug("Obtained #{groups.size} groups")
          Lita.logger.debug("Obtained #{ims.size} ims")

          team_data = TeamData.new(
            SlackIM.from_data_array(ims),
            SlackUser.from_data(connect_response_data["self"]),
            SlackUser.from_data_array(users_list_response_data["members"]),
            SlackChannel.from_data_array(channels) + SlackChannel.from_data_array(groups),
            connect_response_data["url"],
          )
          Lita.logger.debug("Finished building TeamData")
          Lita.logger.debug("Finishing method `rtm_connect`")
          team_data
        end

        private

        attr_reader :stubs
        attr_reader :config
        attr_reader :post_message_config

        def wait_for_rate_limit(response, method, retry_count, page = nil)
          default_rate_limited_wait_time = ENV.fetch("DEFAULT_RATE_LIMITED_WAIT_TIME", DEFAULT_RATE_LIMITED_WAIT_TIME).to_i
          default_max_rate_limited_wait_time = ENV.fetch("DEFAULT_MAX_RATE_LIMITED_WAIT_TIME", DEFAULT_MAX_RATE_LIMITED_WAIT_TIME).to_i

          request_type = 'non-paginated'
          request_type = "page #{page}" if page
          base_sleep_amount = response.headers.fetch('retry-after', default_rate_limited_wait_time).to_i
          sleep_amount = base_sleep_amount * retry_count
          topped_sleep_amount = [default_max_rate_limited_wait_time, sleep_amount].min
          rate_limiting_warning_message = "Rate-limited in #{request_type} #{method} request, retry #{retry_count}, will wait #{topped_sleep_amount} seconds"
          Lita.logger.info(rate_limiting_warning_message)

          sleep(topped_sleep_amount)
          sleep_amount
        end

        def call_api(method, post_data = {}, page = nil)
          request_type = 'non-paginated'
          request_type = "page #{page}" if page

          Lita.logger.debug("Starting #{request_type} #{method} request. Callers: #{caller.join(', ')}")

          url = "https://slack.com/api/#{method}"

          response = connection.post(
            url,
            { token: config.token }.merge(post_data)
          )
          retry_count = 1

          Lita.logger.debug("Finished #{request_type} request retry #{retry_count} to Slack API #{method} with HTTP status #{response.status}")

          while response.status == 429
            waited_time = wait_for_rate_limit(response, method, retry_count, page)
            Lita.logger.info("#{method} #{request_type} request retry #{retry_count} rate-limited, waited #{waited_time} seconds")
            Lita.logger.debug("Waited request Response body #{response.body}")

            response = connection.post(
              url,
              { token: config.token }.merge(post_data)
            )
            retry_count += 1
            Lita.logger.debug("Finished #{method} #{request_type} request retry #{retry_count} with HTTP status #{response.status}")
          end

          Lita.logger.debug("Obtained from #{method} #{request_type} request retry #{retry_count} a HTTP status #{response.status}")

          data = parse_response(response, method)
          Lita.logger.debug("Finished #{method} #{request_type} request retry #{retry_count} response")

          if data["error"]
            error_message = "Slack API #{request_type} #{method} request retry #{retry_count} returned an error: #{data["error"]}."
            log_to_sentry(error_message, url, post_data)
            Lita.logger.error(error_message)
            raise error_message
          else
            Lita.logger.debug("Successful #{request_type} #{method} request retry #{retry_count}")
          end

          Lita.logger.debug("#{method} #{request_type} request retry #{retry_count}. HTTP Status: #{response.status}. Body: '#{response.body}'. Headers: #{response.headers}.")

          data['__RESPONSE__'] = response
          data
        end

        def connection
          if stubs
            Faraday.new { |faraday| faraday.adapter(:test, stubs) }
          else
            options = {}
            unless config.proxy.nil?
              options = { proxy: config.proxy }
            end
            Faraday.new(options)
          end
        end

        def parse_response(response, method)
          unless response.status == 429 || response.success?
            raise "Slack API call to #{method} failed with status code #{response.status}: '#{response.body}'. Headers: #{response.headers}"
          end

          MultiJson.load(response.body)
        end

        def fetch_cursor(page)
          page.dig("response_metadata", "next_cursor")
        end

        def users_list
          call_paginated_api(method: 'users.list', params: {limit: DEFAULT_PAGE_SIZE}, result_field: 'members')
        end

        def log_to_sentry(message, url, post_data)
          require 'sentry-ruby'
          Sentry.capture_exception(
            StandardError.new(message),
            tags: {
              build_sha: ENV.fetch("GITLAB_COMMIT_SHA", ""),
              version: File.read(".semver"),
              trace_id: "no_trace_id",
              user: "unknown",
              lita_cmd: url
            },
            extra: {
              lita_cmd: url,
              maintainers: "Tools, #dev-tools for support",
              post_data: post_data
            }
          )
        end
      end
    end
  end
end
