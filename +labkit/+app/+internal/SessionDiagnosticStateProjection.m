classdef (Hidden, Sealed) SessionDiagnosticStateProjection
    %SESSIONDIAGNOSTICSTATEPROJECTION Prepare exact or compact diagnostic state.
    % RuntimeKernel and SessionDiagnosticBundle validate modes; the Bundle is
    % the sole project caller. Input and output are one scalar App state struct.
    % Compact mode preserves containers, field names, leaf classes, and array
    % dimensions while replacing large supported leaf values with deterministic
    % compressible data. It has no external side effects. The returned report
    % records structural state paths only and never includes replaced values.

    methods (Static)
        function [applicationState, report] = project(applicationState, mode)
            if ~isstruct(applicationState) || ~isscalar(applicationState)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Diagnostic App state must be one scalar struct.");
            end
            mode = ...
                labkit.app.internal.SessionDiagnosticStateProjection.validateMode( ...
                mode);
            replacements = emptyReplacements();
            retainedLargeValues = emptyRetainedLargeValues();
            if mode == "compact"
                [applicationState, replacements, retainedLargeValues] = ...
                    projectValue(applicationState, "applicationState", ...
                    replacements, retainedLargeValues);
            end
            report = struct( ...
                "schemaVersion", 1, ...
                "mode", mode, ...
                "largeValueThresholdBytes", compactThresholdBytes(), ...
                "replacementCount", numel(replacements), ...
                "replacements", replacements, ...
                "retainedLargeValueCount", numel(retainedLargeValues), ...
                "retainedLargeValues", retainedLargeValues);
        end

        function mode = validateMode(mode)
            mode = stateMode(mode);
        end
    end
end

function mode = stateMode(mode)
if ~(ischar(mode) || (isstring(mode) && isscalar(mode)))
    invalidMode();
end
mode = lower(string(mode));
if ~any(mode == ["exact", "compact"])
    invalidMode();
end
end

function invalidMode()
error("labkit:app:contract:InvalidValue", ...
    "Diagnostic state mode must be exact or compact.");
end

function [value, replacements, retained] = projectValue( ...
        value, path, replacements, retained)
if isstruct(value)
    names = fieldnames(value);
    for elementIndex = 1:numel(value)
        elementPath = indexedPath(path, elementIndex, numel(value), "(", ")");
        for fieldIndex = 1:numel(names)
            name = names{fieldIndex};
            childPath = elementPath + "." + string(name);
            [value(elementIndex).(name), replacements, retained] = ...
                projectValue(value(elementIndex).(name), childPath, ...
                replacements, retained);
        end
    end
    return
end
if iscell(value)
    for index = 1:numel(value)
        childPath = indexedPath(path, index, numel(value), "{", "}");
        [value{index}, replacements, retained] = projectValue( ...
            value{index}, childPath, replacements, retained);
    end
    return
end
if istable(value)
    names = string(value.Properties.VariableNames);
    for index = 1:numel(names)
        name = names(index);
        [value.(name), replacements, retained] = projectValue( ...
            value.(name), path + "." + name, replacements, retained);
    end
    return
end
originalBytes = valueBytes(value);
if originalBytes <= compactThresholdBytes()
    return
end
if ~isReplaceable(value)
    retained(end + 1, 1) = struct( ...
        "statePath", path, ...
        "valueClass", string(class(value)), ...
        "dimensions", double(size(value)), ...
        "originalBytes", double(originalBytes), ...
        "reason", "unsupported-value-type");
    return
end
replacement = syntheticValue(value);
record = struct( ...
    "statePath", path, ...
    "valueClass", string(class(value)), ...
    "dimensions", double(size(value)), ...
    "originalBytes", double(originalBytes), ...
    "replacement", "deterministic-compressible-placeholder");
replacements(end + 1, 1) = record;
value = replacement;
end

function path = indexedPath(path, index, count, opening, closing)
if count > 1
    path = path + opening + string(index) + closing;
end
end

function tf = isReplaceable(value)
tf = isnumeric(value) || islogical(value) || ischar(value) || isstring(value);
end

function value = syntheticValue(source)
if ischar(source)
    value = repmat('x', size(source));
elseif isstring(source)
    value = repmat("<synthetic>", size(source));
elseif issparse(source)
    value = sparse(size(source, 1), size(source, 2));
    if islogical(source)
        value = logical(value);
    end
else
    value = zeros(size(source), "like", source);
end
end

function bytes = valueBytes(value)
details = whos('value');
bytes = double(details.bytes);
end

function bytes = compactThresholdBytes()
bytes = 1024 * 1024;
end

function value = emptyReplacements()
value = repmat(struct( ...
    "statePath", "", ...
    "valueClass", "", ...
    "dimensions", zeros(1, 0), ...
    "originalBytes", 0, ...
    "replacement", ""), 0, 1);
end

function value = emptyRetainedLargeValues()
value = repmat(struct( ...
    "statePath", "", ...
    "valueClass", "", ...
    "dimensions", zeros(1, 0), ...
    "originalBytes", 0, ...
    "reason", ""), 0, 1);
end
