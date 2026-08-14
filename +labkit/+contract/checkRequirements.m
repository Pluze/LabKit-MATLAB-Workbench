function report = checkRequirements(req, versions)
%CHECKREQUIREMENTS Compare required API ranges with available LabKit versions.
%
% Usage:
%   report = labkit.contract.checkRequirements(req)
%   report = labkit.contract.checkRequirements(req, versions)
%
% Description:
%   Checks each requested facade in two ways: its current version must satisfy
%   the caller's range, and that range must overlap at least one compatibility
%   range advertised by the facade. When versions is omitted, the current app,
%   dta, rhs, biosignal, image, thermal, and mark10 version functions are
%   queried.
%
% Inputs:
%   req - Scalar structure returned by labkit.contract.requirements.
%   versions - Optional structure array returned by facade version functions
%       or versionInfo. Every element must contain name, current, compatible,
%       status, and notes. An optional facade field overrides the name used for
%       matching. This argument is mainly useful for diagnostics and tests.
%
% Outputs:
%   report - Scalar structure with ok, failures, and message fields. ok is
%       true when every requirement passes. message is a success sentence or
%       newline-separated failure text.
%
% Output Fields:
%   failures - Structure array with one element per failed requirement.
%   failures.facade - Normalized facade name.
%   failures.required - Range requested by the caller.
%   failures.available - Compatibility ranges advertised by the facade, or an
%       empty string array when the facade is unknown.
%   failures.message - Readable incompatibility explanation.
%
% Errors:
%   Throws labkit:contract:InvalidRequirements for a malformed req,
%   labkit:contract:InvalidVersionInfo for a malformed versions array,
%   labkit:contract:InvalidFacadeName for invalid names, and
%   labkit:contract:InvalidVersionRange when a version or constraint cannot be
%   parsed. Versions contain one to three numeric components, such as 6,
%   6.1, or 6.1.2.
%
% Example:
%   req = labkit.contract.requirements("thermal", ">=1.0 <2");
%   report = labkit.contract.checkRequirements(req);
%   if ~report.ok
%       warning("%s", report.message)
%   end
%
% See also labkit.contract.requirements,
%   labkit.contract.assertRequirements,
%   labkit.contract.versionInfo

    if nargin < 2 || isempty(versions)
        versions = currentFacadeVersions();
    end

    entries = normalizeRequirements(req);
    versions = normalizeVersions(versions);
    failures = repmat(struct('facade', "", 'required', "", ...
        'available', strings(0, 1), 'message', ""), numel(entries), 1);
    failureCount = 0;

    for k = 1:numel(entries)
        match = find([versions.facade] == entries(k).facade, 1);
        if isempty(match)
            failureCount = failureCount + 1;
            failures(failureCount, 1) = makeFailure(entries(k), strings(0, 1), ...
                sprintf('Unknown LabKit facade "%s".', entries(k).facade));
            continue;
        end

        advertised = versions(match).compatible;
        current = versions(match).current;
        if ~versionSatisfiesRange(current, entries(k).range)
            message = sprintf('labkit.%s current %s does not satisfy the app requirement %s. It advertises support for %s.', ...
                entries(k).facade, current, entries(k).range, ...
                strjoin(cellstr(advertised(:).'), ', '));
            failureCount = failureCount + 1;
            failures(failureCount, 1) = makeFailure(entries(k), advertised, message);
            continue;
        end
        if ~rangeIntersectsAny(entries(k).range, advertised)
            message = sprintf('labkit.%s current %s supports %s, but the app requires %s.', ...
                entries(k).facade, current, ...
                strjoin(cellstr(advertised(:).'), ', '), entries(k).range);
            failureCount = failureCount + 1;
            failures(failureCount, 1) = makeFailure(entries(k), advertised, message);
        end
    end
    failures = failures(1:failureCount);

    report = struct();
    report.ok = isempty(failures);
    report.failures = failures;
    if report.ok
        report.message = "All LabKit facade requirements are compatible.";
    else
        report.message = strjoin([failures.message], newline);
    end
end

function versions = currentFacadeVersions()
    versions = [
        labkit.app.version()
        labkit.dta.version()
        labkit.rhs.version()
        labkit.biosignal.version()
        labkit.image.version()
        labkit.thermal.version()
        labkit.mark10.version()];
end

function entries = normalizeRequirements(req)
    if ~(isstruct(req) && isfield(req, 'facades'))
        error('labkit:contract:InvalidRequirements', ...
            'Requirements must be returned by labkit.contract.requirements.');
    end
    entries = req.facades;
    requiredFields = ["facade", "range"];
    for k = 1:numel(requiredFields)
        if ~isfield(entries, requiredFields(k))
            error('labkit:contract:InvalidRequirements', ...
                'Requirement entries must include %s.', requiredFields(k));
        end
    end
    for k = 1:numel(entries)
        entries(k).facade = normalizeFacade(entries(k).facade);
        entries(k).range = normalizeRange(entries(k).range);
    end
end

function versions = normalizeVersions(versions)
    if ~isstruct(versions)
        error('labkit:contract:InvalidVersionInfo', ...
            'Facade versions must be a struct array.');
    end
    requiredFields = ["name", "current", "compatible", "status", "notes"];
    for k = 1:numel(requiredFields)
        if ~isfield(versions, requiredFields(k))
            error('labkit:contract:InvalidVersionInfo', ...
                'Facade version structs must include %s.', requiredFields(k));
        end
    end
    for k = 1:numel(versions)
        if isfield(versions, 'facade')
            versions(k).facade = normalizeFacade(versions(k).facade);
        else
            versions(k).facade = normalizeFacade(versions(k).name);
        end
        versions(k).current = normalizeVersionText(versions(k).current);
        versions(k).compatible = string(versions(k).compatible);
        versions(k).compatible = versions(k).compatible(:);
        versions(k).compatible = strtrim(versions(k).compatible);
        versions(k).compatible = versions(k).compatible(strlength(versions(k).compatible) > 0);
    end
end

function failure = makeFailure(entry, advertised, message)
    failure = struct();
    failure.facade = entry.facade;
    failure.required = entry.range;
    failure.available = advertised;
    failure.message = string(message);
end

function tf = versionSatisfiesRange(versionText, rangeText)
    version = parseVersion(versionText);
    range = parseRange(rangeText);
    tf = satisfiesLowerBound(version, range.lower) && ...
        satisfiesUpperBound(version, range.upper);
end

function tf = satisfiesLowerBound(version, bound)
    if isempty(bound.version)
        tf = true;
        return;
    end
    cmp = compareVersions(version, bound.version);
    if bound.exclusive
        tf = cmp > 0;
    else
        tf = cmp >= 0;
    end
end

function tf = satisfiesUpperBound(version, bound)
    if isempty(bound.version)
        tf = true;
        return;
    end
    cmp = compareVersions(version, bound.version);
    if bound.exclusive
        tf = cmp < 0;
    else
        tf = cmp <= 0;
    end
end

function tf = rangeIntersectsAny(requiredRange, advertisedRanges)
    required = parseRange(requiredRange);
    tf = false;
    for k = 1:numel(advertisedRanges)
        advertised = parseRange(advertisedRanges(k));
        if rangesIntersect(required, advertised)
            tf = true;
            return;
        end
    end
end

function tf = rangesIntersect(a, b)
    lower = strongerLowerBound(a.lower, b.lower);
    upper = strongerUpperBound(a.upper, b.upper);
    tf = lowerUpperAllowsOverlap(lower, upper);
end

function bound = strongerLowerBound(a, b)
    if isempty(a.version)
        bound = b;
    elseif isempty(b.version)
        bound = a;
    else
        cmp = compareVersions(a.version, b.version);
        if cmp > 0 || (cmp == 0 && a.exclusive)
            bound = a;
        else
            bound = b;
        end
    end
end

function bound = strongerUpperBound(a, b)
    if isempty(a.version)
        bound = b;
    elseif isempty(b.version)
        bound = a;
    else
        cmp = compareVersions(a.version, b.version);
        if cmp < 0 || (cmp == 0 && a.exclusive)
            bound = a;
        else
            bound = b;
        end
    end
end

function tf = lowerUpperAllowsOverlap(lower, upper)
    if isempty(lower.version) || isempty(upper.version)
        tf = true;
        return;
    end
    cmp = compareVersions(lower.version, upper.version);
    tf = cmp < 0 || (cmp == 0 && ~(lower.exclusive || upper.exclusive));
end

function range = parseRange(text)
    text = normalizeRange(text);
    tokens = split(text);
    tokens = tokens(strlength(tokens) > 0);
    range = struct();
    range.lower = emptyBound();
    range.upper = emptyBound();

    for k = 1:numel(tokens)
        token = tokens(k);
        [op, version] = parseConstraint(token);
        switch op
            case {">", ">="}
                range.lower = strongerLowerBound(range.lower, ...
                    struct('version', version, 'exclusive', op == ">"));
            case {"<", "<="}
                range.upper = strongerUpperBound(range.upper, ...
                    struct('version', version, 'exclusive', op == "<"));
            case {"=", "=="}
                exactLower = struct('version', version, 'exclusive', false);
                exactUpper = struct('version', version, 'exclusive', false);
                range.lower = strongerLowerBound(range.lower, exactLower);
                range.upper = strongerUpperBound(range.upper, exactUpper);
            otherwise
                error('labkit:contract:InvalidVersionRange', ...
                    'Unsupported version constraint "%s".', token);
        end
    end
end

function bound = emptyBound()
    bound = struct('version', [], 'exclusive', false);
end

function [op, version] = parseConstraint(token)
    token = strtrim(string(token));
    operators = [">=", "<=", "==", ">", "<", "="];
    for k = 1:numel(operators)
        candidate = operators(k);
        if startsWith(token, candidate)
            op = candidate;
            versionText = extractAfter(token, strlength(candidate));
            version = parseVersion(versionText);
            return;
        end
    end
    error('labkit:contract:InvalidVersionRange', ...
        'Version constraint "%s" must start with an operator.', token);
end

function version = parseVersion(text)
    text = normalizeVersionText(text);
    parts = split(text, ".");
    if numel(parts) > 3
        error('labkit:contract:InvalidVersionRange', ...
            'Version "%s" has too many components.', text);
    end
    version = zeros(1, 3);
    for k = 1:numel(parts)
        part = char(parts(k));
        if isempty(part) || any(~isstrprop(part, 'digit'))
            error('labkit:contract:InvalidVersionRange', ...
                'Version "%s" must contain numeric components.', text);
        end
        version(k) = str2double(part);
    end
end

function cmp = compareVersions(a, b)
    delta = a - b;
    first = find(delta ~= 0, 1);
    if isempty(first)
        cmp = 0;
    elseif delta(first) > 0
        cmp = 1;
    else
        cmp = -1;
    end
end

function facade = normalizeFacade(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:contract:InvalidFacadeName', ...
            'Facade names must be text scalars.');
    end
    facade = lower(strtrim(string(value)));
    if startsWith(facade, "labkit.")
        facade = extractAfter(facade, strlength("labkit."));
    end
end

function rangeText = normalizeRange(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:contract:InvalidVersionRange', ...
            'Version ranges must be text scalars.');
    end
    rangeText = strtrim(string(value));
    if strlength(rangeText) == 0
        error('labkit:contract:InvalidVersionRange', ...
            'Version ranges cannot be empty.');
    end
end

function text = normalizeVersionText(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:contract:InvalidVersionRange', ...
            'Version values must be text scalars.');
    end
    text = strtrim(string(value));
    if strlength(text) == 0
        error('labkit:contract:InvalidVersionRange', ...
            'Version values cannot be empty.');
    end
end
