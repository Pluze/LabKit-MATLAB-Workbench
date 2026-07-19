function report = measureLabKitUiMigrationBaseline(repoRoot, options)
%MEASURELABKITUIMIGRATIONBASELINE Measure representative current UI costs.
%
% Usage:
%   report = measureLabKitUiMigrationBaseline
%   report = measureLabKitUiMigrationBaseline(repoRoot)
%   report = measureLabKitUiMigrationBaseline(repoRoot, Write=true)
%
% Description:
%   Launches the three Phase-1 prototype Apps with hidden figures and records
%   repeated startup, standalone presenter, and close timings. These numbers
%   are migration comparison evidence, not correctness assertions or
%   interactive-workflow validation.
%
% Inputs:
%   repoRoot - LabKit repository root. Default: repository containing this
%       function.
%
% Name-Value Arguments:
%   LaunchRepetitions - Positive integer launch samples per App. Default: 3.
%   PresentationRepetitions - Positive integer presenter samples per launch.
%       Default: 25.
%   Write - Logical scalar. Write performance-baseline.json under OutputRoot.
%       Default: false.
%   OutputRoot - Evidence folder. Default:
%       .agents/migration/ui-explicit-contract beneath repoRoot.
%
% Outputs:
%   report - Scalar structure containing environment, scenario, and timing
%       samples and medians.
%
% Errors:
%   LabKit:Migration:InvalidRoot - repoRoot is not a LabKit checkout.
%   LabKit:Migration:MissingApp - A representative App cannot be discovered.
%   LabKit:Migration:WriteFailed - The evidence file cannot be written.
%
% Side effects:
%   Temporarily changes the MATLAB path and LABKIT_GUI_TEST_MODE, launches and
%   deletes hidden App figures, and optionally writes one JSON evidence file.
%
% Example:
%   report = measureLabKitUiMigrationBaseline(pwd, ...
%       LaunchRepetitions=1, PresentationRepetitions=3);
%   assert(numel(report.scenarios) == 3)
%
% See also profileLabKitTarget

    arguments
        repoRoot (1, 1) string = defaultRepositoryRoot()
        options.LaunchRepetitions (1, 1) double { ...
            mustBeInteger, mustBePositive} = 3
        options.PresentationRepetitions (1, 1) double { ...
            mustBeInteger, mustBePositive} = 25
        options.Write (1, 1) logical = false
        options.OutputRoot (1, 1) string = ""
    end
    repoRoot = validateRoot(repoRoot);
    if strlength(options.OutputRoot) == 0
        options.OutputRoot = fullfile(repoRoot, ".agents", "migration", ...
            "ui-explicit-contract");
    end

    oldPath = path;
    pathCleanup = onCleanup(@() path(oldPath));
    oldMode = getenv("LABKIT_GUI_TEST_MODE");
    modeCleanup = onCleanup(@() setenv("LABKIT_GUI_TEST_MODE", oldMode));
    setenv("LABKIT_GUI_TEST_MODE", "hidden");
    addpath(repoRoot, "-begin");

    catalog = labkit_launcher("list");
    commands = [ ...
        "labkit_TTestWizard_app"
        "labkit_CurvatureMeasurement_app"
        "labkit_VideoMarker_app"];
    scenarios = repmat(emptyScenario(), numel(commands), 1);
    for k = 1:numel(commands)
        row = find(catalog.Command == commands(k), 1);
        if isempty(row)
            error("LabKit:Migration:MissingApp", ...
                "Representative App is absent from the catalog: %s", ...
                commands(k));
        end
        addpath(catalog.Folder(row), "-begin");
        scenarios(k) = measureScenario(commands(k), ...
            catalog.DisplayName(row), options.LaunchRepetitions, ...
            options.PresentationRepetitions);
    end

    report = struct( ...
        "schemaVersion", 1, ...
        "capturedAtUtc", char(datetime("now", "TimeZone", "UTC", ...
            "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
        "matlabRelease", version("-release"), ...
        "platform", computer, ...
        "guiMode", "hidden", ...
        "launchRepetitions", options.LaunchRepetitions, ...
        "presentationRepetitions", options.PresentationRepetitions, ...
        "scenarios", scenarios);
    if options.Write
        writeReport(options.OutputRoot, report);
    end
    clear modeCleanup pathCleanup
end

function scenario = measureScenario(command, title, launchCount, presentCount)
    startup = zeros(launchCount, 1);
    firstPresenter = zeros(launchCount, 1);
    repeatedPresenter = zeros(launchCount, presentCount);
    closeTime = zeros(launchCount, 1);
    presentationCommits = zeros(launchCount, 1);
    for iLaunch = 1:launchCount
        close all force
        started = tic;
        fig = feval(command);
        drawnow;
        startup(iLaunch) = toc(started);
        cleanup = onCleanup(@() deleteIfValid(fig));
        runtime = getappdata(fig, "labkitUiAppRuntime");
        presented = tic;
        runtime.definition.present(runtime.state);
        firstPresenter(iLaunch) = toc(presented);
        for iPresent = 1:presentCount
            presented = tic;
            runtime.definition.present(runtime.state);
            repeatedPresenter(iLaunch, iPresent) = toc(presented);
        end
        presentationCommits(iLaunch) = ...
            double(runtime.metrics.presentationCommits);
        closing = tic;
        deleteIfValid(fig);
        closeTime(iLaunch) = toc(closing);
        clear cleanup
    end
    scenario = struct( ...
        "command", char(command), ...
        "title", char(title), ...
        "startupSeconds", startup, ...
        "startupMedianSeconds", median(startup), ...
        "firstStandalonePresenterSeconds", firstPresenter, ...
        "firstStandalonePresenterMedianSeconds", median(firstPresenter), ...
        "repeatedStandalonePresenterSeconds", repeatedPresenter, ...
        "repeatedStandalonePresenterMedianSeconds", ...
            median(repeatedPresenter, "all"), ...
        "startupPresentationCommits", presentationCommits, ...
        "closeSeconds", closeTime, ...
        "closeMedianSeconds", median(closeTime));
end

function scenario = emptyScenario()
    scenario = struct( ...
        "command", "", "title", "", ...
        "startupSeconds", [], "startupMedianSeconds", 0, ...
        "firstStandalonePresenterSeconds", [], ...
        "firstStandalonePresenterMedianSeconds", 0, ...
        "repeatedStandalonePresenterSeconds", [], ...
        "repeatedStandalonePresenterMedianSeconds", 0, ...
        "startupPresentationCommits", [], ...
        "closeSeconds", [], "closeMedianSeconds", 0);
end

function deleteIfValid(fig)
    if ~isempty(fig) && isvalid(fig)
        delete(fig);
    end
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

function writeReport(outputRoot, report)
    if ~isfolder(outputRoot)
        mkdir(outputRoot);
    end
    filepath = fullfile(outputRoot, "performance-baseline.json");
    fid = fopen(filepath, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Migration:WriteFailed", ...
            "Could not write migration evidence: %s", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, char(string(jsonencode(report, PrettyPrint=true)) + ...
        newline), "char");
    clear cleanup
end
