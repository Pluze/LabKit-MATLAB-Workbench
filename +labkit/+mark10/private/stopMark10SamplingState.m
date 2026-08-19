function connection = stopMark10SamplingState(state)
% Stop one background sampler, flush its final batch, and retain the port.
if state("stopped")
    connection = state("connection");
    return;
end
mark10StoreState(state, "stopped", true);
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
try
    mark10ServiceRequest(connection, "stop", struct());
    mark10ServiceDrain(service);
catch cause
    mark10StoreState(service, "consumer", []);
    rethrow(cause);
end
mark10StoreState(service, "consumer", []);
connection = mark10ServiceConnection(service);
mark10StoreState(state, "connection", connection);
end
