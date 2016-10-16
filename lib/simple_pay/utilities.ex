defmodule SimplePay.Utilities do
  alias Extreme.Messages, as: ExMsg

  def write_events(stream, events, expected_version) do
    proto_events = Enum.map(events, fn event ->
      ExMsg.NewEvent.new(
        event_id: event.guid,
        event_type: to_string(event.__struct__),
        data_content_type: 0,
        metadata_content_type: 0,
        data: :erlang.term_to_binary(event),
        meta: ""
      )
    end)

    ExMsg.WriteEvents.new(
      event_stream_id: stream,
      expected_version: expected_version, # http://docs.geteventstore.com/http-api/3.9.0/optional-http-headers/expected-version/
      events: proto_events,
      require_master: false # http://docs.geteventstore.com/http-api/3.9.0/optional-http-headers/requires-master/
    )
  end
end
