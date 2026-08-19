function mark10ServiceDrain(service)
% Drain worker batches and responses without waiting on the client thread.
if service("closed")
    return;
end
events = service("events");
while true
    value = poll(events, 0);
    if isempty(value)
        break;
    end
    mark10StoreState(service, "metadata", value.Metadata);
    switch string(value.Type)
        case "samples"
            consumer = service("consumer");
            if isempty(consumer)
                continue;
            end
            connection = mark10ServiceConnection(service);
            for index = 1:numel(value.Payload)
                consumer(connection, value.Payload{index});
            end
        otherwise
            responses = service("responses");
            mark10StoreState(responses, responseKey(value), value);
    end
end
end

function key = responseKey(value)
if string(value.Type) == "ready"
    key = "ready";
else
    key = char("request-" + string(value.RequestId));
end
end
