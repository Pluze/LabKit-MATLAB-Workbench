function report = appEvidence(app, varargin)
%APPEVIDENCE Audit one App's workflow and declared interaction evidence.
%   REPORT = labkittest.appEvidence(APP) inspects the compiled App definition
%   and its official specification owner. APP is one descriptor returned by
%   labkittest.publicApps. REPORT identifies App signals that no specification
%   drives through the test runtime and counts native workflow specifications.
%
%   REPORT = labkittest.appEvidence(APP, SpecsRoot=FOLDER) uses an alternate
%   specification tree. This supports private App repositories without making
%   their product inventory part of the public catalog.
%
%   This is an omission detector, not passing product evidence. Every declared
%   signal requires an exact runtime operation. The owning workflow must still
%   assert the user-visible outcome; source-name matching is not evidence that
%   callback behavior is correct.

opts = parseOptions(varargin{:});
validateApp(app);
owner = lower(replace(string(app.RelativeFolder), "\", "/"));
definition = feval(char(string(app.Package) + ".definition"));
plan = labkittest.inspectDefinition(definition);
source = specificationSource(opts.SpecsRoot, owner);
required = requiredInteractions(plan.Nodes, source);
try
    workflows = labkittest.catalog( ...
        Owner=owner + "/workbench", Contract="workflow", ...
        Environment="hidden-gui", SpecsRoot=opts.SpecsRoot);
catch exception
    if exception.identifier ~= "LabKit:TestCatalog:UnknownOwner"
        rethrow(exception)
    end
    workflows = repmat(struct("Id", ""), 1, 0);
end
report = struct( ...
    "App", string(app.Package), ...
    "Owner", owner, ...
    "WorkflowCount", numel(workflows), ...
    "WorkflowIds", string({workflows.Id}), ...
    "Interactions", required, ...
    "MissingInteractions", required(~[required.RuntimeCovered]), ...
    "MissingRuntimeInteractions", required(~[required.RuntimeCovered]));
end

function opts = parseOptions(varargin)
p = inputParser;
p.FunctionName = "labkittest.appEvidence";
p.addParameter("SpecsRoot", defaultSpecsRoot(), @isFolderPath);
p.parse(varargin{:});
opts = p.Results;
opts.SpecsRoot = string(opts.SpecsRoot);
end

function validateApp(app)
if ~isstruct(app) || ~isscalar(app) || ...
        ~isfield(app, "Package") || ~isfield(app, "RelativeFolder")
    error("LabKit:TestEvidence:InvalidApp", ...
        "App evidence requires one descriptor with Package and RelativeFolder.");
end
end

function source = specificationSource(specsRoot, owner)
folder = specsRoot;
for part = [split(owner, "/").' "workbench"]
    folder = fullfile(folder, part);
end
files = dir(fullfile(folder, "**", "*.m"));
source = "";
for index = 1:numel(files)
    source = source + newline + string(fileread( ...
        fullfile(files(index).folder, files(index).name)));
end
source = erase(source, "...");
source = regexprep(source, "\s+", "");
end

function values = requiredInteractions(nodes, source)
values = repmat(emptyInteraction(), 1, interactionCount(nodes));
valueIndex = 0;
for node = nodes
    for bindingCell = node.Signals
        binding = bindingCell{1};
        invocation = invocationFor(binding.Signal);
        runtimeCovered = containsInvocation( ...
            source, invocation, node.Id, binding.Signal);
        valueIndex = valueIndex + 1;
        values(valueIndex) = interaction(node.Id, binding.Signal, ...
            invocation, runtimeCovered);
    end
    if node.Kind ~= "plotArea" || ...
            ~isfield(node.Configuration, "Interactions")
        continue
    end
    for interactionCell = node.Configuration.Interactions
        spec = interactionCell{1};
        for bindingCell = spec.Signals
            binding = bindingCell{1};
            runtimeCovered = containsInvocation( ...
                source, "applyInteraction", spec.Id, binding.Signal);
            valueIndex = valueIndex + 1;
            values(valueIndex) = interaction(spec.Id, binding.Signal, ...
                "applyInteraction", runtimeCovered);
        end
    end
end
end

function count = interactionCount(nodes)
count = 0;
for node = nodes
    count = count + numel(node.Signals);
    if node.Kind ~= "plotArea" || ...
            ~isfield(node.Configuration, "Interactions")
        continue
    end
    for interactionCell = node.Configuration.Interactions
        count = count + numel(interactionCell{1}.Signals);
    end
end
end

function invocation = invocationFor(signal)
switch string(signal)
    case "pressed"
        invocation = "invokeAction";
    case "valueChanged"
        invocation = "applyControlValue";
    case "listSelectionChanged"
        invocation = "applyFileSelection";
    case "cellEdited"
        invocation = "applyTableEdit";
    case "cellSelectionChanged"
        invocation = "applyTableSelection";
    otherwise
        error("LabKit:TestEvidence:UnknownSignal", ...
            "No test-runtime operation owns the App signal: %s.", signal);
end
end

function tf = containsInvocation(source, invocation, target, signal)
targetTokens = [invocation + "(""" + target + """", ...
    invocation + "('" + target + "'"];
tf = any(contains(source, targetTokens));
if invocation ~= "applyInteraction"
    return
end
tokens = [ ...
    invocation + "(""" + target + """,""" + signal + """", ...
    invocation + "(""" + target + """,'" + signal + "'", ...
    invocation + "('" + target + "',""" + signal + """", ...
    invocation + "('" + target + "','" + signal + "'"];
tf = any(contains(source, tokens));
end

function value = interaction(target, signal, invocation, runtimeCovered)
value = struct( ...
    "Target", string(target), ...
    "Signal", string(signal), ...
    "Invocation", string(invocation), ...
    "RuntimeCovered", logical(runtimeCovered), ...
    "Covered", logical(runtimeCovered));
end

function value = emptyInteraction()
value = interaction("", "", "", false);
end

function root = defaultSpecsRoot()
packageFolder = fileparts(mfilename("fullpath"));
root = fullfile(fileparts(fileparts(packageFolder)), "tests", "specs");
end

function tf = isFolderPath(value)
tf = (ischar(value) || (isstring(value) && isscalar(value))) && ...
    exist(char(value), "dir") == 7;
end
