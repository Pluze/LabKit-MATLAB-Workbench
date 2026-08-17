function value = mark10ServiceAwait(service, key, timeout)
% Wait for one driver response while continuing to route sample batches.
key = char(string(key));
started = tic;
while toc(started) < timeout
    mark10ServiceDrain(service);
    responses = service("responses");
    if isKey(responses, key)
        value = responses(key);
        remove(responses, key);
        if string(value.Type) == "failure"
            failure = value.Payload{1};
            error(char(failure.Identifier), "%s", failure.Message);
        end
        return;
    end
    future = service("future");
    if string(future.State) == "finished"
        fetchOutputs(future);
        error("labkit:mark10:ConnectionFailed", ...
            "Mark-10 background service ended unexpectedly.");
    end
    pause(0.001);
end
error("labkit:mark10:ConnectionFailed", ...
    "Timed out waiting for the Mark-10 background service.");
end
