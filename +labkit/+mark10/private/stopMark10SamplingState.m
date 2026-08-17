function connection = stopMark10SamplingState(state)
% Stop one background sampler, flush its final batch, and retain the port.
if state("stopped")
    connection = state("connection");
    return;
end
state("stopped") = true;
deliveryTimer = state("timer");
if isa(deliveryTimer, "timer") && isvalid(deliveryTimer)
    try
        stop(deliveryTimer);
    catch
    end
    delete(deliveryTimer);
end
connection = state("connection");
service = state("service");
[~, ~] = mark10ServiceRequest(connection, "stop", struct());
mark10ServiceDrain(service);
service("consumer") = [];
connection = mark10ServiceConnection(service);
state("connection") = connection;
end
