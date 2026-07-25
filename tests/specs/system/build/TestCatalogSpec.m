classdef TestCatalogSpec < matlab.unittest.TestCase
    %TESTCATALOGSPEC Verify catalog metadata and exact owner discovery.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function catalogReturnsExactOwnerAndIdentity(testCase)
            descriptors = labkittest.catalog( ...
                "Owner", "system/build", ...
                "Contract", "system", ...
                "Environment", "headless");

            testCase.verifyGreaterThanOrEqual(numel(descriptors), 4);
            testCase.verifyEqual(string({descriptors.Owner}), ...
                repmat("system/build", 1, numel(descriptors)));
            testCase.verifyTrue(all(contains(string({descriptors.Id}), ...
                "TestCatalogSpec/")));
        end

        function catalogAcceptsWindowsCaseVariantsInTheSpecificationRoot(testCase)
            if ~ispc
                return;
            end
            root = labkittest.setup();
            descriptors = labkittest.catalog( ...
                "SpecsRoot", upper(fullfile(root, "tests", "specs")), ...
                "Owner", "system/build", "Contract", "system", ...
                "Environment", "headless");

            testCase.verifyNotEmpty(descriptors);
            testCase.verifyEqual(string({descriptors.Owner}), ...
                repmat("system/build", 1, numel(descriptors)));
        end

        function catalogRejectsMissingMetadata(testCase)
            specsRoot = testCase.createFixtureTree([ ...
                "classdef ProbeSpec < matlab.unittest.TestCase", ...
                "    methods (Test, TestTags = {'Contract:system'})", ...
                "        function proof(~), end", ...
                "    end", ...
                "end"]);

            testCase.verifyError(@() labkittest.catalog("SpecsRoot", specsRoot), ...
                "LabKit:TestCatalog:InvalidMetadata");
        end

        function planRejectsMissingRequiredContract(testCase)
            testCase.verifyError(@() labkittest.plan( ...
                "Owner", "system/build", "Contract", "scientific", ...
                "Environment", "headless"), "LabKit:TestPlan:MissingContract");
        end

        function explicitPlanRunsEachExactIdentityOnce(testCase)
            specsRoot = testCase.createFixtureTree([ ...
                "classdef ProbeSpec < matlab.unittest.TestCase", ...
                "    methods (Test, TestTags = {'Contract:system', 'Env:headless'})", ...
                "        function proof(testCase), testCase.verifyTrue(true), end", ...
                "    end", ...
                "end"]);
            result = labkittest.run("Owner", "system/probe", ...
                "Contract", "system", "Environment", "headless", ...
                "SpecsRoot", specsRoot);

            testCase.verifyEqual(numel(result.Results), 1);
            testCase.verifyEqual(numel(result.Results{1}), 1);
            testCase.verifyFalse(any([result.Results{1}.Failed]));
        end

        function executorWritesOneRunCenteredArtifactSet(testCase)
            specsRoot = testCase.createFixtureTree([ ...
                "classdef ProbeSpec < matlab.unittest.TestCase", ...
                "    methods (Test, TestTags = {'Contract:system', 'Env:headless'})", ...
                "        function proof(testCase), testCase.verifyTrue(true), end", ...
                "    end", ...
                "end"]);
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            result = labkittest.run("Owner", "system/probe", ...
                "Contract", "system", "Environment", "headless", ...
                "SpecsRoot", specsRoot, "ArtifactsRoot", fixture.Folder, ...
                "RunName", "probe");

            testCase.verifyEqual(result.Artifacts.Folder, ...
                string(fullfile(fixture.Folder, "probe")));
            expected = ["manifest.json", "plan.json", "events.jsonl", ...
                "active-test.json", "junit.xml", "summary.json"];
            for k = 1:numel(expected)
                testCase.verifyEqual(exist(fullfile(result.Artifacts.Folder, ...
                    expected(k)), "file"), 2);
            end
        end

        function executorKeepsRelativeArtifactsReachableDuringTestExecution(testCase)
            specsRoot = testCase.createFixtureTree([ ...
                "classdef ProbeSpec < matlab.unittest.TestCase", ...
                "    methods (Test, TestTags = {'Contract:system', 'Env:headless'})", ...
                "        function proof(testCase), testCase.verifyTrue(true), end", ...
                "    end", ...
                "end"]);
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            previousFolder = pwd;
            cleanup = onCleanup(@() cd(previousFolder));
            cd(fixture.Folder);

            result = labkittest.run("Owner", "system/probe", ...
                "Contract", "system", "Environment", "headless", ...
                "SpecsRoot", specsRoot, "ArtifactsRoot", "relative-artifacts", ...
                "RunName", "probe");
            clear cleanup

            expected = fullfile(fixture.Folder, "relative-artifacts", "probe");
            testCase.verifyEqual(result.Artifacts.Folder, string(expected));
            testCase.verifyEqual(exist(fullfile(expected, "summary.json"), "file"), 2);
        end

        function progressPluginWritesHeartbeatForLongRunningTest(testCase)
            specsRoot = testCase.createFixtureTree([ ...
                "classdef ProbeSpec < matlab.unittest.TestCase", ...
                "    methods (Test, TestTags = {'Contract:system', 'Env:headless'})", ...
                "        function proof(testCase), pause(0.06), testCase.verifyTrue(true), end", ...
                "    end", ...
                "end"]);
            runFolder = fullfile(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder, "run");
            mkdir(runFolder);
            suite = matlab.unittest.TestSuite.fromFolder(specsRoot, ...
                "IncludingSubfolders", true);
            runner = matlab.unittest.TestRunner.withTextOutput("OutputDetail", "terse");
            plugin = labkittest.ProgressPlugin(runFolder, "HeartbeatSeconds", 0.01);
            cleanup = onCleanup(@() delete(plugin));
            runner.addPlugin(plugin);
            results = runner.run(suite);
            clear cleanup

            testCase.assertTrue(all([results.Passed]));
            testCase.verifySubstring(string(fileread(fullfile(runFolder, ...
                "events.jsonl"))), '"event":"heartbeat"');
        end

        function calculationFileRequiresItsBoundedContractClosure(testCase)
            specsRoot = testCase.createCapabilityFixture(true);

            result = labkittest.plan( ...
                "File", "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
                "SpecsRoot", specsRoot);

            testCase.verifyFalse(result.Fallback);
            testCase.verifyEqual(string({result.Descriptors.Contracts}), ...
                ["scientific", "result", "presentation"]);
            testCase.verifyEqual(string({result.Descriptors.Owner}), ...
                ["apps/electrochem/cic/analysisrun", ...
                "apps/electrochem/cic/resultfiles", ...
                "apps/electrochem/cic/workbench"]);
        end

        function multiContractRunWritesOneCompletePlanArtifact(testCase)
            specsRoot = testCase.createCapabilityFixture(true);
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);

            result = labkittest.run("File", ...
                "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
                "SpecsRoot", specsRoot, "ArtifactsRoot", fixture.Folder, ...
                "RunName", "closure");
            plan = jsondecode(fileread(fullfile(result.Artifacts.Folder, "plan.json")));

            testCase.verifyEqual(numel(result.Results{1}), 3);
            testCase.verifyEqual(numel(plan.reasons), 3);
            testCase.verifyEqual(numel(plan.tests), 3);
        end

        function locateGivesAuthorsTheExactCapabilityInsertionFolders(testCase)
            locations = labkittest.locate( ...
                "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m");
            root = labkittest.setup();

            testCase.verifyEqual(string({locations.Owner}), [ ...
                "apps/electrochem/cic/analysisRun", ...
                "apps/electrochem/cic/resultFiles", ...
                "apps/electrochem/cic/workbench"]);
            testCase.verifyTrue(all([locations.AuthorOwned]));
            testCase.verifyEqual(string({locations.Folder}), [ ...
                string(fullfile(root, "tests", "specs", "apps", "electrochem", "cic", "analysisRun")), ...
                string(fullfile(root, "tests", "specs", "apps", "electrochem", "cic", "resultFiles")), ...
                string(fullfile(root, "tests", "specs", "apps", "electrochem", "cic", "workbench"))]);
        end

        function locateMapsPublicFrameworkFacadeToItsOwner(testCase)
            location = labkittest.locate("+labkit/+dta/loadFile.m");
            root = labkittest.setup();

            testCase.verifyEqual(location.Owner, "framework/dta");
            testCase.verifyEqual(location.Contract, "source");
            testCase.verifyEqual(location.Environment, "headless");
            testCase.verifyEqual(location.Folder, string(fullfile(root, ...
                "tests", "specs", "framework", "dta")));
        end

        function locateNormalizesWindowsStyleRepositoryPaths(testCase)
            location = labkittest.locate( ...
                "apps\electrochem\cic\+cic\+analysisRun\computeCIC.m");

            testCase.verifyEqual(string({location.Contract}), ...
                ["scientific", "result", "presentation"]);
        end

        function locateMapsStructuralAppRolesWithoutFileNameHeuristics(testCase)
            analysis = labkittest.locate( ...
                "apps/electrochem/vt_resistance/+vt_resistance/+analysisRun/recomputeItems.m");
            result = labkittest.locate( ...
                "apps/electrochem/vt_resistance/+vt_resistance/+resultFiles/writeResultsCSV.m");
            presentation = labkittest.locate( ...
                "apps/electrochem/vt_resistance/+vt_resistance/+workbench/present.m");
            layout = labkittest.locate( ...
                "apps/electrochem/vt_resistance/+vt_resistance/+workbench/buildLayout.m");
            project = labkittest.locate( ...
                "apps/electrochem/vt_resistance/+vt_resistance/projectSpec.m");
            session = labkittest.locate( ...
                "apps/electrochem/vt_resistance/+vt_resistance/createSession.m");

            testCase.verifyEqual(string({analysis.Contract}), ...
                ["scientific", "result", "presentation"]);
            testCase.verifyEqual([result.Owner, result.Contract], ...
                ["apps/electrochem/vt_resistance/resultFiles", "result"]);
            testCase.verifyEqual([presentation.Owner, presentation.Contract], ...
                ["apps/electrochem/vt_resistance/workbench", "presentation"]);
            testCase.verifyEqual(string({layout.Contract}), ["presentation", "product"]);
            testCase.verifyEqual(string({layout.Environment}), ["", "hidden-gui"]);
            testCase.verifyEqual([project.Owner, project.Contract], ...
                ["apps/electrochem/vt_resistance/project", "persistence"]);
            testCase.verifyEqual([session.Owner, session.Contract], ...
                ["apps/electrochem/vt_resistance/session", "state"]);
        end

        function everyProductionSourceHasAnExplicitEvidenceLocation(testCase)
            root = labkittest.setup();
            files = [ ...
                dir(fullfile(root, "apps", "**", "*.m")); ...
                dir(fullfile(root, "+labkit", "**", "*.m"))];

            testCase.verifyGreaterThan(numel(files), 0);
            for k = 1:numel(files)
                relative = erase(string(fullfile(files(k).folder, files(k).name)), ...
                    string(root) + filesep);
                locations = labkittest.locate(relative);
                testCase.verifyNotEmpty(locations, ...
                    "No test location is defined for " + relative);
            end
        end

        function appLaunchersUseTheDefinitionEvidenceClosure(testCase)
            locations = labkittest.locate( ...
                "apps/electrochem/cic/labkit_CIC_app.m");

            testCase.verifyEqual(string({locations.Contract}), ...
                ["definition", "product", "product"]);
            testCase.verifyEqual(string({locations.Environment}), ...
                ["headless", "hidden-gui", "path-isolated"]);
            testCase.verifyEqual(string({locations.App}), ["cic", "cic", ""]);
        end

        function layoutChangesRecordOneConcreteManualResponsibility(testCase)
            result = labkittest.plan("File", ...
                "apps/electrochem/vt_resistance/+vt_resistance/+workbench/buildLayout.m");

            testCase.verifyEqual(numel(result.ManualChecks), 1);
            testCase.verifySubstring(result.ManualChecks, "Open vt_resistance");
            testCase.verifySubstring(result.ManualChecks, "pointer interaction");
        end

        function workbenchChangesSelectEveryDeclaredPresentationEnvironment(testCase)
            result = labkittest.plan("File", ...
                "apps/image_measurement/image_match/+image_match/+workbench/buildLayout.m");

            imageMatch = contains(string({result.Descriptors.Id}), "ImageMatch");
            testCase.verifyEqual(string({result.Descriptors(imageMatch).Environment}), ...
                ["headless", "headless", "hidden-gui"]);
        end

        function lowerLevelChangesDoNotAcquireGenericManualChecks(testCase)
            result = labkittest.plan("File", ...
                "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m");

            testCase.verifyEmpty(result.ManualChecks);
        end

        function createSpecWritesTheRequiredMetadataAndFailingPlaceholder(testCase)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            specsRoot = fullfile(fixture.Folder, "specs");
            mkdir(specsRoot);

            file = labkittest.createSpec( ...
                "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
                "Contract", "scientific", "Name", "PulseWindow", ...
                "Reason", "Regression LK-0001: pulse window must remain bounded.", ...
                "SpecsRoot", specsRoot);
            source = string(fileread(file));

            testCase.verifyEqual(file, string(fullfile(specsRoot, "apps", ...
                "electrochem", "cic", "analysisRun", "PulseWindowSpec.m")));
            testCase.verifySubstring(source, "Contract:scientific");
            testCase.verifySubstring(source, "Env:headless");
            testCase.verifySubstring(source, "Regression LK-0001");
            testCase.verifySubstring(source, "LabKit:TestSpec:Unimplemented");
        end

        function createSpecInfersTheOnlyContractAndRejectsRealAmbiguity(testCase)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            specsRoot = fullfile(fixture.Folder, "specs");
            mkdir(specsRoot);

            file = labkittest.createSpec( ...
                "apps/electrochem/vt_resistance/+vt_resistance/+resultFiles/writeResultsCSV.m", ...
                "Name", "CsvSchema", ...
                "Reason", "Compatibility: CSV columns are a public export contract.", ...
                "SpecsRoot", specsRoot);

            testCase.verifySubstring(string(fileread(file)), "Contract:result");
            testCase.verifyError(@() labkittest.createSpec( ...
                "apps/electrochem/vt_resistance/+vt_resistance/+analysisRun/recomputeItems.m", ...
                "Name", "ResistancePolicy", ...
                "Reason", "Invariant: recomputation preserves item ownership.", ...
                "SpecsRoot", specsRoot), ...
                "LabKit:TestAuthoring:AmbiguousContract");
        end

        function createSpecRequiresOneDurableReasonCategory(testCase)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            specsRoot = fullfile(fixture.Folder, "specs");
            mkdir(specsRoot);

            testCase.verifyError(@() labkittest.createSpec( ...
                "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
                "Contract", "scientific", "Name", "MissingReason", ...
                "SpecsRoot", specsRoot), "LabKit:TestAuthoring:InvalidReason");
        end

        function calculationFileRejectsMissingContractEvidence(testCase)
            specsRoot = testCase.createCapabilityFixture(false);

            testCase.verifyError(@() labkittest.plan( ...
                "File", "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
                "SpecsRoot", specsRoot), "LabKit:TestPlan:MissingContract");
        end

        function changedProfileCombinesSemanticClosuresWithoutDuplicates(testCase)
            specsRoot = testCase.createCapabilityFixture(true);
            repositoryOwner = fullfile(specsRoot, "system", "repository");
            mkdir(repositoryOwner);
            testCase.writeSpec(repositoryOwner, "RepositoryPolicySpec", "system");

            result = labkittest.plan("Profile", "changed", ...
                "ChangedPaths", [ ...
                "apps/electrochem/cic/+cic/+analysisRun/computeCIC.m", ...
                ".agents/migration_guide.md"], ...
                "SpecsRoot", specsRoot);

            testCase.verifyFalse(result.Fallback);
            testCase.verifyEqual(string({result.Descriptors.Contracts}), ...
                ["scientific", "result", "presentation", "system"]);
            testCase.verifyEqual(numel(unique(string({result.Descriptors.Id}))), 4);
        end

        function scopedAgentPolicySelectsRepositoryEvidence(testCase)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            specsRoot = fullfile(fixture.Folder, "specs");
            repositoryOwner = fullfile(specsRoot, "system", "repository");
            mkdir(repositoryOwner);
            testCase.writeSpec(repositoryOwner, ...
                "RepositoryPolicySpec", "system");

            result = labkittest.plan("Profile", "changed", ...
                "ChangedPaths", "+labkit/AGENTS.md", ...
                "SpecsRoot", specsRoot);

            testCase.verifyEqual(result.Classifications.Role, ...
                "repository-policy");
            testCase.verifyEqual(string({result.Descriptors.Owner}), ...
                "system/repository");
            testCase.verifyEqual(result.Descriptors.Contracts, ...
                "system");
        end

        function unknownChangedPathFailsPlanningInsteadOfWidening(testCase)
            specsRoot = testCase.createEnvironmentFixture();

            testCase.verifyError(@() labkittest.plan("Profile", "changed", ...
                "ChangedPaths", "unmapped-policy.txt", "SpecsRoot", specsRoot), ...
                "LabKit:TestPlan:UnknownOwnership");
        end

        function ignoredDocumentationPathDoesNotInventAutomatedEvidence(testCase)
            result = labkittest.plan("Profile", "changed", ...
                "ChangedPaths", "docs/development/maintain-and-release/testing.md");

            testCase.verifyEqual(result.Scope, "focused-local");
            testCase.verifyEmpty(result.Descriptors);
            testCase.verifyEqual(result.Classifications.Kind, "ignored");
            testCase.verifySubstring(result.Classifications.Reason, "docsCheck");
        end

        function validationFrameworkChangeUsesBoundedSystemEvidence(testCase)
            result = labkittest.plan("Profile", "changed", ...
                "ChangedPaths", "tests/+labkittest/plan.m");

            testCase.verifyEqual(result.Scope, "focused-local");
            testCase.verifyFalse(result.Fallback);
            testCase.verifyEqual(string({result.Descriptors.Owner}), ...
                repmat("system/build", 1, numel(result.Descriptors)));
        end

        function explainChangedReportsClassificationAndExactEvidence(testCase)
            output = evalc("labkittest.explainChanged(""ChangedPaths"", ""tests/+labkittest/plan.m"");");

            testCase.verifySubstring(string(output), "classification: mapped");
            testCase.verifySubstring(string(output), "system/build / system / headless");
        end

        function isolatedProfileSelectsEveryPathIsolatedSpecification(testCase)
            result = labkittest.plan("Profile", "isolated");

            testCase.verifyEqual(numel(result.Descriptors), 1);
            testCase.verifyEqual(result.Descriptors.Environment, "path-isolated");
            testCase.verifySubstring(result.Descriptors.Id, ...
                "AppIsolationConformanceSpec/");
        end

        function changedProfileIncludesTrackedAndUntrackedPreCommitPaths(testCase)
            [repository, specsRoot] = testCase.createGitRepository();
            testCase.writeTextFile(fullfile(repository, "docs", "tracked-source.md"), "changed");
            testCase.writeTextFile(fullfile(repository, "site", "untracked-source.md"), "new");

            result = labkittest.plan("Profile", "changed", ...
                "RepositoryRoot", repository, "SpecsRoot", specsRoot);

            testCase.verifyEqual(string({result.Classifications.Kind}), ["ignored", "ignored"]);
            testCase.verifyTrue(any(contains(string({result.Classifications.Path}), ...
                "tracked-source.md")));
            testCase.verifyTrue(any(contains(string({result.Classifications.Path}), ...
                "untracked-source.md")));
        end

        function changedProfileUsesJustCommittedPathsAfterCleanCheckpoint(testCase)
            [repository, specsRoot] = testCase.createGitRepository();
            testCase.writeTextFile(fullfile(repository, "docs", "checkpoint-source.md"), "changed");
            testCase.runGit(repository, "add docs/checkpoint-source.md");
            testCase.runGit(repository, "commit -m checkpoint");

            result = labkittest.plan("Profile", "changed", ...
                "RepositoryRoot", repository, "SpecsRoot", specsRoot);

            testCase.verifyEqual(result.Classifications.Kind, "ignored");
            testCase.verifySubstring(result.Classifications.Path, "checkpoint-source.md");
        end

        function parameterizedDefinitionsKeepEachPublicAppSelectable(testCase)
            descriptors = labkittest.catalog("Owner", "apps/conformance", ...
                "Contract", "definition", "Environment", "headless");
            apps = labkittest.publicApps();

            testCase.verifyEqual(numel(descriptors), numel(fieldnames(apps)));
            testCase.verifyEqual(numel(unique(string({descriptors.Id}))), ...
                numel(descriptors));
            testCase.verifyTrue(all(contains(string({descriptors.Id}), ...
                "AppDefinitionConformanceSpec/declaresThePublicAppContract")));
        end

        function definitionFileSelectsItsCompleteConformanceEvidence(testCase)
            result = labkittest.plan( ...
                "File", "apps/electrochem/cic/+cic/definition.m");

            testCase.verifyFalse(result.Fallback);
            testCase.verifyEqual(numel(result.Descriptors), 3);
            testCase.verifyEqual(string({result.Descriptors.Id}), [ ...
                "AppDefinitionConformanceSpec/declaresThePublicAppContract(App=cic)", ...
                "AppSmokeConformanceSpec/launchesThroughTheSupportedDefinition(App=cic)", ...
                "AppIsolationConformanceSpec/verifiesEveryPublicAppFromAResetPathBoundary"]);
            testCase.verifyEqual(string({result.Descriptors.Environment}), ...
                ["headless", "hidden-gui", "path-isolated"]);
        end

        function isolatedProbeReportsLaterAppsAfterAnEarlierFailure(testCase)
            apps = labkittest.publicApps();
            valid = apps.cic;
            invalid = valid;
            invalid.Package = "missing_app";
            previousPath = path;
            previousFolder = pwd;

            [status, output] = labkittest.runIsolatedAppProbes([invalid, valid]);

            testCase.verifyNotEqual(status, 0);
            testCase.verifySubstring(string(output), ...
                "ISOLATED_APP_PROBE missing_app FAIL");
            testCase.verifySubstring(string(output), "ISOLATED_APP_PROBE cic PASS");
            testCase.verifyEqual(path, previousPath);
            testCase.verifyEqual(pwd, previousFolder);
        end

        function isolatedProbeDoesNotResolveASiblingAppsLoadedFunction(testCase)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            token = string(randi(10^9));
            first = "isolatedfirst" + token;
            second = "isolatedsecond" + token;
            firstFolder = testCase.writeIsolatedFixtureApp( ...
                fixture.Folder, first, "");
            secondFolder = testCase.writeIsolatedFixtureApp( ...
                fixture.Folder, second, first);
            apps = struct( ...
                "Package", {first, second}, ...
                "Folder", {string(firstFolder), string(secondFolder)});

            [status, output] = labkittest.runIsolatedAppProbes(apps);

            testCase.verifyNotEqual(status, 0);
            testCase.verifySubstring(string(output), ...
                "ISOLATED_APP_PROBE " + first + " PASS");
            testCase.verifySubstring(string(output), ...
                "ISOLATED_APP_PROBE " + second + " FAIL");
        end
    end

    methods (Access = private)
        function specsRoot = createFixtureTree(testCase, lines)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            specsRoot = fullfile(fixture.Folder, "specs");
            owner = fullfile(specsRoot, "system", "probe");
            mkdir(owner);
            file = fullfile(owner, "ProbeSpec.m");
            fid = fopen(file, "w");
            cleanup = onCleanup(@() fclose(fid));
            fprintf(fid, "%s\n", strjoin(lines, newline));
            clear cleanup
        end

        function [repository, specsRoot] = createGitRepository(testCase)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            repository = string(fixture.Folder);
            specsRoot = fullfile(repository, "specs");
            owner = fullfile(specsRoot, "system", "probe");
            guiOwner = fullfile(specsRoot, "system", "gui");
            isolatedOwner = fullfile(specsRoot, "system", "isolated");
            mkdir(owner);
            mkdir(guiOwner);
            mkdir(isolatedOwner);
            testCase.writeSpec(owner, "ProbeSpec", "system");
            testCase.writeSpec(guiOwner, "GuiSpec", "system", "hidden-gui");
            testCase.writeSpec(isolatedOwner, "IsolatedSpec", "system", ...
                "path-isolated");
            testCase.writeTextFile(fullfile(repository, "baseline.m"), "baseline");
            testCase.runGit(repository, "init");
            testCase.runGit(repository, "config user.email labkit-test@example.invalid");
            testCase.runGit(repository, "config user.name LabKitTest");
            testCase.runGit(repository, "add baseline.m specs");
            testCase.runGit(repository, "commit -m baseline");
        end

        function runGit(testCase, repository, gitArguments)
            [status, output] = system(char("git -C " + ...
                testCase.shellQuote(repository) + " " + gitArguments));
            testCase.assertEqual(status, 0, string(output));
        end

        function writeTextFile(~, file, contents)
            folder = fileparts(file);
            if exist(folder, "dir") ~= 7
                mkdir(folder);
            end
            fid = fopen(file, "w");
            cleanup = onCleanup(@() fclose(fid));
            fprintf(fid, "%s\n", contents);
            clear cleanup
        end

        function value = shellQuote(~, value)
            quote = string(char(34));
            value = quote + replace(string(value), quote, "\\" + quote) + quote;
        end

        function specsRoot = createCapabilityFixture(testCase, includePresentation)
            fixture = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            specsRoot = fullfile(fixture.Folder, "specs");
            owner = fullfile(specsRoot, "apps", "electrochem", "cic", ...
                "analysisRun");
            mkdir(owner);
            testCase.writeSpec(owner, "ScientificSpec", "scientific");
            resultOwner = fullfile(specsRoot, "apps", "electrochem", "cic", ...
                "resultFiles");
            mkdir(resultOwner);
            testCase.writeSpec(resultOwner, "ResultSpec", "result");
            if includePresentation
                presentationOwner = fullfile(specsRoot, "apps", "electrochem", ...
                    "cic", "workbench");
                mkdir(presentationOwner);
                testCase.writeSpec(presentationOwner, "PresentationSpec", "presentation");
            end
        end

        function specsRoot = createEnvironmentFixture(testCase)
            specsRoot = testCase.createCapabilityFixture(true);
            guiOwner = fullfile(specsRoot, "system", "gui");
            isolatedOwner = fullfile(specsRoot, "system", "isolated");
            mkdir(guiOwner);
            mkdir(isolatedOwner);
            testCase.writeSpec(guiOwner, "GuiSpec", "system", "hidden-gui");
            testCase.writeSpec(isolatedOwner, "IsolatedSpec", "system", ...
                "path-isolated");
        end

        function writeSpec(~, owner, className, contract, environment)
            if nargin < 5
                environment = "headless";
            end
            file = fullfile(owner, className + ".m");
            source = strjoin([ ...
                "classdef " + className + " < matlab.unittest.TestCase", ...
                "    methods (Test, TestTags = {'Contract:" + contract + ...
                    "', 'Env:" + environment + "'})", ...
                "        function proof(testCase), testCase.verifyTrue(true), end", ...
                "    end", ...
                "end"], newline);
            fid = fopen(file, "w");
            cleanup = onCleanup(@() fclose(fid));
            fprintf(fid, "%s\n", source);
            clear cleanup
        end

        function folder = writeIsolatedFixtureApp(testCase, root, package, sibling)
            folder = fullfile(root, package);
            packageFolder = fullfile(folder, "+" + package);
            mkdir(packageFolder);
            dependency = [ ...
                "function onlyFromFirst()", ...
                "end"];
            testCase.writeTextFile(fullfile(packageFolder, "onlyFromFirst.m"), ...
                strjoin(dependency, newline));
            prefix = strings(1, 0);
            if strlength(sibling) > 0
                prefix = sibling + ".onlyFromFirst();";
            end
            definition = [ ...
                "function app = definition()", ...
                prefix, ...
                "app = struct( ...", ...
                "    'AppId', """ + package + """, ...", ...
                "    'AppVersion', ""1.0.0"", ...", ...
                "    'Requirements', labkit.contract.requirements(""app"", "">=1 <2""), ...", ...
                "    'BuildDebugSample', @(context) labkit.app.diagnostic.SamplePack( ...", ...
                "        Scenario=""fixture"", InitialProject=struct(), Artifacts={}));", ...
                "end"];
            testCase.writeTextFile(fullfile(packageFolder, "definition.m"), ...
                strjoin(definition, newline));
        end
    end
end
