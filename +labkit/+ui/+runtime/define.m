function def = define(varargin)
%DEFINE Create a LabKit declarative app runtime definition.
%
% Usage:
%   def = labkit.ui.runtime.define("Command", command, "Id", id, ...
%       "Title", title, "Family", family, "AppVersion", version, ...
%       "Updated", date, "Requirements", requirements, ...
%       "Layout", layoutFcn)
%   def = labkit.ui.runtime.define(..., Name=Value)
%
% Outputs:
%   def - Validated scalar Runtime V2 definition accepted by
%       labkit.ui.runtime.launch.
%
% Description:
%   define describes an app without creating a figure. The definition connects
%   durable project data, temporary session data, a declarative layout, event
%   actions, and view presentation. Invalid definitions fail here, before the
%   app begins startup.
%
% Required Name-Value Arguments:
%   Command - Public MATLAB function used to launch the App, for example
%       "labkit_Example_app". Single-definition launch uses this value for
%       request errors and version metadata.
%   Id - Stable scalar text identifier for saved projects, recovery storage,
%       results, and diagnostics. It starts with an ASCII letter and contains
%       only letters, digits, underscore, hyphen, or period. Treat it as a
%       permanent compatibility identifier after projects have been saved.
%   Title - Text shown in the app window title.
%   Family - Nonempty character vector or scalar string naming the
%       reader-facing App family used by the launcher and documentation.
%   AppVersion - Semantic App version in X.Y.Z form. This versions the App
%       product, not the Runtime V2 project payload.
%   Updated - Last product-change date in YYYY-MM-DD form.
%   Requirements - labkit.contract.requirements result declaring compatible
%       reusable LabKit facades.
%   Layout - Function handle returning a labkit.ui.layout.workbench tree. It
%       may accept no inputs, callbacks, or callbacks and initial state:
%       layoutFcn(), layoutFcn(callbacks), or layoutFcn(callbacks,state).
%
% Optional Name-Value Arguments:
%   DisplayName - Short product name shown by the launcher. Default: Title.
%   Project - Scalar struct that owns a durable project schema. Omit it for an
%       empty version-1 project with no App validator or migrations. Supplied
%       project fields are listed under Project Fields.
%   CreateSession - Function handle returning transient session state. It may
%       accept no inputs or the newly created project. Missing selection,
%       workflow, view, and cache fields are added automatically. Default: an
%       empty session struct.
%   Actions - Scalar struct whose field names are event IDs and whose values
%       are functions of the form state = action(state,event,services).
%       Default: struct(), which is valid for a static App.
%   Present - Function handle of the form view = present(state). The returned
%       presenter model supplies control values, lists, tables, text, plots,
%       and interaction models for one committed view. Default: an empty
%       presenter model, which preserves values declared by a static layout.
%   Renderers - Scalar struct of renderer functions keyed by renderer ID. A
%       renderer may accept no inputs, the presented model, or the target axes
%       and model. Default: struct().
%   Start - Action ID or action function queued after the first view appears.
%       A function uses the normal action signature. Default: no startup action.
%   DebugSample - Function called as pack = writer(debugContext) after a debug
%       launch. It is not called during normal launch. Default: none.
%   Utilities - Scalar struct controlling framework menus. Fields are Visible,
%       Plot, Screenshot, and State. Visible defaults to true. Plot defaults to
%       true when the layout contains a preview area and false otherwise.
%       Screenshot defaults to true. State accepts "on" or "off" and defaults
%       to "on".
%
% Project Fields:
%   Version - Positive integer payload version. Version 1 has no migrations.
%   Create - Function handle project = createProject(). Missing inputs,
%       parameters, annotations, results, and extensions fields are added.
%   Validate - Function that checks a complete project. It may throw on invalid
%       data or return a logical scalar.
%   Migrate - Function project = migrate(project,fromVersion). The runtime
%       calls it once for each missing version and validates every returned
%       payload. Required when Version is greater than 1. Default: none.
%   LegacyImports - Scalar struct mapping MAT-file variable names to import
%       functions. An importer is called as project = import(value) or
%       [project,resume] = import(value), where value is the named MAT-file
%       variable. Imported formats are read-only; new saves use labkitProject.
%   CreateResume - Function resume = createResume(session,project) for optional
%       lightweight view/workflow state saved with the project.
%   ApplyResume - Function session = applyResume(session,resume,project) used
%       after a fresh session is created during load.
%   RelinkSources - Function project = relink(project,unresolved,projectFile)
%       used when required external files cannot be found. Returning [] cancels
%       the load.
%
% Action State and Event Fields:
%   state.project - Durable project data. Changes mark the document dirty and
%       are included in the next project save.
%   state.session - Transient selection, workflow, view, and cache data. It is
%       recreated when a project opens unless resume callbacks preserve a small
%       part of it.
%   event.id - Action ID that selected the handler.
%   event.source - Event origin, such as "user", "service", "startup", or
%       "interaction".
%   event.target - ID of the control, interaction, or runtime target.
%   event.value - Value supplied by the control, interaction, or dispatch call.
%   event.meta - Scalar struct containing source-specific details. For UI
%       events, meta.original contains the layout event without runtime handles.
%
% Service Fields:
%   services.figure - Owning app figure, for example as the parent of a custom
%       dialog.
%   services.debug - Debug context for trace messages and diagnostic reports.
%   services.request - Read-only launch request returned by RequestAdapter.
%   services.dispatch - Queues another action. Call dispatch(id,value) or pass
%       a scalar event struct. Nested actions run after the current action.
%   services.workflow - workflow.log(state,message) appends a visible workflow
%       message and returns the updated state.
%   services.diagnostics - diagnostics.report(context,exception) records a
%       caught exception in the runtime debug report.
%   services.events - Helpers entries(event,field), paths(event,field), and
%       indices(event,field,count) decode values from UI event metadata.
%   services.dialogs - App-parented alert, choice, inputFile, inputFolder,
%       outputFile, and outputFolder dialogs, plus defaultFolder and
%       defaultOutputFolder path helpers. File and folder selectors return the
%       selected string path and a logical cancelled flag.
%   services.project - newState creates a fresh canonical project and session
%       through the current definition. sourceRecord, upsertSource, and
%       reconcileSources create external-file records understood by project
%       save/load. Apps read current paths with labkit.ui.runtime.sourcePaths.
%       Each save
%       rebases their relative paths from its actual destination; saveState
%       saves a named project, while saveAutosave(state) immediately writes the
%       framework-managed recovery copy. saveAutosave(state,filepath) writes
%       the same recovery envelope to an app-determined path. Neither form
%       prompts for a path or changes named-project ownership.
%   services.previews - previews.axes(previewId,axisId) returns axes owned by a
%       declared preview area.
%   services.resources - set, get, remove, and clearScope manage resources with
%       optional cleanup functions at event, interaction, or figure scope.
%       set replaces and disposes an existing resource with the same scope and
%       id; choose distinct ids for resources that must coexist.
%   services.results - results.emptyOutputs creates the canonical empty
%       output array; results.output creates one validated manifest output;
%       results.writeManifest writes the app's result manifest.
%
% Action Processing:
%   Actions are processed in FIFO order. After an action returns, the runtime
%   validates the complete state and presents the new view as one transaction.
%   If the action, validation, or presentation throws, the previous state and
%   view are restored and the error is rethrown. An action with no output is
%   allowed for side effects, but it cannot change value-based project or
%   session state.
%
% Errors:
%   labkit:ui:runtime:InvalidDefinitionOptions - Name-value arguments are not
%   paired.
%   labkit:ui:runtime:MissingDefinitionField - A required definition field is
%   absent.
%   labkit:ui:runtime:InvalidDefinition - Product metadata, requirements,
%   project specification, callbacks, actions, utilities, or startup IDs do
%   not satisfy the Runtime V2 contract. Layout callback output is validated
%   later when launch or create builds the workbench.
%
% Typical Call:
%   def = labkit.ui.runtime.define( ...
%       "Command", "labkit_ExampleViewer_app", ...
%       "Id", "org.example.viewer", "Title", "Example Viewer", ...
%       "Family", "Examples", "AppVersion", "1.0.0", ...
%       "Updated", "2026-07-16", ...
%       "Requirements", labkit.contract.requirements("ui", ">=7 <8"), ...
%       "Layout", @buildStaticLayout);
%
% See also labkit.ui.runtime.launch, labkit.ui.runtime.sourceRecord,
%   labkit.ui.runtime.sourcePaths,
%   labkit.ui.runtime.saveState, labkit.ui.runtime.loadState

    opts = parseOptions(varargin);
    def = createV2Definition(opts);
    validateAppDefinition(def);
end

function def = createV2Definition(opts)
    def = struct();
    def.type = "labkit.ui.runtime.definition";
    def.contractVersion = 2;
    def.id = string(requiredOption(opts, "Id"));
    def.title = string(requiredOption(opts, "Title"));
    def.product = productMetadata(opts, def.title);
    def.requirements = optionValue(opts, "Requirements", []);
    def.project = optionValue(opts, "Project", defaultProjectSpec());
    def.createSession = optionValue(opts, "CreateSession", []);
    def.layout = requiredOption(opts, "Layout");
    def.actions = optionValue(opts, "Actions", struct());
    def.present = optionValue(opts, "Present", @emptyPresentation);
    def.renderers = optionValue(opts, "Renderers", struct());
    def.start = optionValue(opts, "Start", []);
    def.debugSample = optionValue(opts, "DebugSample", []);
    def.utilities = optionValue(opts, "Utilities", struct());
end

function product = productMetadata(opts, title)
    product = struct( ...
        "command", string(optionValue(opts, "Command", "")), ...
        "displayName", string(optionValue(opts, "DisplayName", title)), ...
        "family", string(optionValue(opts, "Family", "")), ...
        "version", string(optionValue(opts, "AppVersion", "")), ...
        "updated", string(optionValue(opts, "Updated", "")));
end

function spec = defaultProjectSpec()
    spec = struct( ...
        "Version", 1, ...
        "Create", @createEmptyProject, ...
        "Validate", @acceptProject, ...
        "Migrate", []);
end

function project = createEmptyProject()
    project = struct();
end

function accepted = acceptProject(~)
    accepted = true;
end

function presentation = emptyPresentation(~)
    presentation = struct();
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:runtime:InvalidDefinitionOptions', ...
            'labkit.ui.runtime.define options must be name-value pairs.');
    end
    opts = struct();
    for k = 1:2:numel(args)
        name = char(string(args{k}));
        opts.(name) = args{k + 1};
    end
end

function value = requiredOption(opts, name)
    field = char(name);
    if ~isfield(opts, field)
        error('labkit:ui:runtime:MissingDefinitionField', ...
            'App definition is missing required field "%s".', field);
    end
    value = opts.(field);
end

function value = optionValue(opts, name, defaultValue)
    field = char(name);
    value = defaultValue;
    if isfield(opts, field)
        value = opts.(field);
    end
end
