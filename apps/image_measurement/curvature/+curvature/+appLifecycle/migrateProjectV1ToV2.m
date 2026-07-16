% Expected caller: Runtime V2 loading a Curvature payload version 1. Input
% owns one source under inputs.source. Output moves the same record to the
% canonical inputs.sources collection without changing annotations/results.
function project = migrateProjectV1ToV2(project)
    project.inputs.sources = project.inputs.source;
    project.inputs = rmfield(project.inputs, 'source');
end
