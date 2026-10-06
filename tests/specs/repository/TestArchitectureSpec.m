classdef TestArchitectureSpec < matlab.unittest.TestCase
    %TESTARCHITECTURESPEC Specify one active owner/contract test architecture.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function appSdkInternalRootContainsNoImplementationTypes(testCase)
            root = labkittest.setup();
            internalRoot = fullfile(root, "+labkit", "+app", "+internal");
            files = dir(fullfile(internalRoot, "*.m"));

            testCase.verifyEmpty(string({files.name}), ...
                "App SDK internal implementations must belong to a named subsystem.");

        end

        function launcherDoesNotOwnFigureStudioOrDocumentationConsumers(testCase)
            root = labkittest.setup();
            controller = text(root, ...
                "+labkit/+app/+internal/+launcher/createLauncher.m");
            handoff = text(root, ...
                "+labkit/+app/+internal/+native/private/sendPlotsToStudio.m");
            documentation = text(root, ...
                "tools/docs/private/loadLabKitDocumentation.m");

            testCase.verifyFalse(any(contains(controller, ...
                ["labkit_FigureStudio_app" "labkitFigureStudioLauncher"])));
            testCase.verifyFalse(contains(handoff, ...
                "labkitFigureStudioLauncher"));
            testCase.verifySubstring(handoff, ...
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

        function defaultBuildRunsOneCompleteLocalGate(testCase)
            plan = buildfile;

            testCase.verifyEqual(plan.DefaultTasks, "changedFast");
            testCase.verifyEqual(sort(string(plan("changedFast").Dependencies)), ...
                ["codecheck", "docsCheck"]);
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

        function specificationsConstructRuntimesThroughJournalGuardedSeams(testCase)
            root = labkittest.setup();
            files = dir(fullfile(root, "tests", "specs", "**", "*.m"));
            forbidden = "labkit.app.internal.runtime." + "RuntimeFactory";
            for file = files.'
                source = string(fileread(fullfile(file.folder, file.name)));
                testCase.verifyFalse(contains(source, forbidden), ...
                    "Use the test runtime seam that requires an explicit journal: " + ...
                    string(file.name));
            end
        end
    end
end

function value = text(root, relative)
value = string(fileread(fullfile(root, relative)));
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
