classdef TestArchitectureSpec < matlab.unittest.TestCase
    %TESTARCHITECTURESPEC Specify one active owner/contract test architecture.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function appSdkInternalRootContainsNoImplementationTypes(testCase)
            root = labkittest.setup();
            internalRoot = fullfile(root, "+labkit", "+app", "+internal");
            files = dir(fullfile(internalRoot, "*.m"));

            testCase.verifyEmpty(string({files.name}), ...
                "App SDK internal implementations must belong to a named subsystem.");
            required = ["+artifact" "+contract" "+diagnostics" "+discovery" ...
                "+interaction" "+launcher" "+native" "+resource" ...
                "+runtime" "+source"];
            testCase.verifyTrue(all(arrayfun(@(name) ...
                isfolder(fullfile(internalRoot, name)), required)), ...
                "The governed App SDK internal subsystem map is incomplete.");
        end

        function launcherDispatchRemainsCompositionOnly(testCase)
            root = labkittest.setup();
            source = text(root, ...
                "+labkit/+app/+internal/+launcher/dispatch.m");
            definitions = regexp(source, "(?m)^function ", "match");

            testCase.verifyNumElements(definitions, 1, ...
                "Launcher dispatch must not reacquire local subsystem implementations.");
            for owner = ["parseRequest" "appCatalog" ...
                    "documentationPage" "launcherVersion" "createLauncher"]
                testCase.verifySubstring(source, ...
                    "labkit.app.internal.launcher." + owner);
            end
        end

        function launcherDoesNotOwnFigureStudioOrDocumentationConsumers(testCase)
            root = labkittest.setup();
            controller = text(root, ...
                "+labkit/+app/+internal/+launcher/createLauncher.m");
            popout = text(root, ...
                "+labkit/+app/+internal/+native/private/createPopoutToolbar.m");
            documentation = text(root, ...
                "tools/docs/private/loadLabKitDocumentation.m");

            testCase.verifyFalse(any(contains(controller, ...
                ["labkit_FigureStudio_app" "labkitFigureStudioLauncher"])));
            testCase.verifyFalse(contains(popout, ...
                "labkitFigureStudioLauncher"));
            testCase.verifySubstring(popout, ...
                "labkit.app.internal.discovery.discoverApps");
            testCase.verifySubstring(documentation, ...
                "labkit.app.internal.launcher.appCatalog");
            testCase.verifyFalse(contains(documentation, ...
                "labkit_launcher("));
        end

        function catalogDescriptorsUseCurrentOwnerRoots(testCase)
            descriptors = labkittest.catalog();

            testCase.verifyNotEmpty(descriptors);
            testCase.verifyTrue(all(startsWith(string({descriptors.Owner}), ...
                ["apps/" "labkit/" "tools/" "tests/"]) | ...
                ismember(string({descriptors.Owner}), ...
                ["labkit_launcher" "repository"]) | ...
                string({descriptors.Owner}) == ""));
        end

        function appPackagesUseWorkflowOrDomainCapabilityNames(testCase)
            root = labkittest.setup();
            listing = dir(fullfile(root, "apps", "**", "+*"));
            listing = listing([listing.isdir]);
            forbidden = ["+actions" "+ops" "+io" "+ui" ...
                "+userInterface" "+view" "+export" "+helpers" ...
                "+utils" "+manager" "+processor"];
            names = string({listing.name});
            listing = listing(ismember(names, forbidden));
            violations = strings(1, numel(listing));
            for index = 1:numel(listing)
                folder = fullfile(listing(index).folder, listing(index).name);
                violations(index) = replace(erase( ...
                    string(folder), string(root) + filesep), "\", "/");
            end

            testCase.verifyEmpty(violations, ...
                "App packages must name a workflow or domain capability: " + ...
                strjoin(violations, ", "));
        end

        function productionDynamicInvocationIsClosedAndOwned(testCase)
            root = labkittest.setup();
            files = replace(repositoryTextFiles(root), "\", "/");
            files = files(endsWith(lower(files), ".m"));
            files = files(files == "labkit_launcher.m" | ...
                startsWith(files, ["+labkit/" "apps/" "tools/"]));
            allowedFiles = [ ...
                "+labkit/+app/+internal/+discovery/invokeDiscoveredApp.m"
                "tools/profiling/profileLabKitTarget.m"];
            allowedCalls = { ...
                ["feval(" "feval("]
                "feval("};
            markers = [ ...
                "Dynamic extension boundary"
                "Dynamic maintainer-tool boundary"];

            for file = files.'
                source = string(fileread(fullfile(root, file)));
                calls = regexp(source, ...
                    '(?<![\w.])(eval|evalin|assignin|str2func|feval)\s*\(', ...
                    'match');
                assignments = regexp(source, ...
                    ['(?<![\w.])assignin\s*\(\s*' ...
                    '(?:"base"|''base'')\s*,\s*' ...
                    '(?:"[A-Za-z]\w*"|''[A-Za-z]\w*'')\s*,'], ...
                    'match');
                testCase.verifyEqual(sum(string(calls) == "assignin("), ...
                    numel(assignments), ...
                    "assignin must export data through literal base-workspace and variable names in " + file);
                calls(string(calls) == "assignin(") = [];
                allowedIndex = find(allowedFiles == file, 1);
                if ~isempty(allowedIndex)
                    testCase.verifyEqual(string(calls), ...
                        string(allowedCalls{allowedIndex}), ...
                        "Only the reviewed dynamic boundary is allowed in " + file);
                    testCase.verifySubstring(source, markers(allowedIndex));
                else
                    testCase.verifyEmpty(calls, ...
                        "Fixed production calls must remain statically visible in " + file);
                end
            end
        end

        function productionUsesOnlyBaseMatlabBackgroundRuntime(testCase)
            root = labkittest.setup();
            files = productionMatlabFiles(root);
            expression = ["parpool\s*\(" "parfor\s+" "spmd\s*\(" ...
                "parallel\.Pool" "parallel\.Cluster"];
            probe = ["parpool('threads')" "parfor index = 1:2" ...
                "spmd(2)" "parallel.Pool.empty" "parallel.Cluster"];
            testCase.verifyTrue(all(arrayfun(@(index) ~isempty(regexp( ...
                probe(index), expression(index), "once")), ...
                1:numel(expression))), ...
                "The Toolbox-only guard patterns must prove their own coverage.");
            violations = strings(numel(files) * numel(expression), 1);
            violationCount = 0;
            for file = files.'
                source = string(fileread(fullfile(root, file)));
                for token = expression
                    if ~isempty(regexp(source, token, "once"))
                        violationCount = violationCount + 1;
                        violations(violationCount) = file + ": " + token;
                    end
                end
            end
            violations = violations(1:violationCount);

            testCase.verifyEmpty(violations, ...
                "Production must not open or address Parallel Computing Toolbox pools: " + ...
                strjoin(violations, ", "));

            driver = text(root, "+labkit/+mark10/connect.m");
            testCase.verifySubstring(driver, ...
                "parfeval(backgroundPool, @mark10ServiceLoop");
            testCase.verifySubstring(driver, ...
                "parallel.pool.PollableDataQueue");
            testCase.verifyFalse(contains(driver, "parfeval(@"), ...
                "Background work must explicitly name backgroundPool.");
        end

        function taskBranchFeedbackUsesOneCancelableBaseMatlabLane(testCase)
            root = labkittest.setup();
            workflow = text(root, ...
                ".github/workflows/development-feedback.yml");

            testCase.verifySubstring(workflow, "branches-ignore:");
            testCase.verifySubstring(workflow, "- main");
            testCase.verifySubstring(workflow, "runs-on: ubuntu-latest");
            testCase.verifySubstring(workflow, "release: latest");
            testCase.verifyFalse(contains(workflow, "products:"));
            testCase.verifySubstring(workflow, "cancel-in-progress: true");
            testCase.verifySubstring(workflow, "pull-requests: read");
            testCase.verifySubstring(workflow, ...
                "steps.scope.outputs.should_run == 'true'");
            testCase.verifySubstring(workflow, ...
                "steps.handoff.outputs.should_run == 'true'");
            testCase.verifySubstring(workflow, ...
                "Open task-branch PR owns complete validation");
            testCase.verifySubstring(workflow, ...
                "Pull request took ownership before MATLAB setup");
            testCase.verifySubstring(workflow, "github.event.before");
            testCase.verifySubstring(workflow, ...
                "artifacts/development-feedback/changed-paths.txt");
            testCase.verifySubstring(workflow, "runDevelopmentFeedback");
            testCase.verifySubstring(workflow, "tasks: docsCheck");
        end

        function defaultBuildRunsOneCompleteLocalGate(testCase)
            plan = buildfile;

            testCase.verifyEqual(plan.DefaultTasks, "changedFast");
            testCase.verifyEqual(sort(string(plan("changedFast").Dependencies)), ...
                ["codecheck", "docsCheck"]);
        end

        function ciGatesPlatformAndDocsWithoutDuplicateCoverage(testCase)
            root = labkittest.setup();
            workflow = text(root, ".github/workflows/ci.yml");
            platformJob = workflowJob(workflow, "platform-matrix");
            docsJob = workflowJob(workflow, "docs-check");
            gateJob = workflowJob(workflow, "ci-gate");

            testCase.verifySubstring(workflow, "policy:");
            testCase.verifySubstring(workflow, "name: Repository policy");
            testCase.verifyFalse(contains(workflow, "workflow_dispatch:"));
            testCase.verifyFalse(contains(workflow, ...
                "group: ci-${{ github.event.pull_request.head.sha || github.sha }}"));
            testCase.verifySubstring(workflow, ...
                "python -m unittest discover -s .github/scripts");
            testCase.verifySubstring(workflow, ...
                "python .github/scripts/validate_agent_skills.py");
            testCase.verifySubstring(workflow, ...
                "python .github/scripts/check_integration_policy.py");
            testCase.verifySubstring(workflow, ...
                "--head-ref ""${{ github.head_ref }}""");
            testCase.verifySubstring(workflow, ...
                "--head-repository");
            testCase.verifySubstring(workflow, ...
                "--base-sha ""${BASE_SHA}""");
            testCase.verifySubstring(workflow, ...
                "[ -z ""${BASE_SHA}"" ]");
            testCase.verifySubstring(workflow, ...
                "git merge-base origin/main ""${HEAD_SHA}""");
            testCase.verifySubstring(workflow, "fetch-depth: 0");
            testCase.verifyFalse(contains(workflow, "classify_ci_scope"));
            testCase.verifySubstring(platformJob, "needs: policy");
            testCase.verifySubstring(docsJob, "needs: policy");
            testCase.verifySubstring(workflow, "docs-check:");
            testCase.verifySubstring(workflow, "tasks: docsCheck");
            testCase.verifySubstring(workflow, "release: R2022b");
            testCase.verifySubstring(workflow, "release: latest");
            testCase.verifySubstring(workflow, "shard: All profiles");
            testCase.verifySubstring(workflow, "shard: Desktop boundaries");
            testCase.verifySubstring(workflow, "os: ubuntu-22.04");
            testCase.verifySubstring(workflow, "os: windows-2022");
            testCase.verifySubstring(workflow, "os: windows-latest");
            testCase.verifySubstring(workflow, "os: macos-14");
            testCase.verifyEqual(count(workflow, "- os: "), 5);
            testCase.verifyEqual(count(workflow, "run_headless: true"), 3);
            testCase.verifyEqual(count(workflow, "run_gui: true"), 5);
            testCase.verifyEqual(count(workflow, "run_isolated: true"), 5);
            testCase.verifySubstring(platformJob, "cache: true");
            testCase.verifySubstring(docsJob, "cache: true");
            testCase.verifyFalse(contains(workflow, "tasks: coverage"));
            testCase.verifySubstring(workflow, ...
                "name: Start Linux virtual display");
            testCase.verifySubstring(workflow, ...
                "Xvfb :99 -screen 0 1920x1080x24");
            testCase.verifySubstring(workflow, ...
                "Documents/MATLAB");
            testCase.verifySubstring(workflow, ...
                "release: ${{ matrix.release }}");
            testCase.verifySubstring(workflow, ...
                "name: matlab-${{ matrix.id }}-${{ matrix.release }}-" + ...
                "${{ matrix.shard_id }}");
            testCase.verifySubstring(workflow, ...
                "name: Summarize platform validation");
            testCase.verifyEqual(count(workflow, ...
                "python .github/scripts/summarize_junit.py"), 1);
            testCase.verifySubstring(workflow, ...
                "--profiles ""${{ matrix.profiles }}""");
            testCase.verifySubstring(workflow, ...
                "--headless-outcome ""${{ steps.headless.outcome }}""");
            testCase.verifySubstring(workflow, ...
                "if: matrix.run_headless");
            testCase.verifySubstring(workflow, ...
                "if: matrix.run_gui");
            testCase.verifySubstring(workflow, ...
                "if: matrix.run_isolated");
            testCase.verifyEqual(count(workflow, ...
                "if: github.event_name != 'push'"), 2);
            testCase.verifySubstring(workflow, ...
                "needs.platform-matrix.result");
            testCase.verifySubstring(gateJob, "name: CI Gate");
            testCase.verifySubstring(gateJob, "- platform-matrix");
            testCase.verifySubstring(gateJob, "- docs-check");
            testCase.verifySubstring(gateJob, "needs.policy.result");
            testCase.verifySubstring(gateJob, "needs.platform-matrix.result");
            testCase.verifySubstring(gateJob, "needs.docs-check.result");
            testCase.verifyFalse(contains(gateJob, "coverage"));
        end

        function pullRequestChecklistContainsOnlyAuthorOwnedMergeObligations(testCase)
            root = labkittest.setup();
            template = text(root, ".github/PULL_REQUEST_TEMPLATE.md");

            for heading = ["## Why" "## What changed" "## Evidence" ...
                    "## Risks and follow-up" "## Author confirmation"]
                testCase.verifySubstring(template, heading);
            end
            lines = strip(splitlines(template));
            tasks = lines(startsWith(lines, "- [ ] "));
            testCase.verifyNumElements(tasks, 3);
            testCase.verifyTrue(any(contains(tasks, "final diff")));
            testCase.verifyTrue(any(contains(tasks, "evidence above")));
            testCase.verifyTrue(any(contains(tasks, "synthetic or generic")));
            testCase.verifyFalse(any(contains(lower(tasks), ...
                ["github" "branch" "commit" "push" "merge" "n/a"])));
        end

        function documentationSiteIsBuiltByPagesAndNotTracked(testCase)
            root = labkittest.setup();
            workflow = text(root, ".github/workflows/docs-pages.yml");
            ignore = splitlines(text(root, ".gitignore"));

            testCase.verifyTrue(any(strip(ignore) == "site/"));
            testCase.verifySubstring(workflow, "workflow_dispatch:");
            testCase.verifyFalse(contains(workflow, "    paths:"));
            testCase.verifySubstring(workflow, ...
                "name: Generate documentation from the exact main source");
            testCase.verifySubstring(workflow, ...
                "uses: matlab-actions/setup-matlab@v3");
            testCase.verifySubstring(workflow, ...
                "uses: matlab-actions/run-build@v3");
            testCase.verifySubstring(workflow, "tasks: docs");
            testCase.verifySubstring(workflow, ...
                "uses: actions/configure-pages@v6");
            testCase.verifySubstring(workflow, ...
                "uses: actions/upload-pages-artifact@v5");
            testCase.verifySubstring(workflow, ...
                "uses: actions/deploy-pages@v5");
            testCase.verifySubstring(workflow, "path: site");
        end

        function repositoryTextDoesNotContainUserPathsOrTimestampTokens(testCase)
            root = labkittest.setup();
            files = repositoryTextFiles(root);

            testCase.verifyNotEmpty(files);
            for index = 1:numel(files)
                file = files(index);
                content = string(fileread(fullfile(root, file)));
                testCase.verifyEmpty(regexp(content, "(?<![A-Za-z])[A-Za-z]:[\\\\/]", "once"), ...
                    "Tracked text contains a drive-root path: " + file);
                testCase.verifyEmpty(regexp(content, "/(?:Users|home)/[^/\\s]+/", "once"), ...
                    "Tracked text contains a Unix user path: " + file);
                testCase.verifyEmpty(regexp(content, "\\d{8}_\\d{6}", "once"), ...
                    "Tracked text contains a sample timestamp token: " + file);
            end
        end

        function matlabFunctionNamesFitTheIdentifierLimit(testCase)
            root = labkittest.setup();
            files = repositoryTextFiles(root);
            files = files(endsWith(lower(files), ".m"));
            violationChunks = repmat({strings(0, 1)}, numel(files), 1);
            expression = "(?m)^\s*function\s+" + ...
                "(?:\[[^\]\r\n]*\]\s*=\s*|[A-Za-z]\w*\s*=\s*)?" + ...
                "([A-Za-z]\w*)\s*(?:\(|$)";
            for index = 1:numel(files)
                relative = files(index);
                file = fullfile(root, relative);
                tokens = regexp(fileread(file), expression, "tokens");
                names = string([tokens{:}]);
                names = names(strlength(names) > 63);
                if isempty(names)
                    continue;
                end
                violationChunks{index} = relative + ": " + names(:);
            end
            violations = vertcat(violationChunks{:});

            testCase.verifyEmpty(violations, ...
                "R2022b truncates MATLAB identifiers longer than 63 characters: " + ...
                strjoin(violations, ", "));
        end

        function appsUseSdkOwnedNativeFileDialogs(testCase)
            root = labkittest.setup();
            listing = dir(fullfile(root, "apps", "**", "*.m"));
            violations = strings(numel(listing), 1);
            violationCount = 0;
            expression = "(?<![A-Za-z0-9_.])" + ...
                "(uigetfile|uiputfile|uigetdir)\s*\(";
            for index = 1:numel(listing)
                file = fullfile(listing(index).folder, listing(index).name);
                source = string(fileread(file));
                if ~isempty(regexp(source, expression, "once"))
                    relative = erase(string(file), string(root) + filesep);
                    violationCount = violationCount + 1;
                    violations(violationCount, 1) = relative;
                end
            end

            violations = violations(1:violationCount);
            testCase.verifyEmpty(violations, ...
                "Apps must use CallbackContext or fileList for native " + ...
                "file dialogs so platform/version adaptation remains in SDK.");
        end

        function appSpecificationsUseLabKitTestSeams(testCase)
            root = labkittest.setup();
            specsRoot = fullfile(root, "tests", "specs", "apps");
            listing = dir(fullfile(specsRoot, "**", "*.m"));
            violations = strings(numel(listing), 1);
            violationCount = 0;
            for index = 1:numel(listing)
                file = fullfile(listing(index).folder, listing(index).name);
                if contains(string(fileread(file)), "labkit.app.internal")
                    violationCount = violationCount + 1;
                    violations(violationCount) = erase( ...
                        string(file), string(root) + filesep);
                end
            end

            violations = violations(1:violationCount);
            testCase.verifyEmpty(violations, ...
                "App and conformance specifications must use focused " + ...
                "labkittest seams instead of SDK internals: " + ...
                strjoin(violations, ", "));
        end

        function testsPassAnExplicitJournalOrJournalRootToEveryRuntimeFactory(testCase)
            root = labkittest.setup();
            files = dir(fullfile(root, "tests", "**", "*.m"));
            violationChunks = cell(1, numel(files));
            for index = 1:numel(files)
                file = fullfile(files(index).folder, files(index).name);
                calls = labkittest.runtimeFactoryCalls(fileread(file));
                fileViolations = strings(1, numel(calls));
                violationCount = 0;
                for call = calls
                    if ~hasExplicitJournalOrRoot(call)
                        relative = erase(string(file), string(root) + filesep);
                        violationCount = violationCount + 1;
                        fileViolations(violationCount) = relative + ":" + ...
                            string(call.Line) + " must pass a nonempty fourth journal " + ...
                            "or fourth [] with a nonempty JournalRoot.";
                    end
                end
                violationChunks{index} = fileViolations(1:violationCount);
            end
            violations = [violationChunks{:}];
            testCase.verifyEmpty(violations, strjoin(violations, newline));
        end

        function runtimeFactoryParserAcceptsFourthArgumentJournal(testCase)
            source = strjoin([ ...
                "% RuntimeFactory.createMatlab(app) is a comment.", ...
                "literal = ""RuntimeFactory.createHeadless(app)"";", ...
                "runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...", ...
                "    app, [], struct(), journal);"], newline);

            calls = labkittest.runtimeFactoryCalls(source);

            testCase.verifyNumElements(calls, 1);
            testCase.verifyEqual(calls.Method, "createHeadless");
            testCase.verifyNumElements(calls.Arguments, 4);
            testCase.verifyTrue(hasExplicitJournalOrRoot(calls));
        end

        function runtimeFactoryParserAcceptsLabKitTestRuntimeSeam(testCase)
            source = strjoin([ ...
                "runtime = labkittest.createMatlabRuntime( ...", ...
                "    app, [], struct(), journal);"], newline);

            calls = labkittest.runtimeFactoryCalls(source);

            testCase.verifyNumElements(calls, 1);
            testCase.verifyEqual(calls.Method, "createMatlab");
            testCase.verifyNumElements(calls.Arguments, 4);
            testCase.verifyTrue(hasExplicitJournalOrRoot(calls));
        end

        function runtimeFactoryParserHandlesTransposeAndCharLiterals(testCase)
            source = strjoin([ ...
                "values = [1 2];", ...
                "values.';", ...
                "literal = 'RuntimeFactory.createMatlab(app)';", ...
                "runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...", ...
                "    app, [], struct(""alert"", @(~, ~) []), ...", ...
                "    journal);"], newline);

            calls = labkittest.runtimeFactoryCalls(source);

            testCase.verifyNumElements(calls, 1);
            testCase.verifyEqual(calls.Method, "createHeadless");
            testCase.verifyNumElements(calls.Arguments, 4);
            testCase.verifyTrue(hasExplicitJournalOrRoot(calls));
        end

        function runtimeFactoryParserAcceptsJournalAndExtraArguments(testCase)
            source = strjoin([ ...
                "runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...", ...
                "    app, [], struct(), journal, ...", ...
                "    JournalRoot=temporaryRoot);"], newline);

            calls = labkittest.runtimeFactoryCalls(source);

            testCase.verifyNumElements(calls, 1);
            testCase.verifyEqual(calls.Arguments(4), "journal");
            testCase.verifyTrue(hasExplicitJournalOrRoot(calls));
        end

        function runtimeFactoryParserAcceptsExplicitJournalRootWithEmptyJournal(testCase)
            source = strjoin([ ...
                "runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...", ...
                "    app, [], struct(), [], ...", ...
                "    JournalRoot=temporaryRoot);"], newline);

            calls = labkittest.runtimeFactoryCalls(source);

            testCase.verifyNumElements(calls, 1);
            testCase.verifyEqual(calls.Arguments(4), "[]");
            testCase.verifyTrue(startsWith(strtrim(calls.Arguments(5)), "..."));
            testCase.verifyEqual(calls.JournalRoot, "temporaryRoot");
            testCase.verifyTrue(hasExplicitJournalOrRoot(calls));
        end
    end
end

function tf = hasExplicitJournalOrRoot(call)
callArguments = call.Arguments;
hasJournal = numel(callArguments) >= 4 && ...
    strlength(callArguments(4)) > 0 && callArguments(4) ~= "[]";
hasJournalRoot = any(numel(callArguments) == [5, 6]) && ...
    callArguments(4) == "[]" && strlength(call.JournalRoot) > 0;
tf = hasJournal || hasJournalRoot;
end

function value = text(root, relative)
value = string(fileread(fullfile(root, relative)));
end

function section = workflowJob(workflow, name)
lines = splitlines(workflow);
startLine = find(lines == "  " + name + ":", 1);
jobLines = find(~cellfun("isempty", regexp(cellstr(lines), ...
    "^  [A-Za-z0-9_-]+:$", "once")));
nextLine = jobLines(find(jobLines > startLine, 1));
if isempty(nextLine)
    nextLine = numel(lines) + 1;
end
section = join(lines(startLine:nextLine - 1), newline);
end

function files = productionMatlabFiles(root)
files = replace(repositoryTextFiles(root), "\", "/");
files = files(endsWith(lower(files), ".m"));
files = files(files == "labkit_launcher.m" | ...
    startsWith(files, ["+labkit/" "apps/" "tools/"]));
end

function files = repositoryTextFiles(root)
% Secondary-runtime test boundary: a synthetic Git repository proves policy.
[status, output] = system("git -C " + shellQuote(root) + ...
    " ls-files --cached --others --exclude-standard");
if status ~= 0
    error("LabKit:RepositoryGuardrail:GitListFailed", ...
        "Could not list tracked repository files.");
end
files = splitlines(string(output));
files = unique(files(strlength(files) > 0), "stable");
files = files(arrayfun(@(file) isfile(fullfile(root, file)), files));
extensions = [".m" ".md" ".json" ".yml" ".yaml" ".txt"];
files = files(endsWith(lower(files), extensions));
end

function value = shellQuote(value)
value = '"' + replace(string(value), '"', '\\"') + '"';
end
