classdef (Sealed) Definition
    %DEFINITION Compile and launch one immutable App SDK contract.
    %
    % Usage:
    %   app = labkit.app.Definition(Entrypoint=entrypoint, AppId=appId, ...
    %       Title=title, ...
    %       Family=family, AppVersion=version, Updated=date, ...
    %       Requirements=requirements, Workbench=workbench, Name=Value)
    %   fig = app.launch()
    %   fig = app.launch(InitialProject=project)
    %   fig = app.launch(Diagnostics=diagnosticOptions)
    %   requirements = app.launch("requirements")
    %   version = app.launch("version")
    %
    % Description:
    %   Definition validates product metadata, layout-owned callbacks and
    %   renderers, global IDs, callback roles, and references in one atomic
    %   constructor. The static
    %   target graph is cached once. validateViewSnapshot checks a complete
    %   view snapshot against that graph without rebuilding the layout.
    %
    % Required Name-Value Arguments:
    %   Entrypoint - Public MATLAB launch function name as a scalar identifier.
    %   AppId - Stable App identifier beginning with an ASCII letter and
    %       containing letters, digits, underscore, hyphen, or period.
    %   Title - Nonempty reader-facing scalar text.
    %   Family - Nonempty reader-facing scalar text.
    %   AppVersion - Semantic version in X.Y.Z form.
    %   Updated - Product date in YYYY-MM-DD form.
    %   Requirements - Empty value or labkit.contract.requirements result.
    %   Workbench - Root value returned by labkit.app.layout.workbench.
    %
    % Optional Name-Value Arguments:
    %   DisplayName - Nonempty scalar text. Default: Title.
    %   ProjectSchema - labkit.app.project.Schema or empty for a static App.
    %       Default: empty.
    %   CreateSession - Fixed callback session = callback(project,context).
    %       Portable project sources remain opaque; use
    %       context.resolveSourcePaths
    %       while rebuilding transient session data. Default: empty.
    %   PresentWorkbench - Fixed callback view = callback(state). Default:
    %       empty.
    %   OnStart - Fixed callback state = callback(state,context), invoked
    %       after the first view commit. Default: empty.
    %   BuildDebugSample - Fixed callback pack = callback(context). Default:
    %       empty.
    %
    % Outputs:
    %   app - Immutable compiled labkit.app.Definition value.
    %
    % Definition Methods:
    %   launch() - Build and show the native MATLAB App figure.
    %   launch(Diagnostics=options) - Use one
    %       labkit.app.diagnostic.Options value for standard or verbose
    %       sanitized runtime recording.
    %   launch("requirements") - Return declared facade requirements without
    %       creating a figure.
    %   launch("version") - Return product version metadata without creating
    %       a figure.
    %   validateViewSnapshot(view) - Validate target references, target
    %       capabilities and complete target coverage.
    %       Returns true or throws before any runtime UI mutation.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - A required argument is missing or
    %       an argument is unknown, duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - Metadata, requirements, workbench,
    %       callbacks, or renderers are malformed.
    %   labkit:app:contract:DuplicateId - A layout ID is duplicated.
    %   labkit:app:contract:UnknownReference - A view target is undeclared.
    %   labkit:app:contract:UnsupportedOperation - A view operation is
    %       not legal for its target.
    %   labkit:app:contract:InvalidValue - A launch request or output count is
    %       unsupported.
    %
    % Typical Call:
    %   workbench = labkit.app.layout.workbench({ ...
    %       labkit.app.layout.button("run", "Run", @runAnalysis)});
    %   app = labkit.app.Definition( ...
    %       Entrypoint="labkit_Example_app", AppId="example.app", ...
    %       Title="Example", Family="Examples", AppVersion="1.0.0", ...
    %       Updated="2026-07-19", Requirements=[], Workbench=workbench);
    %
    % See also labkit.app.layout.workbench, labkit.app.view.Snapshot,
    %   labkit.contract.requirements

    properties (SetAccess = immutable)
        Entrypoint (1, 1) string
        AppId (1, 1) string
        Title (1, 1) string
        DisplayName (1, 1) string
        Family (1, 1) string
        AppVersion (1, 1) string
        Updated (1, 1) string
        Requirements
        ProjectSchema
        CreateSession
        PresentWorkbench
        OnStart
        BuildDebugSample
        TargetIds (1, :) string
    end

    properties (SetAccess = immutable, GetAccess = private)
        TargetNodes (1, :) cell
        SignalBindings (1, :) cell
        OnStartBinding
        PlatformPlan (1, 1) struct
    end

    methods
        function obj = Definition(varargin)
            names = [ ...
                "Entrypoint", "AppId", "Title", "DisplayName", "Family", ...
                "AppVersion", "Updated", "Requirements", "Workbench", ...
                "ProjectSchema", "CreateSession", "PresentWorkbench", ...
                "OnStart", "BuildDebugSample"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.Definition", names, varargin{:});
            required = [ ...
                "Entrypoint", "AppId", "Title", "Family", "AppVersion", ...
                "Updated", "Requirements", "Workbench"];
            for name = required
                if ~isfield(options, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "labkit.app.Definition requires argument %s.", name);
                end
            end

            obj.Entrypoint = matlabId(options.Entrypoint, "Entrypoint");
            obj.AppId = appId(options.AppId);
            obj.Title = nonemptyText(options.Title, "Title");
            displayName = obj.Title;
            if isfield(options, "DisplayName")
                displayName = nonemptyText( ...
                    options.DisplayName, "DisplayName");
            end
            obj.DisplayName = displayName;
            obj.Family = nonemptyText(options.Family, "Family");
            obj.AppVersion = semanticVersion(options.AppVersion);
            obj.Updated = isoDate(options.Updated);
            obj.Requirements = validateRequirements(options.Requirements);
            obj.ProjectSchema = validateProjectSchema( ...
                optionValue(options, "ProjectSchema", []));
            obj.CreateSession = optionalFixedCallback( ...
                options, "CreateSession", 2, 1);
            obj.PresentWorkbench = optionalFixedCallback( ...
                options, "PresentWorkbench", 1, 1);
            startCallback = optionalFixedCallback( ...
                options, "OnStart", 2, 1);
            obj.OnStart = startCallback;
            onStartBinding = [];
            if ~isempty(startCallback)
                onStartBinding = labkit.app.internal.SignalBinding( ...
                    "application", "started", startCallback);
            end
            obj.OnStartBinding = onStartBinding;
            obj.BuildDebugSample = optionalFixedCallback( ...
                options, "BuildDebugSample", 1, 1);

            layout = options.Workbench;
            if ~isa(layout, "labkit.app.internal.LayoutNode") || ...
                    layout.Kind ~= "workbench"
                error("labkit:app:contract:InvalidValue", ...
                    "Definition Workbench must be a workbench Layout value.");
            end
            nodes = layout.flattenForCompiler();
            ids = string(cellfun(@(value) value.Id, nodes, ...
                "UniformOutput", false));
            interactions = collectInteractions(nodes);
            interactionIds = string(cellfun(@(value) value.Id, interactions, ...
                "UniformOutput", false));
            assertUnique([ids interactionIds], "Layout and interaction");
            targetMask = cellfun(@(value) ...
                ~isempty(value.Capabilities), nodes);
            obj.TargetNodes = [nodes(targetMask) interactions];
            obj.TargetIds = string(cellfun(@(value) value.Id, ...
                obj.TargetNodes, "UniformOutput", false));
            obj.SignalBindings = collectSignalBindings( ...
                [nodes interactions], obj.OnStartBinding);
            obj.PlatformPlan = compilePlatformPlan(nodes);
        end

        function accepted = validateViewSnapshot(obj, view)
            if ~isa(view, "labkit.app.view.Snapshot")
                error("labkit:app:contract:InvalidValue", ...
                    "Definition view snapshot must be a " + ...
                    "labkit.app.view.Snapshot value.");
            end
            operations = view.operationsForCompiler();
            covered = false(size(obj.TargetIds));
            for k = 1:numel(operations)
                operation = operations{k};
                index = find(obj.TargetIds == operation.Target, 1);
                if isempty(index)
                    error("labkit:app:contract:UnknownReference", ...
                        "Unknown view target: %s.", operation.Target);
                end
                node = obj.TargetNodes{index};
                if ~any(node.Capabilities == operation.Kind)
                    error("labkit:app:contract:UnsupportedOperation", ...
                        "Target %s does not support %s.", ...
                        operation.Target, operation.Kind);
                end
                if operation.Kind == "renderPlot" && isempty(node.Renderer)
                    error("labkit:app:contract:UnknownReference", ...
                        "Target %s does not declare a renderer.", ...
                        operation.Target);
                end
                covered(index) = true;
            end
            missing = obj.TargetIds(~covered);
            if ~isempty(missing)
                error("labkit:app:contract:UnknownReference", ...
                    "Complete view snapshot is missing target: %s.", ...
                    missing(1));
            end
            accepted = true;
        end

        function varargout = launch(obj, varargin)
            %LAUNCH Answer metadata requests or show the native MATLAB App.
            initialProject = [];
            diagnostics = labkit.app.diagnostic.Options();
            if ~isempty(varargin) && ...
                    ~(numel(varargin) == 1 && ...
                      (ischar(varargin{1}) || ...
                       (isstring(varargin{1}) && isscalar(varargin{1}))))
                options = labkit.app.internal.OptionParser.parse( ...
                    "labkit.app.Definition.launch", ...
                    ["InitialProject", "Diagnostics"], ...
                    varargin{:});
                if isfield(options, "InitialProject")
                    if ~isstruct(options.InitialProject) || ...
                            ~isscalar(options.InitialProject)
                        error("labkit:app:contract:InvalidValue", ...
                            "Definition launch InitialProject must be a " + ...
                            "scalar project struct.");
                    end
                    initialProject = options.InitialProject;
                end
                if isfield(options, "Diagnostics")
                    if ~isa(options.Diagnostics, ...
                            "labkit.app.diagnostic.Options") || ...
                            ~isscalar(options.Diagnostics)
                        error("labkit:app:contract:InvalidValue", ...
                            "Definition launch Diagnostics must be one " + ...
                            "labkit.app.diagnostic.Options value.");
                    end
                    diagnostics = options.Diagnostics;
                end
                varargin = {};
            end
            if ~isempty(varargin)
                if numel(varargin) ~= 1 || ...
                        ~(ischar(varargin{1}) || ...
                        (isstring(varargin{1}) && isscalar(varargin{1})))
                    error("labkit:app:contract:InvalidValue", ...
                        "Definition launch accepts one optional request.");
                end
                request = lower(string(varargin{1}));
                if nargout > 1
                    error("labkit:app:contract:InvalidValue", ...
                        "Definition metadata requests return one output.");
                end
                switch request
                    case "requirements"
                        varargout = {obj.Requirements};
                    case "version"
                        varargout = {struct( ...
                            "name", obj.Entrypoint, ...
                            "displayName", obj.DisplayName, ...
                            "family", obj.Family, ...
                            "version", obj.AppVersion, ...
                            "updated", obj.Updated)};
                    otherwise
                        error("labkit:app:contract:InvalidValue", ...
                            "Definition launch request is unsupported: %s.", ...
                            request);
                end
                return;
            end
            if nargout > 1
                error("labkit:app:contract:InvalidValue", ...
                    "Definition launch returns at most one figure.");
            end
            runtime = obj.createMatlabRuntime( ...
                initialProject, struct(), diagnostics);
            runtime.showFigure();
            figure = runtime.figureHandle();
            if nargout == 1
                varargout = {figure};
            else
                varargout = {};
            end
        end
    end

    methods (Hidden)
        function ids = signalIdsForRuntime(obj)
            ids = string(cellfun(@(binding) binding.Id, obj.SignalBindings, ...
                "UniformOutput", false));
        end

        function binding = onStartBindingForRuntime(obj)
            binding = obj.OnStartBinding;
        end

        function tf = hasSignalForRuntime(obj, binding)
            tf = any(cellfun(@(candidate) ...
                isequaln(candidate, binding), obj.SignalBindings));
        end

        function runtime = createRuntimeForTesting( ...
                obj, initialProject, backend, diagnostics)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                diagnostics = labkit.app.diagnostic.Options();
            end
            runtime = obj.createRuntimeKernel( ...
                initialProject, backend, "headless", diagnostics);
        end

        function runtime = createMatlabRuntime( ...
                obj, initialProject, backend, diagnostics)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                diagnostics = labkit.app.diagnostic.Options();
            end
            runtime = obj.createRuntimeKernel( ...
                initialProject, backend, "matlab", diagnostics);
        end

        function plan = platformPlanForRuntime(obj)
            plan = obj.PlatformPlan;
        end

        function runtime = createRuntimeKernel( ...
                obj, initialProject, backend, platform, diagnostics)
            recorder = labkit.app.internal.DiagnosticRecorder( ...
                obj, diagnostics);
            sampleOperation = [];
            try
                if diagnostics.Sample == "synthetic"
                    sampleOperation = recorder.begin( ...
                        "sample", "synthetic", "build");
                    initialProject = obj.buildSyntheticProject( ...
                        initialProject, diagnostics);
                    recorder.finish(sampleOperation, "completed", []);
                    sampleOperation = [];
                end
                runtime = labkit.app.internal.RuntimeKernel( ...
                    obj, initialProject, backend, platform, diagnostics, ...
                    recorder);
            catch cause
                if ~isempty(sampleOperation)
                    recorder.finish(sampleOperation, "failed", cause);
                end
                recorder.close();
                rethrow(cause);
            end
        end

        function initialProject = buildSyntheticProject( ...
                obj, initialProject, diagnostics)
            if ~isempty(initialProject)
                error("labkit:app:contract:InvalidValue", ...
                    "Definition launch cannot combine InitialProject with " + ...
                    "a synthetic diagnostic sample.");
            end
            if strlength(diagnostics.ArtifactFolder) == 0
                error("labkit:app:contract:InvalidValue", ...
                    "A synthetic diagnostic sample requires ArtifactFolder.");
            end
            if isempty(obj.BuildDebugSample)
                error("labkit:app:contract:UnsupportedOperation", ...
                    "Definition does not declare BuildDebugSample.");
            end
            if isempty(obj.ProjectSchema)
                error("labkit:app:contract:UnsupportedOperation", ...
                    "A synthetic diagnostic sample requires ProjectSchema.");
            end
            context = labkit.app.diagnostic.SampleContext( ...
                diagnostics.ArtifactFolder);
            pack = obj.BuildDebugSample(context);
            if ~isa(pack, "labkit.app.diagnostic.SamplePack") || ...
                    ~isscalar(pack)
                error("labkit:app:contract:InvalidValue", ...
                    "BuildDebugSample must return one " + ...
                    "labkit.app.diagnostic.SamplePack value.");
            end
            try
                accepted = obj.ProjectSchema.Validate(pack.InitialProject);
            catch cause
                failure = MException( ...
                    "labkit:app:contract:InvalidValue", ...
                    "BuildDebugSample returned an invalid current project.");
                failure = addCause(failure, cause);
                throw(failure);
            end
            if ~isequal(accepted, true)
                error("labkit:app:contract:InvalidValue", ...
                    "BuildDebugSample returned an invalid current project.");
            end
            verifySampleArtifacts(context, pack);
            writeSampleManifest(context, pack);
            initialProject = pack.InitialProject;
        end
    end
end

function verifySampleArtifacts(context, pack)
for k = 1:numel(pack.Artifacts)
    artifact = pack.Artifacts{k};
    if artifact.Expectation == "exports"
        continue;
    end
    pathParts = cellstr(split(artifact.RelativePath, "/"));
    filepath = string(fullfile( ...
        char(context.ArtifactFolder), pathParts{:}));
    if exist(char(filepath), "file") ~= 2 && ...
            exist(char(filepath), "dir") ~= 7
        error("labkit:app:contract:InvalidValue", ...
            "BuildDebugSample did not create artifact %s.", artifact.Id);
    end
end
end

function writeSampleManifest(context, pack)
artifacts = repmat(struct( ...
    "id", "", "role", "", "relativePath", "", ...
    "expectation", ""), 1, numel(pack.Artifacts));
for k = 1:numel(pack.Artifacts)
    artifact = pack.Artifacts{k};
    artifacts(k) = struct( ...
        "id", artifact.Id, ...
        "role", artifact.Role, ...
        "relativePath", artifact.RelativePath, ...
        "expectation", artifact.Expectation);
end
payload = struct( ...
    "type", "labkit.diagnostic.sample-pack", ...
    "scenario", pack.Scenario, ...
    "artifacts", artifacts);
filepath = string(fullfile(context.ArtifactFolder, "sample-pack.json"));
temporary = filepath + ".tmp";
file = fopen(char(temporary), "w");
if file < 0
    error("labkit:app:runtime:DiagnosticWriteFailed", ...
        "Could not write the diagnostic sample manifest.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
clear cleanup
[moved, message] = movefile(char(temporary), char(filepath), "f");
if ~moved
    error("labkit:app:runtime:DiagnosticWriteFailed", ...
        "Could not publish the diagnostic sample manifest: %s", message);
end
end

function plan = compilePlatformPlan(nodes)
    compiled = repmat(struct( ...
        "Kind", "", "Id", "", "ChildIds", strings(1, 0), ...
        "Capabilities", strings(1, 0), "Signals", {{}}, ...
        "Renderer", [], "AxisIds", strings(1, 0), ...
        "PageIds", strings(1, 0), "InitialPage", "", ...
        "Configuration", struct()), 1, numel(nodes));
    for k = 1:numel(nodes)
        node = nodes{k};
        childIds = string(cellfun(@(child) child.Id, node.Children, ...
            "UniformOutput", false));
        compiled(k) = struct( ...
            "Kind", node.Kind, "Id", node.Id, "ChildIds", childIds, ...
            "Capabilities", node.Capabilities, ...
            "Signals", {node.Signals}, ...
            "Renderer", node.Renderer, "AxisIds", node.AxisIds, ...
            "PageIds", node.PageIds, "InitialPage", node.InitialPage, ...
            "Configuration", node.configurationForCompiler());
    end
    plan = struct("Nodes", compiled);
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end

function value = matlabId(value, label)
    value = nonemptyText(value, label);
    if ~isvarname(char(value))
        error("labkit:app:contract:InvalidValue", ...
            "Definition %s must be a MATLAB identifier.", label);
    end
end

function value = appId(value)
    value = nonemptyText(value, "Id");
    if isempty(regexp(char(value), ...
            '^[A-Za-z][A-Za-z0-9_.-]*$', "once"))
        error("labkit:app:contract:InvalidValue", ...
            "Definition AppId has invalid syntax.");
    end
end

function value = nonemptyText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
            strlength(string(value)) == 0
        error("labkit:app:contract:InvalidValue", ...
            "Definition %s must be nonempty scalar text.", label);
    end
    value = string(value);
end

function value = semanticVersion(value)
    value = nonemptyText(value, "AppVersion");
    if isempty(regexp(char(value), ...
            '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$', ...
            "once"))
        error("labkit:app:contract:InvalidValue", ...
            "Definition AppVersion must use X.Y.Z syntax.");
    end
end

function value = isoDate(value)
    value = nonemptyText(value, "Updated");
    if isempty(regexp(char(value), ...
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', "once"))
        error("labkit:app:contract:InvalidValue", ...
            "Definition Updated must use YYYY-MM-DD syntax.");
    end
    try
        parsed = datetime(value, "InputFormat", "yyyy-MM-dd");
    catch
        error("labkit:app:contract:InvalidValue", ...
            "Definition Updated is not a valid date.");
    end
    if string(parsed, "yyyy-MM-dd") ~= value
        error("labkit:app:contract:InvalidValue", ...
            "Definition Updated is not a canonical date.");
    end
end

function value = validateRequirements(value)
    if isempty(value)
        return;
    end
    if ~isstruct(value) || ~isscalar(value) || ...
            ~isfield(value, "type") || ...
            string(value.type) ~= "labkit.requirements" || ...
            ~isfield(value, "facades")
        error("labkit:app:contract:InvalidValue", ...
            "Requirements must come from labkit.contract.requirements.");
    end
end

function value = validateProjectSchema(value)
    if ~isempty(value) && ~isa(value, "labkit.app.project.Schema")
        error("labkit:app:contract:InvalidValue", ...
            "Definition ProjectSchema must be a project.Schema or empty.");
    end
end

function callback = optionalFixedCallback(options, name, inputs, outputs)
    callback = [];
    if ~isfield(options, name) || isempty(options.(name))
        return;
    end
    callback = options.(name);
    if ~isa(callback, "function_handle") || ~isscalar(callback) || ...
            nargin(callback) ~= inputs || nargout(callback) ~= outputs
        error("labkit:app:contract:CallbackRoleMismatch", ...
            "Definition %s requires %d inputs and %d outputs.", ...
            name, inputs, outputs);
    end
end

function assertUnique(values, label)
    if numel(unique(values)) ~= numel(values)
        error("labkit:app:contract:DuplicateId", ...
            "%s IDs must be globally unique.", label);
    end
end

function bindings = collectSignalBindings(nodes, start)
    bindings = {};
    for k = 1:numel(nodes)
        signals = nodes{k}.Signals;
        for s = 1:numel(signals)
            bindings{end + 1} = signals{s};
        end
    end
    if ~isempty(start)
        bindings{end + 1} = start;
    end
    bindings = uniqueBindings(bindings);
end

function interactions = collectInteractions(nodes)
interactions = {};
for k = 1:numel(nodes)
    if nodes{k}.Kind ~= "plotArea"
        continue;
    end
    configuration = nodes{k}.configurationForCompiler();
    if isfield(configuration, "Interactions")
        interactions = [interactions configuration.Interactions];
    end
end
end

function values = uniqueBindings(values)
    uniqueValues = {};
    for k = 1:numel(values)
        value = values{k};
        sameId = find(cellfun(@(candidate) candidate.Id == value.Id, ...
            uniqueValues), 1);
        if isempty(sameId)
            uniqueValues{end + 1} = value;
        elseif ~isequaln(uniqueValues{sameId}, value)
            error("labkit:app:contract:DuplicateId", ...
                "Layout signal ID %s has conflicting callbacks.", value.Id);
        end
    end
    values = uniqueValues;
end

function state = runAnalysis(state, ~)
    state.finished = true;
end
