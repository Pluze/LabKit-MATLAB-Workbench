classdef (Hidden, Sealed) SessionEventValidator
    %SESSIONEVENTVALIDATOR Validate and project private session event inputs.

    methods (Static)
        function values = logInputs(severity, eventName, message, ...
                category, audience, attributes, exception)
            values = struct( ...
                "severity", labkit.app.internal.diagnostics.SessionEventValidator.severity(severity), ...
                "eventName", labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                eventName, "eventName"), ...
                "message", labkit.app.internal.diagnostics.SessionEventValidator.privacySafeText( ...
                    message, "message"), ...
                "category", labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                category, "category"), ...
                "audience", labkit.app.internal.diagnostics.SessionEventValidator.audience(audience), ...
                "attributes", labkit.app.internal.diagnostics.SessionEventValidator.privacySafeAttributes( ...
                    attributes), ...
                "exception", labkit.app.internal.diagnostics.SessionEventValidator.exception(exception));
        end

        function value = semanticIdentifier(value, name)
            if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
                    strlength(strip(string(value))) == 0
                error("labkit:app:contract:InvalidValue", ...
                    "Session event %s must be nonempty scalar text.", name);
            end
            value = string(value);
            if isempty(regexp(char(value), "^[A-Za-z][A-Za-z0-9._-]*$", "once"))
                error("labkit:app:contract:InvalidValue", ...
                    "Session event %s must be a semantic identifier.", name);
            end
        end

        function value = severity(value)
            value = lower(labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                value, "severity"));
            if ~any(value == ["trace", "debug", "info", "warning", "error", "critical"])
                error("labkit:app:contract:InvalidValue", ...
                    "Unsupported log severity: %s.", value);
            end
        end

        function value = audience(value)
            value = lower(labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                value, "audience"));
            if ~any(value == ["user", "developer"])
                error("labkit:app:contract:InvalidValue", ...
                    "Session event audience must be user or developer.");
            end
        end

        function value = privacySafeText(value, name)
            if ~((ischar(value) && isrow(value)) || ...
                    (isstring(value) && isscalar(value))) || ...
                    ismissing(string(value))
                error("labkit:app:contract:InvalidValue", ...
                    "Session event %s must be scalar text.", name);
            end
            value = string(value);
            if strlength(value) > 512
                error("labkit:app:contract:InvalidValue", ...
                    "Session event %s exceeds the retained-text limit.", name);
            end
            if containsUnsafeAbsolutePath(value) || containsFilenameLikeLeaf(value)
                error("labkit:app:contract:UnsafeLogData", ...
                    "Session event %s must not contain a path or original filename.", name);
            end
        end

        function attributes = privacySafeAttributes(attributes)
            if ~isstruct(attributes) || ~isscalar(attributes)
                unsafeAttributeData("must be one scalar struct");
            end
            names = string(fieldnames(attributes));
            if numel(names) > maximumRetainedAttributeFieldCount()
                unsafeAttributeData("exceed the retained field limit");
            end
            for index = 1:numel(names)
                name = attributeKeyIdentifier(names(index), "key");
                value = attributes.(name);
                rejectSensitiveAttributeKey(name, value);
                if name == "dimensions"
                    attributes.(name) = validateDimensions(value);
                elseif isScalarText(value)
                    if ~any(name == retainedTextAttributeKeys())
                        unsafeAttributeData("only allow text for controlled semantic keys");
                    end
                    attributes.(name) = validateRetainedText(name, value);
                elseif isnumeric(value) || islogical(value)
                    if ~(isscalar(value) && isreal(value) && isfinite(double(value)))
                        unsafeAttributeData("must use finite scalar numeric or logical values");
                    end
                else
                    unsafeAttributeData("must not contain arrays, nested values, or MATLAB objects");
                end
            end
            attributes = orderfields(attributes);
            if isfield(attributes, "dimensions")
                attributes.dimensions = orderfields(attributes.dimensions);
            end
            dimensionAxes = 0;
            if isfield(attributes, "dimensions")
                dimensionAxes = numel(fieldnames(attributes.dimensions));
            end
            if numel(names) + dimensionAxes > maximumRetainedAttributeFieldCount()
                unsafeAttributeData("exceed the retained total field limit");
            end
            if utf8ByteCount(jsonencode(attributes)) > maximumRetainedAttributeJsonBytes()
                unsafeAttributeData("exceed the retained canonical JSON byte limit");
            end
        end

        function value = exception(value)
            if ~isempty(value) && (~isa(value, "MException") || ~isscalar(value))
                error("labkit:app:contract:InvalidValue", ...
                    "Session event Exception must be a scalar MException.");
            end
        end

        function terminal = terminalFields(operationResult, stateDisposition)
            operationResult = lower( ...
                labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                operationResult, "operationResult"));
            stateDisposition = lower( ...
                labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                stateDisposition, "stateDisposition"));
            if operationResult == "completed" && ...
                    any(stateDisposition == ["committed", "notapplicable"])
                terminal = struct("operationResult", "completed", ...
                    "stateDisposition", ternary(stateDisposition == "committed", ...
                    "committed", "notApplicable"));
            elseif operationResult == "failed" && ...
                    any(stateDisposition == ["rolledback", "notapplicable"])
                terminal = struct("operationResult", "failed", ...
                    "stateDisposition", ternary(stateDisposition == "rolledback", ...
                    "rolledBack", "notApplicable"));
            elseif operationResult == "abandoned" && stateDisposition == "unknown"
                terminal = struct("operationResult", "abandoned", ...
                    "stateDisposition", "unknown");
            else
                error("labkit:app:contract:InvalidValue", ...
                    "Session terminal result and state disposition are incompatible.");
            end
        end

        function tf = canonicalTerminalPair(operationResult, stateDisposition)
            if ~(ischar(operationResult) || ...
                    (isstring(operationResult) && isscalar(operationResult))) || ...
                    ~(ischar(stateDisposition) || ...
                    (isstring(stateDisposition) && isscalar(stateDisposition)))
                tf = false;
                return;
            end
            operationResult = string(operationResult);
            stateDisposition = string(stateDisposition);
            if strlength(operationResult) == 0 || strlength(stateDisposition) == 0
                tf = strlength(operationResult) == 0 && ...
                    strlength(stateDisposition) == 0;
                return;
            end
            try
                terminal = labkit.app.internal.diagnostics.SessionEventValidator.terminalFields( ...
                    operationResult, stateDisposition);
                tf = operationResult == terminal.operationResult && ...
                    stateDisposition == terminal.stateDisposition;
            catch
                tf = false;
            end
        end
    end
end

function value = ternary(condition, trueValue, falseValue)
if condition
    value = trueValue;
else
    value = falseValue;
end
end

function value = validateRetainedText(key, value)
if key == "unit"
    value = validateUnitToken(value);
elseif key == "sourceAlias"
    value = validateSourceAlias(value);
else
    value = retainedSemanticToken(value, "text value");
end
end

function value = validateUnitToken(value)
if ~isScalarText(value)
    unsafeAttributeData("unit must be one short controlled token");
end
value = string(value);
unitCharacters = [char(181), char(956), char(8486), char(176)];
factor = "[A-Za-z" + string(unitCharacters) + "]+(?:\^-?[1-9][0-9]*)?";
pattern = "^(1|%|a\.u\." + "|" + factor + "(?:[*/.]" + factor + ")*)$";
if strlength(value) > maximumRetainedSemanticTokenLength() || ...
        strlength(value) > maximumRetainedUnitTokenLength() || ...
        isempty(regexp(char(value), char(pattern), "once"))
    unsafeAttributeData("unit must be one short controlled token");
end
end

function value = validateSourceAlias(value)
if ~isScalarText(value)
    unsafeAttributeData("sourceAlias must use the framework source-N form");
end
value = string(value);
if strlength(value) > maximumRetainedSemanticTokenLength() || ...
        isempty(regexp(char(value), '^source-[1-9][0-9]*$', "once"))
    unsafeAttributeData("sourceAlias must use the framework source-N form");
end
end

function value = validateDimensions(value)
if ~isstruct(value) || ~isscalar(value)
    unsafeAttributeData("dimensions must be one fixed scalar object");
end
names = string(fieldnames(value));
if isempty(names) || numel(names) > maximumDimensionAxisCount()
    unsafeAttributeData("dimensions exceed the axis limit");
end
for index = 1:numel(names)
    name = attributeKeyIdentifier(names(index), "dimension axis");
    axisLength = value.(name);
    if ~(isnumeric(axisLength) && isreal(axisLength) && isscalar(axisLength) && ...
            isfinite(axisLength) && axisLength >= 1 && axisLength == fix(axisLength))
        unsafeAttributeData("dimension axes must be positive integer scalars");
    end
    value.(name) = double(axisLength);
end
end

function value = attributeKeyIdentifier(value, label)
if ~isScalarText(value)
    unsafeAttributeData(label + " must be scalar semantic text");
end
value = string(value);
if strlength(value) > maximumRetainedAttributeKeyLength() || ...
        isempty(regexp(char(value), '^[A-Za-z][A-Za-z0-9._-]*$', "once"))
    unsafeAttributeData(label + " must be a short semantic identifier");
end
end

function value = retainedSemanticToken(value, label)
if ~isScalarText(value)
    unsafeAttributeData(label + " must be scalar semantic text");
end
value = string(value);
if strlength(value) > maximumRetainedSemanticTokenLength() || ...
        isempty(regexp(char(value), '^[A-Za-z][A-Za-z0-9._-]*$', "once"))
    unsafeAttributeData(label + " must be a short semantic identifier");
end
end

function rejectSensitiveAttributeKey(key, value)
if any(key == retainedTextAttributeKeys()) || key == "dimensions"
    return;
end
normalized = lower(erase(key, [".", "_", "-"]));
if isSafeScalarFact(key, value)
    return;
end
forbiddenFragments = ["subject", "device", "serial", "sample", "signal", ...
    "path", "file", "name", "value", "data", "content", "metadata", ...
    "message", "freetext", "user", "identifier"];
if any(contains(normalized, forbiddenFragments)) || endsWith(normalized, "id")
    unsafeAttributeData("key denotes retained identity, content, or scientific data");
end
end

function tf = isSafeScalarFact(key, value)
tf = (isnumeric(value) || islogical(value)) && isreal(value) && isscalar(value) && ...
    isfinite(double(value)) && (key == "ordinal" || key == "count" || ...
    endsWith(key, ["Count", "Index", "DurationSeconds"]));
end

function keys = retainedTextAttributeKeys()
keys = ["enum", "unit", "reason", "runtimeAlias", "sourceAlias"];
end

function tf = isScalarText(value)
tf = (isstring(value) && isscalar(value) && ~ismissing(value)) || ...
    (ischar(value) && isrow(value));
end

function count = maximumRetainedAttributeFieldCount()
count = 16;
end

function count = maximumDimensionAxisCount()
count = 4;
end

function count = maximumRetainedAttributeKeyLength()
% R2022b truncates MATLAB identifiers after 63 characters. Attribute keys
% arrive as struct field names, so the portable contract cannot exceed that
% floor even when a newer MATLAB reports a larger namelengthmax.
count = 63;
end

function count = maximumRetainedSemanticTokenLength()
count = 64;
end

function count = maximumRetainedUnitTokenLength()
count = 24;
end

function count = maximumRetainedAttributeJsonBytes()
% Bound one fully validated canonical object before it reaches the ring/disk.
count = 1024;
end

function count = utf8ByteCount(value)
count = numel(unicode2native(char(string(value)), "UTF-8"));
end

function unsafeAttributeData(detail)
error("labkit:app:contract:UnsafeLogData", ...
    "Session event attributes %s.", detail);
end

function tf = containsUnsafeAbsolutePath(value)
text = char(value);
tf = containsWindowsDrivePath(text) || containsUncPath(text) || ...
    containsPosixAbsolutePath(text);
end

function tf = containsWindowsDrivePath(text)
tf = false;
for index = 1:max(0, strlength(string(text)) - 2)
    if isstrprop(text(index), "alpha") && text(index + 1) == ':' && ...
            isPathSeparator(text(index + 2)) && isPathTokenBoundary(text, index)
        tf = true;
        return;
    end
end
end

function tf = containsUncPath(text)
tf = false;
for index = 1:max(0, strlength(string(text)) - 2)
    if text(index) == char(92) && text(index + 1) == char(92) && ...
            isstrprop(text(index + 2), "alphanum") && ...
            isPathTokenBoundary(text, index)
        tf = true;
        return;
    end
end
end

function tf = containsPosixAbsolutePath(text)
tf = false;
for index = 1:max(0, strlength(string(text)) - 1)
    if text(index) == '/' && isstrprop(text(index + 1), "alphanum") && ...
            isPathTokenBoundary(text, index)
        tf = true;
        return;
    end
end
end

function tf = isPathSeparator(character)
tf = character == '/' || character == char(92);
end

function tf = isPathTokenBoundary(text, index)
tf = index == 1 || (~isstrprop(text(index - 1), "alphanum") && ...
    text(index - 1) ~= '_' && text(index - 1) ~= ':');
end

function tf = containsFilenameLikeLeaf(value)
extensions = [".csv", ".mat", ".json", ".txt", ".png", ".jpg", ...
    ".jpeg", ".tif", ".tiff", ".avi", ".xlsx", ".dta", ".rhs"];
text = char(lower(value));
tf = false;
for extension = extensions
    starts = strfind(text, char(extension));
    for startIndex = starts
        extensionEnd = startIndex + strlength(extension) - 1;
        hasLeafStem = startIndex > 1 && ...
            isstrprop(text(startIndex - 1), "alphanum");
        hasLeafBoundary = extensionEnd == strlength(string(text)) || ...
            ~isstrprop(text(extensionEnd + 1), "alphanum");
        if hasLeafStem && hasLeafBoundary
            tf = true;
            return;
        end
    end
end
end
