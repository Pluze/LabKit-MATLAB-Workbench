% Expected caller: Runtime V2 loading a Gait payload version 2. Input owns
% one source under the retired inputs.source field. Output moves the same
% record to the canonical inputs.sources collection without file IO.
function project = migrateProjectV2ToV3(project)
    project.inputs.sources = project.inputs.source;
    project.inputs = rmfield(project.inputs, 'source');
end
