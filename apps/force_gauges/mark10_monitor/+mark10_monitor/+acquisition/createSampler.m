function sampler = createSampler(connectionBox, buffer, context, period)
%CREATESAMPLER Connect the Mark-10 event source to the App-owned buffer.
connection = connectionBox("connection");
consumer = @(updatedConnection, sample) ...
    mark10_monitor.acquisition.receiveSample( ...
    connectionBox, buffer, context, updatedConnection, sample);
sampler = labkit.mark10.startSampling(connection, period, consumer);
end
