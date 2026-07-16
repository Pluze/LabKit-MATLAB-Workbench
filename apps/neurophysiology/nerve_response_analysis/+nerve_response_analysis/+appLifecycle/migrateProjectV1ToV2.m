% Expected caller: Runtime V2 loading a Nerve Response Analysis version 1
% payload. Output combines the filter/protocol fields into canonical sources
% without changing either record.
function project = migrateProjectV1ToV2(project)
    project.inputs.sources = [project.inputs.filterSource, ...
        project.inputs.protocolSource];
    project.inputs = rmfield(project.inputs, ...
        {'filterSource', 'protocolSource'});
end
