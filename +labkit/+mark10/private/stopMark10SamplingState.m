function connection = stopMark10SamplingState(state)
% Stop one Base MATLAB sampler and retain the serial connection.
if state("stopped")
    connection = state("connection");
    return;
end
state("stopped") = true;
samplingTimer = state("timer");
if isa(samplingTimer, "timer") && isvalid(samplingTimer)
    try
        stop(samplingTimer);
    catch
    end
    delete(samplingTimer);
end
connection = state("connection");
state("consumer") = [];
state("connection") = connection;
end
