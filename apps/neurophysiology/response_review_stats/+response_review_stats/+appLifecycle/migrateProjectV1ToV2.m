% Expected caller: Runtime V2 loading a Response Review Stats payload version
% 1. Input owns one source under inputs.source. Output moves the same record to
% canonical inputs.sources without changing parameters or result references.
function project = migrateProjectV1ToV2(project)
    project.inputs.sources = project.inputs.source;
    project.inputs = rmfield(project.inputs, 'source');
end
