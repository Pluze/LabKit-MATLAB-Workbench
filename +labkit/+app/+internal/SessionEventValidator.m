classdef (Hidden, Sealed) SessionEventValidator
    %SESSIONEVENTVALIDATOR Validate privacy-safe private session event inputs.

    methods (Static)
        function values = logInputs(severity, eventName, message, ...
                category, audience, attributes, exception)
            values = struct( ...
                "severity", labkit.app.internal.SessionEventValidator.severity(severity), ...
                "eventName", labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
                eventName, "eventName"), ...
                "message", labkit.app.internal.SessionEventValidator.privacySafeText( ...
                message, "message"), ...
                "category", labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
                category, "category"), ...
                "audience", labkit.app.internal.SessionEventValidator.audience(audience), ...
                "attributes", labkit.app.internal.SessionEventValidator.privacySafeAttributes( ...
                attributes), ...
                "exception", labkit.app.internal.SessionEventValidator.exception(exception));
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
            value = lower(labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
                value, "severity"));
            if ~any(value == ["trace", "debug", "info", "warning", "error", "critical"])
                error("labkit:app:contract:InvalidValue", ...
                    "Unsupported log severity: %s.", value);
            end
        end

        function value = audience(value)
            value = lower(labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
                value, "audience"));
            if ~any(value == ["user", "developer"])
                error("labkit:app:contract:InvalidValue", ...
                    "Session event audience must be user or developer.");
            end
        end

        function value = privacySafeText(value, name)
            if ~(ischar(value) || (isstring(value) && isscalar(value)))
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
            if ~isstruct(attributes) || ~isscalar(attributes) || ...
                    numel(fieldnames(attributes)) > 16
                error("labkit:app:contract:InvalidValue", ...
                    "Session event attributes must be one bounded scalar struct.");
            end
            names = string(fieldnames(attributes));
            for index = 1:numel(names)
                name = labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
                    names(index), "attribute key");
                value = attributes.(name);
                if ischar(value) || (isstring(value) && isscalar(value))
                    attributes.(name) = ...
                        labkit.app.internal.SessionEventValidator.privacySafeText( ...
                        value, "attribute value");
                elseif isnumeric(value) || islogical(value)
                    if numel(value) > 16 || any(~isfinite(double(value)), "all")
                        error("labkit:app:contract:InvalidValue", ...
                            "Session event numeric attributes must be finite and bounded.");
                    end
                elseif isstruct(value) && isscalar(value)
                    attributes.(name) = ...
                        labkit.app.internal.SessionEventValidator.privacySafeAttributes(value);
                else
                    error("labkit:app:contract:InvalidValue", ...
                        "Session event attributes must use privacy-safe scalar values.");
                end
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
                labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
                operationResult, "operationResult"));
            stateDisposition = lower( ...
                labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
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
                terminal = labkit.app.internal.SessionEventValidator.terminalFields( ...
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
