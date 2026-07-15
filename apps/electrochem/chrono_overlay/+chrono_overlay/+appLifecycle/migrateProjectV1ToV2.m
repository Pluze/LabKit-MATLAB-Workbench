% Expected caller: Runtime V2 project loading. Input is a version-1 Chrono
% Overlay payload. Output removes decoded DTA items so source records remain
% the sole durable input owner.
function project = migrateProjectV1ToV2(project)
    if isfield(project, 'inputs') && isfield(project.inputs, 'items')
        project.inputs = rmfield(project.inputs, 'items');
    end
end
