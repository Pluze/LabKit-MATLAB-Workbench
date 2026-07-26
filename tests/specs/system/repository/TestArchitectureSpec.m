classdef TestArchitectureSpec < matlab.unittest.TestCase
    %TESTARCHITECTURESPEC Specify one active owner/contract test architecture.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
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
                ["apps/" "framework/" "system/"]) | ...
                string({descriptors.Owner}) == ""));
            testCase.verifyFalse(isfile(fullfile(root, "tests", "runLabKitTests.m")) && ...
                isfile(fullfile(root, "buildfile.m")) && ...
                contains(text(root, "buildfile.m"), "runLabKitTests"));
            testCase.verifyTrue(isfolder(fullfile(root, "tests", "+testfixtures")));
            testCase.verifyFalse(isfolder(fullfile(root, "tests", "shared")));
            testCase.verifyFalse(isfolder(fullfile(root, "tests", "cases")));
            testCase.verifyFalse(isfolder(fullfile(root, "tests", "runner")));
        end

        function ciHasOneDocumentationCheckAndOneAggregateGate(testCase)
            root = labkittest.setup();
            workflow = text(root, ".github/workflows/ci.yml");

            testCase.verifySubstring(workflow, "docs-check:");
            testCase.verifySubstring(workflow, "tasks: docsCheck");
            testCase.verifySubstring(workflow, "ci-gate:");
            testCase.verifySubstring(workflow, "name: CI Gate");
            testCase.verifySubstring(workflow, "docs-check.result");
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

        function testsPassAnExplicitTemporaryJournalToEveryRuntimeFactory(testCase)
            root = labkittest.setup();
            files = dir(fullfile(root, "tests", "**", "*.m"));
            violations = strings(1, 0);
            for index = 1:numel(files)
                file = fullfile(files(index).folder, files(index).name);
                calls = labkittest.runtimeFactoryCalls(fileread(file));
                for call = calls
                    if ~hasExplicitJournal(call)
                        relative = erase(string(file), string(root) + filesep);
                        violations(end + 1) = relative + ":" + ...
                            string(call.Line) + " must pass a fifth journal argument.";
                    end
                end
            end
            testCase.verifyEmpty(violations, strjoin(violations, newline));
        end

        function runtimeFactoryParserRejectsFourthArgumentJournal(testCase)
            source = strjoin([ ...
                "% RuntimeFactory.createMatlab(app) is a comment.", ...
                "literal = ""RuntimeFactory.createHeadless(app)"";", ...
                "runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...", ...
                "    app, [], struct(), journal);"], newline);

            calls = labkittest.runtimeFactoryCalls(source);

            testCase.verifyNumElements(calls, 1);
            testCase.verifyEqual(calls.Method, "createHeadless");
            testCase.verifyNumElements(calls.Arguments, 4);
            testCase.verifyFalse(hasExplicitJournal(calls));
        end

        function runtimeFactoryParserHandlesTransposeAndCharLiterals(testCase)
            source = strjoin([ ...
                "values = [1 2];", ...
                "values.';", ...
                "literal = 'RuntimeFactory.createMatlab(app)';", ...
                "runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...", ...
                "    app, [], struct(""alert"", @(~, ~) []), ...", ...
                "    labkit.app.diagnostic.Options(), journal);"], newline);

            calls = labkittest.runtimeFactoryCalls(source);

            testCase.verifyNumElements(calls, 1);
            testCase.verifyEqual(calls.Method, "createHeadless");
            testCase.verifyNumElements(calls.Arguments, 5);
            testCase.verifyTrue(hasExplicitJournal(calls));
        end
    end
end

function tf = hasExplicitJournal(call)
callArguments = call.Arguments;
tf = numel(callArguments) == 5 && ...
    strlength(callArguments(5)) > 0 && callArguments(5) ~= "[]";
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
