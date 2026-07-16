% Private UI runtime helper. Expected caller: loadState. Inputs are a MAT-file
% path and current v2 definition. Outputs are a migrated complete project,
% optional resume data, and the preserved envelope. The reader inventories the
% file first and loads only one recognized trusted top-level variable.
function [project, resume, envelope] = readV2ProjectFile(filepath, def)
    details = whos('-file', filepath);
    inventory = string({details.name});
    recognized = intersect(inventory, ...
        ["labkitProject", "snapshot", legacyNames(def.project)]);
    if numel(recognized) ~= 1
        error('labkit:ui:runtime:UnknownProjectFormat', ...
            'Project file must contain exactly one recognized state variable.');
    end
    variable = recognized(1);
    loaded = load(filepath, variable);
    if variable == "labkitProject"
        envelope = loaded.labkitProject;
        [project, resume] = decodeCurrentEnvelope(envelope, def);
    elseif variable == "snapshot"
        [project, resume, envelope] = importSnapshot(loaded.snapshot, def);
    else
        [project, resume, envelope] = importLegacy( ...
            variable, loaded.(char(variable)), def);
    end
end

function [project, resume] = decodeCurrentEnvelope(envelope, def)
    requireScalarStruct(envelope, 'project envelope');
    required = ["format", "formatVersion", "app", "document", ...
        "producer", "sources", "payload"];
    requireFields(envelope, required, 'project envelope');
    if string(envelope.format) ~= "labkit.project"
        invalid('Unsupported project format.');
    end
    requireFields(envelope.formatVersion, ["major", "minor"], ...
        'formatVersion');
    if double(envelope.formatVersion.major) > 1
        error('labkit:ui:runtime:NewerProjectFormat', ...
            'Project format major version is newer than this LabKit reader.');
    end
    requireFields(envelope.app, ["id", "payloadVersion"], 'app');
    if string(envelope.app.id) ~= string(def.id)
        error('labkit:ui:runtime:WrongProjectApp', ...
            'Project app id "%s" does not match "%s".', ...
            string(envelope.app.id), string(def.id));
    end
    project = migratePayload(envelope.payload, ...
        double(envelope.app.payloadVersion), def.project);
    resume = struct();
    if isfield(envelope, 'resume') && isstruct(envelope.resume)
        resume = envelope.resume;
    end
end

function project = migratePayload(project, versionValue, spec)
    current = double(spec.Version);
    if ~isscalar(versionValue) || ~isfinite(versionValue) || ...
            versionValue < 1 || versionValue ~= fix(versionValue)
        invalid('Project payload version must be a positive integer.');
    end
    if versionValue > current
        error('labkit:ui:runtime:NewerProjectPayload', ...
            'Project payload version %d is newer than supported version %d.', ...
            versionValue, current);
    end
    migrations = optionValue(spec, 'Migrations', {});
    for version = versionValue:current - 1
        project = migrations{version}(project);
        validateSerializableState(project);
    end
end

function [project, resume, envelope] = importSnapshot(snapshot, def)
    requireScalarStruct(snapshot, 'snapshot');
    requireFields(snapshot, ["app", "state"], 'snapshot');
    if string(snapshot.app.id) ~= string(def.id)
        error('labkit:ui:runtime:WrongProjectApp', ...
            'Snapshot app id does not match the running app.');
    end
    state = snapshot.state;
    if isstruct(state) && isfield(state, 'project')
        project = state.project;
        resume = optionValue(state, 'session', struct());
    else
        project = state;
        resume = struct();
    end
    envelope = struct();
end

function [project, resume, envelope] = importLegacy(name, value, def)
    imports = def.project.LegacyImports;
    importer = imports.(char(name));
    outputCount = nargout(importer);
    if outputCount >= 2
        [project, resume] = importer(value);
    else
        project = importer(value);
        resume = struct();
    end
    envelope = struct();
end

function names = legacyNames(spec)
    names = strings(1, 0);
    if isfield(spec, 'LegacyImports') && isstruct(spec.LegacyImports)
        names = string(fieldnames(spec.LegacyImports)).';
    end
end

function requireScalarStruct(value, label)
    if ~isstruct(value) || ~isscalar(value)
        invalid('%s must be a scalar struct.', label);
    end
end

function requireFields(value, fields, label)
    requireScalarStruct(value, label);
    for k = 1:numel(fields)
        if ~isfield(value, fields(k))
            invalid('%s is missing field "%s".', label, fields(k));
        end
    end
end

function value = optionValue(spec, name, defaultValue)
    value = defaultValue;
    if isstruct(spec) && isfield(spec, name)
        value = spec.(name);
    end
end

function invalid(message, varargin)
    error('labkit:ui:runtime:InvalidProject', message, varargin{:});
end
