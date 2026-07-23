function descriptors = catalog(varargin)
%CATALOG Discover and validate official LabKit test specifications.
%   DESCRIPTORS = labkittest.catalog discovers the test specifications under
%   tests/specs and returns one descriptor for each exact
%   matlab.unittest.Test identity.
%
%   DESCRIPTORS = labkittest.catalog(Owner=OWNER) limits discovery to a
%   path-derived test owner such as "apps/electrochem/cic/analysisRun".
%   OWNER must name a directory below tests/specs; it is never a substring
%   selector.
%
%   DESCRIPTORS = labkittest.catalog(Contract=CONTRACT) or
%   labkittest.catalog(Environment=ENVIRONMENT) filters validated descriptors
%   by their Contract:<name> or Env:<name> test tag. Legal contracts are
%   product, definition, source, scientific, state, persistence,
%   presentation, rendering, result, and system. Legal environments are
%   headless, hidden-gui, and isolated-process.
%
%   DESCRIPTORS = labkittest.catalog(SpecsRoot=FOLDER) discovers a separate
%   specification tree. This option is intended for framework self-tests and
%   isolated repositories; ordinary callers use the default tests/specs tree.
%
%   Each descriptor has Id, Owner, Contracts, Environment, and Test fields.
%   The Test field is the exact official test object that the executor runs.
%   Catalog validation rejects malformed owner paths, unknown metadata,
%   duplicate identities, and tests without exactly one Contract and Env tag.

    opts = parseOptions(varargin{:});
    labkittest.setup();
    root = normalizedFolder(opts.SpecsRoot);
    ownerFolder = ownerFolderFor(root, opts.Owner);
    suite = discoverSuite(ownerFolder);
    descriptors = descriptorsForSuite(suite, root);
    descriptors = filterDescriptors(descriptors, opts);
end

function opts = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkittest.catalog";
    p.addParameter("Owner", "", @isTextScalar);
    p.addParameter("Contract", "", @isTextScalar);
    p.addParameter("Environment", "", @isTextScalar);
    p.addParameter("SpecsRoot", defaultSpecsRoot(), @isFolderPath);
    p.parse(varargin{:});
    opts = p.Results;
    opts.Owner = normalizedOwner(opts.Owner);
    opts.Contract = normalizedMetadata(opts.Contract, legalContracts(), "Contract");
    opts.Environment = normalizedMetadata(opts.Environment, legalEnvironments(), "Environment");
end

function root = defaultSpecsRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fullfile(fileparts(fileparts(packageFolder)), "tests", "specs");
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isFolderPath(value)
    tf = isTextScalar(value) && exist(char(value), "dir") == 7;
end

function root = normalizedFolder(value)
    root = string(java.io.File(char(value)).getCanonicalPath());
    root = replace(root, "\\", "/");
    while endsWith(root, "/")
        root = extractBefore(root, strlength(root));
    end
    if ispc
        root = lower(root);
    end
end

function owner = normalizedOwner(value)
    owner = lower(strip(replace(string(value), "\\", "/")));
    if strlength(owner) == 0
        return;
    end
    parts = split(owner, "/");
    if any(parts == "" | parts == "." | parts == "..") || ...
            startsWith(owner, "/") || contains(owner, ":")
        error("LabKit:TestCatalog:InvalidOwner", ...
            "Owner must be a relative directory below tests/specs: %s.", owner);
    end
end

function value = normalizedMetadata(value, allowed, kind)
    value = lower(strip(string(value)));
    if strlength(value) == 0
        return;
    end
    if ~ismember(value, allowed)
        error("LabKit:TestCatalog:Unknown" + kind, ...
            "%s must be one of: %s.", kind, strjoin(allowed, ", "));
    end
end

function folder = ownerFolderFor(root, owner)
    if strlength(owner) == 0
        folder = root;
        return;
    end
    folder = fullfile(char(root), char(replace(owner, "/", filesep)));
    if exist(folder, "dir") ~= 7
        error("LabKit:TestCatalog:UnknownOwner", ...
            "No test specification owner exists at %s.", owner);
    end
end

function suite = discoverSuite(folder)
    suite = matlab.unittest.TestSuite.fromFolder(folder, ...
        "IncludingSubfolders", true, ...
        "InvalidFileFoundAction", "error");
end

function descriptors = descriptorsForSuite(suite, specsRoot)
    descriptors = repmat(emptyDescriptor(), 1, numel(suite));
    ids = strings(1, numel(suite));
    for k = 1:numel(suite)
        test = suite(k);
        [contracts, environment] = testMetadata(test);
        owner = ownerForTest(test, specsRoot);
        ids(k) = string(test.Name);
        descriptors(k) = struct( ...
            "Id", ids(k), ...
            "Owner", owner, ...
            "Contracts", contracts, ...
            "Environment", environment, ...
            "Test", test);
    end
    duplicateIds = ids(duplicated(lower(ids)));
    if ~isempty(duplicateIds)
        error("LabKit:TestCatalog:DuplicateIdentity", ...
            "Test specification identities must be unique: %s.", ...
            strjoin(unique(duplicateIds, "stable"), ", "));
    end
end

function descriptor = emptyDescriptor()
    descriptor = struct( ...
        "Id", "", ...
        "Owner", "", ...
        "Contracts", strings(1, 0), ...
        "Environment", "", ...
        "Test", matlab.unittest.Test.empty(1, 0));
end

function [contracts, environment] = testMetadata(test)
    tags = string(test.Tags);
    contractPrefix = "Contract:";
    environmentPrefix = "Env:";
    contractTags = tags(startsWith(tags, contractPrefix));
    environmentTags = tags(startsWith(tags, environmentPrefix));
    unexpected = tags(~startsWith(tags, [contractPrefix, environmentPrefix]));
    if numel(contractTags) ~= 1 || numel(environmentTags) ~= 1 || ...
            ~isempty(unexpected)
        error("LabKit:TestCatalog:InvalidMetadata", ...
            ["Each test must declare exactly one Contract:<name> and one " + ...
            "Env:<name> tag, with no other tags: %s."], test.Name);
    end
    contracts = lower(extractAfter(contractTags, contractPrefix));
    environment = lower(extractAfter(environmentTags, environmentPrefix));
    normalizedMetadata(contracts, legalContracts(), "Contract");
    normalizedMetadata(environment, legalEnvironments(), "Environment");
end

function owner = ownerForTest(test, specsRoot)
    baseFolder = normalizedFolder(test.BaseFolder);
    root = normalizedFolder(specsRoot);
    if baseFolder == root
        owner = "";
        return;
    end
    prefix = root + "/";
    if ~startsWith(baseFolder + "/", prefix)
        error("LabKit:TestCatalog:ExternalTest", ...
            "Test %s is outside the specification root.", test.Name);
    end
    owner = lower(extractAfter(baseFolder, strlength(prefix)));
end

function descriptors = filterDescriptors(descriptors, opts)
    if isempty(descriptors)
        return;
    end
    if strlength(opts.Contract) > 0
        descriptors = descriptors([descriptors.Contracts] == opts.Contract);
    end
    if ~isempty(descriptors) && strlength(opts.Environment) > 0
        descriptors = descriptors([descriptors.Environment] == opts.Environment);
    end
end

function values = legalContracts()
    values = ["product", "definition", "source", "scientific", "state", ...
        "persistence", "presentation", "rendering", "result", "system"];
end

function values = legalEnvironments()
    values = ["headless", "hidden-gui", "isolated-process"];
end

function mask = duplicated(values)
    [~, first] = unique(values, "stable");
    mask = true(size(values));
    mask(first) = false;
end
