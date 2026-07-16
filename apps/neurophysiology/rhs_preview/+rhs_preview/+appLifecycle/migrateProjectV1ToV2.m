% Expected caller: Runtime V2 loading an RHS Preview payload version 1. Input
% owns three role-specific source fields. Output combines them into the
% canonical sources collection without changing record contents.
function project = migrateProjectV1ToV2(project)
    project.inputs.sources = [project.inputs.rhsSource, ...
        project.inputs.protocolSource, project.inputs.filterSources];
    project.inputs = rmfield(project.inputs, ...
        {'rhsSource', 'protocolSource', 'filterSources'});
end
