classdef TestArchitectureSpec < matlab.unittest.TestCase
    %TESTARCHITECTURESPEC Specify one active owner/contract test architecture.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function generatedApiExcludesInternalPackages(testCase)
            root = labkittest.setup();

            testCase.verifyFalse(isfolder(fullfile( ...
                root, "site", "reference", "api", "labkit", ...
                "app", "internal")));
        end

        function appSdkInternalRootContainsNoImplementationTypes(testCase)
            root = labkittest.setup();
            internalRoot = fullfile(root, "+labkit", "+app", "+internal");
            files = dir(fullfile(internalRoot, "*.m"));

            testCase.verifyEmpty(string({files.name}), ...
                "App SDK internal implementations must belong to a named subsystem.");
            required = ["+artifact" "+contract" "+diagnostics" ...
                "+interaction" "+launcher" "+native" "+project" ...
                "+resource" "+result" "+runtime" "+source"];
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
            for owner = ["parseRequest" "discoverApps" "appCatalogTable" ...
                    "documentationPage" "launcherVersion" "createLauncher"]
                testCase.verifySubstring(source, ...
                    "labkit.app.internal.launcher." + owner);
            end
        end

        function runtimeKernelKeepsCompleteWorkflowsInClassFolder(testCase)
            root = labkittest.setup();
            folder = fullfile(root, "+labkit", "+app", "+internal", ...
                "+runtime", "@RuntimeKernel");
            required = ["RuntimeKernel" "applyBoundControl" ...
                "applyFileSelection" "commitFilePanel" "completeBackend" ...
                "execute" "present" "restoreProject" ...
                "wrapDialogOperations"] + ".m";

            testCase.verifyTrue(all(arrayfun(@(name) ...
                isfile(fullfile(folder, name)), required)), ...
                "RuntimeKernel workflow methods must remain separately owned.");
            main = string(fileread(fullfile(folder, "RuntimeKernel.m")));
            testCase.verifyLessThanOrEqual(numel(splitlines(main)), 800, ...
                "RuntimeKernel definition is accumulating workflow bodies again.");
        end

        function activeEntryPointsDescribeOnlyTheCatalogModel(testCase)
            root = labkittest.setup();
            build = text(root, "buildfile.m");
            guide = text(root, "docs/development/maintain-and-release/testing.md");
            testsGuide = text(root, "tests/AGENTS.md");
            migrationGuide = text(root, ".agents/migration_guide.md");
            skillFiles = activeSkillFiles(root, "labkit-test-planner");

            testCase.verifySubstring(build, "labkittest.run");
            testCase.verifyFalse(contains(build, "runLabKitTests"));
            testCase.verifyFalse(contains(build, "tests/runner"));
            testCase.verifySubstring(migrationGuide, ...
                "tests/+labkittest/toolboxDebt.m");
            testCase.verifyFalse(contains(migrationGuide, ...
                "tests/runner/labkitToolboxDebt.m"));
            activeTexts = [guide; testsGuide; ...
                arrayfun(@(file) string(fileread(file)), skillFiles(:))];
            for active = activeTexts.'
                testCase.verifyFalse(contains(active, "tests/cases"));
                testCase.verifyFalse(contains(active, "runLabKitTests"));
                testCase.verifyFalse(contains(active, "tests/runner"));
            end
        end

        function catalogOwnsTheOnlyRunnableSpecificationRoot(testCase)
            root = labkittest.setup();
            descriptors = labkittest.catalog();

            testCase.verifyNotEmpty(descriptors);
            testCase.verifyTrue(all(startsWith(string({descriptors.Owner}), ...
                ["apps/" "labkit/" "tools/" "tests/"]) | ...
                ismember(string({descriptors.Owner}), ...
                ["labkit_launcher" "repository"]) | ...
                string({descriptors.Owner}) == ""));
            testCase.verifyFalse(isfile(fullfile(root, "tests", "runLabKitTests.m")) && ...
                isfile(fullfile(root, "buildfile.m")) && ...
                contains(text(root, "buildfile.m"), "runLabKitTests"));
            testCase.verifyTrue(isfolder(fullfile(root, "tests", "+testfixtures")));
            testCase.verifyFalse(isfolder(fullfile(root, "tests", "shared")));
            testCase.verifyFalse(isfolder(fullfile(root, "tests", "cases")));
            testCase.verifyFalse(isfolder(fullfile(root, "tests", "runner")));
        end

        function productionDynamicInvocationIsClosedAndOwned(testCase)
            root = labkittest.setup();
            files = replace(repositoryTextFiles(root), "\", "/");
            files = files(endsWith(lower(files), ".m"));
            files = files(files == "labkit_launcher.m" | ...
                startsWith(files, ["+labkit/" "apps/" "tools/"]));
            allowedFiles = [ ...
                "+labkit/+app/+internal/+launcher/createLauncher.m"
                "+labkit/+app/+internal/+native/private/FigureInteractionHub.m"
                "tools/profiling/profileLabKitTarget.m"];
            markers = [ ...
                "Dynamic extension boundary"
                "Compatibility boundary"
                "Dynamic maintainer-tool boundary"];

            for file = files.'
                source = string(fileread(fullfile(root, file)));
                calls = regexp(source, ...
                    '(?<![\w.])(eval|evalin|assignin|str2func|feval)\s*\(', ...
                    'match');
                allowedIndex = find(allowedFiles == file, 1);
                if ~isempty(allowedIndex)
                    testCase.verifyEqual(string(calls), "feval(", ...
                        "Only one reviewed feval boundary is allowed in " + file);
                    testCase.verifySubstring(source, markers(allowedIndex));
                else
                    testCase.verifyEmpty(calls, ...
                        "Fixed production calls must remain statically visible in " + file);
                end
            end
        end

        function ciRoutesDocumentationWithoutWeakeningAggregateGate(testCase)
            root = labkittest.setup();
            workflow = text(root, ".github/workflows/ci.yml");

            testCase.verifySubstring(workflow, "change-scope:");
            testCase.verifySubstring(workflow, ...
                "group: ci-${{ github.event_name }}-" + ...
                "${{ github.event.pull_request.number || github.ref }}");
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
            testCase.verifySubstring(workflow, "fetch-depth: 0");
            testCase.verifySubstring(workflow, ...
                "needs.change-scope.outputs.full == 'true'");
            testCase.verifySubstring(workflow, ...
                "needs.change-scope.outputs.docs == 'true'");
            testCase.verifySubstring(workflow, "docs-check:");
            testCase.verifySubstring(workflow, "tasks: docsCheck");
            testCase.verifyEqual(count(workflow, ...
                "release: R2022b"), 2);
            testCase.verifyEqual(count(workflow, ...
                "release: latest"), 6);
            testCase.verifyEqual(count(workflow, ...
                "shard: All profiles"), 3);
            testCase.verifyEqual(count(workflow, ...
                "shard: Core"), 2);
            testCase.verifyEqual(count(workflow, ...
                "shard: Hidden GUI"), 2);
            testCase.verifyEqual(count(workflow, ...
                "          - os: "), 7);
            testCase.verifySubstring(workflow, "os: ubuntu-22.04");
            testCase.verifySubstring(workflow, "os: windows-2022");
            testCase.verifySubstring(workflow, "os: macos-14");
            testCase.verifySubstring(workflow, ...
                "name: Start Linux virtual display");
            testCase.verifySubstring(workflow, ...
                "Xvfb :99 -screen 0 1920x1080x24");
            testCase.verifySubstring(workflow, ...
                "Documents/MATLAB");
            testCase.verifyEqual(count(workflow, ...
                "release: ${{ matrix.release }}"), 1);
            testCase.verifyEqual(count(workflow, ...
                "continue-on-error: true"), 3);
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
            testCase.verifyGreaterThanOrEqual(count(workflow, ...
                "github.event_name == 'pull_request'"), 2);
            testCase.verifySubstring(workflow, ...
                "needs.platform-matrix.result");
            testCase.verifySubstring(workflow, "ci-gate:");
            testCase.verifySubstring(workflow, "name: CI Gate");
            testCase.verifySubstring(workflow, "needs.change-scope.result");
            testCase.verifySubstring(workflow, "docs-check.result");
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
            testCase.verifySubstring(workflow, "- 'docs/**'");
            testCase.verifySubstring(workflow, "- '+labkit/**'");
            testCase.verifySubstring(workflow, "- 'apps/**'");
            testCase.verifySubstring(workflow, "- 'tools/docs/**'");
            testCase.verifyFalse(contains(workflow, "- 'site/**'"));
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

function files = activeSkillFiles(root, skillName)
listing = dir(fullfile(root, ".agents", "skills", skillName, "**", "*"));
listing = listing(~[listing.isdir]);
extensions = [".m" ".md"];
paths = string(fullfile({listing.folder}, {listing.name}));
files = paths(endsWith(lower(paths), extensions));
end

function files = repositoryTextFiles(root)
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
