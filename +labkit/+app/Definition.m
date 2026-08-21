classdef (Sealed) Definition
    %DEFINITION Compile and launch one immutable App SDK contract.
    %
    % Usage:
    %   app = labkit.app.Definition(Entrypoint=entrypoint, AppId=appId, ...
    %       Title=title, ...
    %       Family=family, AppVersion=version, Updated=date, ...
    %       Workbench=workbench, Name=Value)
    %   fig = app.launch()
    %   fig = app.launch(InitialInput=value)
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
    %   Workbench - Root value returned by labkit.app.layout.workbench.
    %
    % Optional Name-Value Arguments:
    %   DisplayName - Nonempty scalar text. Default: Title.
    %   CreateState - Fixed callback state = callback(context,initialInput).
    %       initialInput is an opaque App-owned scalar struct supplied at
    %       launch; it has no framework persistence semantics. Default: empty.
    %   Requirements - Empty value or labkit.contract.requirements result.
    %       Default: empty.
    %   RefreshState - Fixed callback state = callback(state,context), used
    %       after framework-owned source-list edits. Default: empty.
    %   PresentWorkbench - Fixed callback view = callback(state). Default:
    %       empty.
    %   OnStart - Fixed callback state = callback(state,context), invoked
    %       after the first view commit. Default: empty.
    %   BuildSyntheticSample - Fixed callback pack = callback(context). Default:
    %       empty.
    %
    % Outputs:
    %   app - Immutable compiled labkit.app.Definition value.
    %
    % Definition Methods:
    %   launch() - Build and show the native MATLAB App figure.
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
    %       labkit.app.layout.button("run", "Run", @runAnalysis, ...
    %           Tooltip="Compute the current analysis.")});
    %   app = labkit.app.Definition( ...
    %       Entrypoint="labkit_Example_app", AppId="example.app", ...
    %       Title="Example", Family="Examples", AppVersion="1.0.0", ...
    %       Updated="2026-07-19", Workbench=workbench);
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
        CreateState
        RefreshState
        PresentWorkbench
        OnStart
        BuildSyntheticSample
    end

    properties (SetAccess = immutable, GetAccess = { ...
            ?labkit.app.internal.runtime.RuntimeFactory, ...
            ?labkit.app.internal.contract.DefinitionInspector})
        Compiled
    end

    methods
        function obj = Definition(varargin)
            names = [ ...
                "Entrypoint", "AppId", "Title", "DisplayName", "Family", ...
                "AppVersion", "Updated", "Requirements", "Workbench", ...
                "CreateState", "RefreshState", ...
                "PresentWorkbench", ...
                "OnStart", "BuildSyntheticSample"];
            options = labkit.app.internal.contract.OptionParser.parse( ...
                "labkit.app.Definition", names, varargin{:});
            required = [ ...
                "Entrypoint", "AppId", "Title", "Family", "AppVersion", ...
                "Updated", "Workbench"];
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
            requirements = [];
            if isfield(options, "Requirements")
                requirements = options.Requirements;
            end
            obj.Requirements = validateRequirements(requirements);
            obj.CreateState = optionalFixedCallback( ...
                options, "CreateState", 2, 1);
            obj.RefreshState = optionalFixedCallback( ...
                options, "RefreshState", 2, 1);
            obj.PresentWorkbench = optionalFixedCallback( ...
                options, "PresentWorkbench", 1, 1);
            startCallback = optionalFixedCallback( ...
                options, "OnStart", 2, 1);
            obj.OnStart = startCallback;
            obj.BuildSyntheticSample = optionalFixedCallback( ...
                options, "BuildSyntheticSample", 1, 1);
            obj.Compiled = labkit.app.internal.contract.CompiledDefinition( ...
                options.Workbench, startCallback);
        end

        function accepted = validateViewSnapshot(obj, view)
            accepted = obj.Compiled.validateViewSnapshot(view);
        end

        function varargout = launch(obj, varargin)
            %LAUNCH Answer metadata requests or show the native MATLAB App.
            initialState = [];
            if ~isempty(varargin) && ...
                    ~(isscalar(varargin) && ...
                      (ischar(varargin{1}) || ...
                       (isstring(varargin{1}) && isscalar(varargin{1}))))
                options = labkit.app.internal.contract.OptionParser.parse( ...
                    "labkit.app.Definition.launch", ...
                    "InitialInput", ...
                    varargin{:});
                if isfield(options, "InitialInput")
                    if ~isstruct(options.InitialInput) || ...
                            ~isscalar(options.InitialInput)
                        error("labkit:app:contract:InvalidValue", ...
                            "Definition launch InitialInput must be a " + ...
                            "scalar App-owned struct.");
                    end
                    initialState = options.InitialInput;
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
            if ~isempty(obj.Requirements)
                labkit.contract.assertRequirements( ...
                    obj.Entrypoint, obj.Requirements);
            end
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                obj, initialState, struct());
            runtime.showFigure();
            figure = runtime.figureHandle();
            if nargout == 1
                varargout = {figure};
            else
                varargout = {};
            end
        end
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
