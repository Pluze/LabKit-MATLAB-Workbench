% Expected caller: Runtime V2 loading an ECG Print payload version 1. Input
% owns one source under inputs.source. Output moves the same record to the
% canonical inputs.sources collection without changing analysis parameters.
function project = migrateProjectV1ToV2(project)
    project.inputs.sources = project.inputs.source;
    project.inputs = rmfield(project.inputs, 'source');
end
