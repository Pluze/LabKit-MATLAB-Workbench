function report = prototypeLabKitUiEndToEnd(repoRoot, options)
%PROTOTYPELABKITUENDTOEND Exercise one disposable end-to-end UI contract.
%
% Usage:
%   report = prototypeLabKitUiEndToEnd
%   report = prototypeLabKitUiEndToEnd(repoRoot, Write=true)
%
% Description:
%   Compiles and commits a hidden T-Test-style UI from immutable prototype
%   values. The experiment covers complete presentation snapshots, private
%   reconciliation, declared context capabilities, callback transactions,
%   rollback, render-surface escape rejection, and Phase-0-derived timing
%   thresholds. It is migration evidence, not a production runtime.
%
% Inputs:
%   repoRoot - LabKit repository root. Default: repository containing this
%       function.
%
% Name-Value Arguments:
%   Write - Write Phase 1B JSON and Markdown evidence. Default: false.
%   OutputRoot - Evidence folder. Default:
%       .agents/migration/ui-explicit-contract beneath repoRoot.
%
% Outputs:
%   report - Scalar structure containing transaction, reconciliation, timing,
%       threshold, and acceptance evidence.
%
% Errors:
%   LabKit:Migration:InvalidRoot - repoRoot is not a LabKit checkout.
%   LabKit:Migration:WriteFailed - Evidence cannot be written.
%
% Side effects:
%   Creates and closes three hidden uifigures. Write=true updates migration
%   evidence files.
%
% See also prototypeLabKitUiContracts

    arguments
        repoRoot (1, 1) string = defaultRepositoryRoot()
        options.Write (1, 1) logical = false
        options.OutputRoot (1, 1) string = ""
    end
    repoRoot = validateRoot(repoRoot);
    if strlength(options.OutputRoot) == 0
        options.OutputRoot = fullfile(repoRoot, ".agents", "migration", ...
            "ui-explicit-contract");
    end
    prototypeRoot = fullfile(repoRoot, "tools", "migration", "prototypes");
    addpath(prototypeRoot, "-begin");
    pathCleanup = onCleanup(@() rmpath(prototypeRoot));

    baseline = jsondecode(fileread(fullfile(options.OutputRoot, ...
        "performance-baseline.json")));
    ttestBaseline = baseline.scenarios(1);
    startup = zeros(3, 1);
    firstPresentation = zeros(3, 1);
    repeatedPresentation = zeros(25, 3);
    closeTime = zeros(3, 1);
    commitTime = zeros(3, 1);
    transaction = struct();
    reconciliation = struct();

    for sample = 1:3
        started = tic;
        [app, commands] = buildContract();
        ui = createHiddenUi();
        uiCleanup = onCleanup(@() deleteValidFigure(ui.figure));
        state = initialState();
        initialView = presentationFor(state);
        initialPlan = compileSnapshot(app, initialView);
        [initialApplied, ~] = applySnapshot(ui, initialPlan, struct());
        drawnow;
        startup(sample) = toc(started);

        started = tic;
        compileSnapshot(app, presentationFor(state));
        firstPresentation(sample) = toc(started);
        for repetition = 1:25
            started = tic;
            compileSnapshot(app, presentationFor(state));
            repeatedPresentation(repetition, sample) = toc(started);
        end

        context = runtimeContext(app);
        [committedState, committedPlan, rolledBack, errorId] = ...
            dispatchTransaction(state, commands.run, context, ...
                initialPlan, app);
        commitStarted = tic;
        [updatedApplied, appliedKeys] = applySnapshot( ...
            ui, committedPlan, initialPlan);
        drawnow;
        commitTime(sample) = toc(commitStarted);

        [failedState, failedPlan, failureRolledBack, failureId] = ...
            dispatchTransaction(committedState, commands.fail, context, ...
                committedPlan, app);
        missingContext = runtimeContext(app);
        missingContext.Capabilities = "render";
        [~, ~, missingCapabilityRolledBack, missingCapabilityId] = ...
            dispatchTransaction(state, commands.run, missingContext, ...
                initialPlan, app);
        surfaceContext = context;
        surfaceContext.RenderSurface = acquireRenderSurface( ...
            context, "groupComparison", ui.previews.resultPlot);
        [~, ~, surfaceRolledBack, surfaceErrorId] = ...
            dispatchTransaction(state, commands.storeSurface, ...
                surfaceContext, initialPlan, app);

        if sample == 1
            transaction = struct( ...
                "commitChangedState", ~isequaln(committedState, state), ...
                "commitRolledBack", rolledBack, ...
                "commitError", errorId, ...
                "failureRolledBack", failureRolledBack, ...
                "failurePreservedState", ...
                    isequaln(failedState, committedState), ...
                "failurePreservedPresentation", ...
                    isequaln(failedPlan, committedPlan), ...
                "failureError", failureId, ...
                "missingCapabilityRolledBack", ...
                    missingCapabilityRolledBack, ...
                "missingCapabilityError", missingCapabilityId, ...
                "surfaceEscapeRolledBack", surfaceRolledBack, ...
                "surfaceEscapeError", surfaceErrorId);
            reconciliation = struct( ...
                "snapshotTargetCount", numel(initialPlan.TargetIds), ...
                "initialAppliedOperationCount", initialApplied, ...
                "updatedAppliedOperationCount", updatedApplied, ...
                "updatedAppliedKeys", appliedKeys, ...
                "runtimeOwnedDiff", updatedApplied < ...
                    numel(committedPlan.Operations));
        end

        closeStarted = tic;
        delete(ui.figure);
        drawnow;
        closeTime(sample) = toc(closeStarted);
        clear uiCleanup
    end

    thresholds = struct( ...
        "startupSeconds", ...
            1.20 * ttestBaseline.startupMedianSeconds + 0.25, ...
        "firstPresentationSeconds", max( ...
            2 * ttestBaseline.firstStandalonePresenterMedianSeconds, ...
            0.005), ...
        "repeatedPresentationSeconds", max( ...
            2 * ttestBaseline.repeatedStandalonePresenterMedianSeconds, ...
            0.001), ...
        "closeSeconds", 1.20 * ttestBaseline.closeMedianSeconds + 0.25);
    timings = struct( ...
        "startupMedianSeconds", median(startup), ...
        "firstPresentationMedianSeconds", median(firstPresentation), ...
        "repeatedPresentationMedianSeconds", ...
            median(repeatedPresentation, "all"), ...
        "commitMedianSeconds", median(commitTime), ...
        "closeMedianSeconds", median(closeTime));
    timingAccepted = timings.startupMedianSeconds <= ...
        thresholds.startupSeconds && ...
        timings.firstPresentationMedianSeconds <= ...
        thresholds.firstPresentationSeconds && ...
        timings.repeatedPresentationMedianSeconds <= ...
        thresholds.repeatedPresentationSeconds && ...
        timings.closeMedianSeconds <= thresholds.closeSeconds;
    behaviorAccepted = transaction.commitChangedState && ...
        ~transaction.commitRolledBack && ...
        transaction.failureRolledBack && ...
        transaction.failurePreservedState && ...
        transaction.failurePreservedPresentation && ...
        transaction.missingCapabilityRolledBack && ...
        transaction.surfaceEscapeRolledBack && ...
        reconciliation.runtimeOwnedDiff;
    report = struct( ...
        "schemaVersion", 1, ...
        "scenario", "T-Test-style hidden end-to-end contract", ...
        "transaction", transaction, ...
        "reconciliation", reconciliation, ...
        "timings", timings, ...
        "thresholds", thresholds, ...
        "timingAccepted", timingAccepted, ...
        "behaviorAccepted", behaviorAccepted, ...
        "accepted", timingAccepted && behaviorAccepted);
    if options.Write
        writeEvidence(options.OutputRoot, report);
    end
    clear pathCleanup
end

function [app, commands] = buildContract()
    commands = struct( ...
        "run", valueproto.Command("runTest", @runAnalysis), ...
        "fail", valueproto.Command("failTest", @failAnalysis), ...
        "storeSurface", valueproto.Command( ...
            "storeSurface", @storeRenderSurface));
    layout = valueproto.Layout.root({ ...
        valueproto.Layout.control("group", "field"), ...
        valueproto.Layout.control("dataTable", "table"), ...
        valueproto.Layout.control("runTest", "action"), ...
        valueproto.Layout.preview("resultPlot")});
    app = valueproto.Application("ttest_end_to_end", layout, ...
        {commands.run, commands.fail, commands.storeSurface}, ...
        "groupComparison", ["workflow", "render"]);
end

function state = initialState()
    state = struct( ...
        "Group", "A", ...
        "Groups", ["A", "B"], ...
        "Data", [1 2; 3 4], ...
        "CanRun", true, ...
        "ResultX", [1 2], ...
        "ResultY", [1 1]);
end

function view = presentationFor(state)
    view = valueproto.Presentation();
    view = view.choices("group", state.Groups);
    view = view.value("group", state.Group);
    view = view.table("dataTable", state.Data);
    view = view.enabled("runTest", state.CanRun);
    view = view.plot("resultPlot", "groupComparison", ...
        struct("X", state.ResultX, "Y", state.ResultY));
end

function plan = compileSnapshot(app, view)
    plan = app.compile(view);
    operationTargets = strings(1, numel(plan.Operations));
    for k = 1:numel(plan.Operations)
        operationTargets(k) = plan.Operations{k}.Target;
    end
    for k = 1:numel(plan.TargetIds)
        if ~any(operationTargets == plan.TargetIds(k))
            error("prototype:ui:IncompletePresentation", ...
                "Complete presentation is missing target: %s", ...
                plan.TargetIds(k));
        end
    end
end

function context = runtimeContext(app)
    context = struct( ...
        "Capabilities", app.Capabilities, ...
        "Renderers", app.Renderers);
end

function [nextState, nextPlan, rolledBack, errorId] = ...
        dispatchTransaction(state, command, context, priorPlan, app)
    nextState = state;
    nextPlan = priorPlan;
    rolledBack = false;
    errorId = "";
    try
        candidate = command.Callback(state, context);
        validateState(candidate);
        candidatePlan = compileSnapshot(app, presentationFor(candidate));
        nextState = candidate;
        nextPlan = candidatePlan;
    catch exception
        rolledBack = true;
        errorId = string(exception.identifier);
    end
end

function state = runAnalysis(state, context)
    requireCapability(context, "workflow");
    state.Group = "B";
    state.CanRun = false;
    state.ResultY = [1.5 2.5];
end

function state = failAnalysis(state, context)
    requireCapability(context, "workflow");
    state.Group = "B";
    error("prototype:ui:ActionFailed", "Synthetic transaction failure.");
end

function state = storeRenderSurface(state, context)
    requireCapability(context, "render");
    state.EscapedRenderSurface = context.RenderSurface;
end

function requireCapability(context, capability)
    if ~any(context.Capabilities == capability)
        error("prototype:ui:UndeclaredCapability", ...
            "Runtime capability was not declared: %s", capability);
    end
end

function surface = acquireRenderSurface(context, renderer, axesHandle)
    requireCapability(context, "render");
    if ~any(context.Renderers == renderer)
        error("prototype:ui:UnknownReference", ...
            "Renderer was not declared: %s", renderer);
    end
    surface = axesHandle;
end

function validateState(state)
    fields = fieldnames(state);
    for k = 1:numel(fields)
        value = state.(fields{k});
        if any(isgraphics(value), "all")
            error("prototype:ui:EscapedRenderSurface", ...
                "Render surfaces cannot be retained in App state.");
        end
    end
end

function ui = createHiddenUi()
    figureHandle = uifigure( ...
        "Visible", "off", ...
        "Name", "LabKit UI contract Phase 1B prototype");
    grid = uigridlayout(figureHandle, [2 3]);
    group = uidropdown(grid);
    dataTable = uitable(grid);
    runTest = uibutton(grid, "Text", "Run");
    resultPlot = uiaxes(grid);
    resultPlot.Layout.Row = 2;
    resultPlot.Layout.Column = [1 3];
    ui = struct( ...
        "figure", figureHandle, ...
        "controls", struct( ...
            "group", group, ...
            "dataTable", dataTable, ...
            "runTest", runTest), ...
        "previews", struct("resultPlot", resultPlot));
end

function [appliedCount, appliedKeys] = ...
        applySnapshot(ui, plan, previousPlan)
    operations = plan.Operations;
    appliedKeys = strings(0, 1);
    for k = 1:numel(operations)
        operation = operations{k};
        key = operation.Kind + "|" + operation.Target;
        previous = previousOperation(previousPlan, key);
        if ~isempty(previous) && isequaln(previous, operation)
            continue;
        end
        applyOperation(ui, operation);
        appliedKeys(end + 1, 1) = key;
    end
    appliedCount = numel(appliedKeys);
end

function operation = previousOperation(plan, key)
    operation = [];
    if ~isstruct(plan) || ~isfield(plan, "Operations")
        return;
    end
    for k = 1:numel(plan.Operations)
        candidate = plan.Operations{k};
        if candidate.Kind + "|" + candidate.Target == key
            operation = candidate;
            return;
        end
    end
end

function applyOperation(ui, operation)
    switch operation.Kind
        case "choices"
            ui.controls.(operation.Target).Items = ...
                cellstr(operation.Value);
        case "value"
            ui.controls.(operation.Target).Value = operation.Value;
        case "table"
            ui.controls.(operation.Target).Data = operation.Value;
        case "enabled"
            ui.controls.(operation.Target).Enable = ...
                matlab.lang.OnOffSwitchState(operation.Value);
        case "plot"
            axesHandle = ui.previews.(operation.Target);
            cla(axesHandle);
            plot(axesHandle, operation.Value.X, operation.Value.Y);
        otherwise
            error("prototype:ui:UnsupportedOperation", ...
                "Prototype adapter cannot apply: %s", operation.Kind);
    end
end

function deleteValidFigure(figureHandle)
    if isgraphics(figureHandle)
        delete(figureHandle);
    end
end

function writeEvidence(outputRoot, report)
    if ~isfolder(outputRoot)
        mkdir(outputRoot);
    end
    writeText(fullfile(outputRoot, "phase-1-end-to-end-evidence.json"), ...
        string(jsonencode(report, PrettyPrint=true)) + newline);
    lines = [ ...
        "# Phase 1B end-to-end contract evidence"
        ""
        "Scenario: hidden T-Test-style contract from immutable values through " + ...
            "compile, complete snapshot, private reconciliation, transaction, " + ...
            "rollback, and close."
        ""
        "- Behavior accepted: " + string(report.behaviorAccepted)
        "- Timing accepted: " + string(report.timingAccepted)
        "- Phase 1B accepted: " + string(report.accepted)
        "- Startup median/threshold: " + ...
            compose("%.4f", report.timings.startupMedianSeconds) + "/" + ...
            compose("%.4f", report.thresholds.startupSeconds) + " s"
        "- First presentation median/threshold: " + ...
            compose("%.6f", ...
                report.timings.firstPresentationMedianSeconds) + "/" + ...
            compose("%.6f", ...
                report.thresholds.firstPresentationSeconds) + " s"
        "- Repeated presentation median/threshold: " + ...
            compose("%.6f", ...
                report.timings.repeatedPresentationMedianSeconds) + "/" + ...
            compose("%.6f", ...
                report.thresholds.repeatedPresentationSeconds) + " s"
        "- Close median/threshold: " + ...
            compose("%.4f", report.timings.closeMedianSeconds) + "/" + ...
            compose("%.4f", report.thresholds.closeSeconds) + " s"
        "- Runtime diff applied " + ...
            string(report.reconciliation.updatedAppliedOperationCount) + ...
            " of " + ...
            string(report.reconciliation.initialAppliedOperationCount) + ...
            " snapshot operations after the committed action."
        ""
        "This is disposable migration evidence, not a released runtime."
        ""];
    writeText(fullfile(outputRoot, "phase-1-end-to-end-evidence.md"), ...
        strjoin(lines, newline));
end

function root = defaultRepositoryRoot()
    root = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
end

function root = validateRoot(root)
    [ok, attributes] = fileattrib(root);
    if ~ok || ~attributes.directory || ...
            ~isfile(fullfile(attributes.Name, "labkit_launcher.m"))
        error("LabKit:Migration:InvalidRoot", ...
            "Not a LabKit repository root: %s", root);
    end
    root = string(attributes.Name);
end

function writeText(filepath, text)
    fid = fopen(filepath, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Migration:WriteFailed", ...
            "Could not write migration evidence: %s", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, char(text), "char");
    clear cleanup
end
