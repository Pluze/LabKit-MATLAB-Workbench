classdef TestArchitectureSpec < matlab.unittest.TestCase
    %TESTARCHITECTURESPEC Specify one active owner/contract test architecture.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function activeEntryPointsDescribeOnlyTheCatalogModel(testCase)
            root = labkittest.setup();
            build = text(root, "buildfile.m");
            guide = text(root, "docs/development/maintain-and-release/testing.md");
            skill = text(root, ".agents/skills/labkit-test-planner/SKILL.md");
            testsGuide = text(root, "tests/AGENTS.md");

            testCase.verifySubstring(build, "labkittest.run");
            testCase.verifyFalse(contains(build, "runLabKitTests"));
            testCase.verifyFalse(contains(build, "tests/runner"));
            for active = [guide skill testsGuide]
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

        function trackedTextDoesNotContainLocalSamplePathOrTimestampTokens(testCase)
            root = labkittest.setup();
            files = trackedTextFiles(root);
            homes = unique(string({getenv("HOME"), getenv("USERPROFILE")}));

            testCase.verifyNotEmpty(files);
            for index = 1:numel(files)
                file = files(index);
                content = string(fileread(fullfile(root, file)));
                testCase.verifyEmpty(regexp(content, "(?<![A-Za-z])[A-Za-z]:[\\\\/]", "once"), ...
                    "Tracked text contains a drive-root path: " + file);
                testCase.verifyEmpty(regexp(content, "\\d{8}_\\d{6}", "once"), ...
                    "Tracked text contains a sample timestamp token: " + file);
                for home = homes
                    if strlength(home) > 3
                        testCase.verifyFalse(contains(content, home), ...
                            "Tracked text contains a local home path: " + file);
                    end
                end
            end
        end
    end
end

function value = text(root, relative)
value = string(fileread(fullfile(root, relative)));
end

function files = trackedTextFiles(root)
[status, output] = system("git -C " + shellQuote(root) + " ls-files");
if status ~= 0
    error("LabKit:RepositoryGuardrail:GitListFailed", ...
        "Could not list tracked repository files.");
end
files = splitlines(string(output));
files = files(strlength(files) > 0);
extensions = [".m" ".md" ".json" ".yml" ".yaml" ".txt"];
files = files(endsWith(lower(files), extensions));
end

function value = shellQuote(value)
value = '"' + replace(string(value), '"', '\\"') + '"';
end
