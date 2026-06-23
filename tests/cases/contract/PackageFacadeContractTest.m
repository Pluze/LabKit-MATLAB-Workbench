classdef PackageFacadeContractTest < matlab.unittest.TestCase
    %PACKAGEFACADECONTRACTTEST Verify LabKit facade version contracts.

    methods (Test, TestTags = {'Integration', 'Style'})
        function facadeVersionsAreValid(testCase)
            setupLabKitTestPath();
            versions = currentVersions();
            expectedFacades = ["ui"; "dta"; "rhs"; "biosignal"];

            testCase.verifyEqual(sort([versions.facade].'), sort(expectedFacades));
            for k = 1:numel(versions)
                info = versions(k);
                testCase.verifyEqual(info.name, "labkit." + info.facade);
                testCase.verifyMatches(info.current, "^\d+(\.\d+){0,2}$");
                testCase.verifyTrue(any(info.status == ["stable", "deprecated", "experimental"]));
                testCase.verifyNotEmpty(info.compatible);
                testCase.verifyTrue(all(contains(info.compatible, "<")), ...
                    "Facade compatibility ranges should use upper bounds: " + info.name);
                testCase.verifyGreaterThan(strlength(info.notes), 0);
            end
        end

        function appRequirementsPassCurrentFacades(testCase)
            root = setupLabKitTestPath();
            versions = currentVersions();
            knownFacades = [versions.facade];
            apps = collectAppEntrypoints(root);

            testCase.verifyNotEmpty(apps, 'Contract test should discover app entrypoints.');
            for k = 1:numel(apps)
                req = feval(apps(k).functionName, "requirements");
                validateRequirementShape(testCase, req, apps(k).functionName);
                facades = [req.facades.facade];
                testCase.verifyEmpty(setdiff(facades, knownFacades), ...
                    apps(k).functionName + " references unknown LabKit facades.");
                report = labkit.contract.checkRequirements(req, versions);
                testCase.verifyTrue(report.ok, ...
                    apps(k).functionName + " requirements should pass current LabKit: " + report.message);
            end
        end

        function appVersionsAreValidAndExposed(testCase)
            root = setupLabKitTestPath();
            apps = collectAppEntrypoints(root);

            testCase.verifyNotEmpty(apps, 'Contract test should discover app entrypoints.');
            for k = 1:numel(apps)
                info = feval(apps(k).functionName, "version");
                validateAppVersionShape(testCase, info, apps(k).functionName);
            end
        end

        function incompatibleRequirementsProduceClearFailures(testCase)
            setupLabKitTestPath();
            req = labkit.contract.requirements("ui", ">=99.0 <100");
            report = labkit.contract.checkRequirements(req);

            testCase.verifyFalse(report.ok);
            testCase.verifyTrue(contains(report.message, "labkit.ui"));
            testCase.verifyTrue(contains(report.message, "requires >=99.0 <100"));
            testCase.verifyError(@() labkit.contract.assertRequirements("probe_app", req), ...
                'probe_app:IncompatibleLabKit');
            testCase.verifyError(@() labkit.ui.app.dispatchRequest( ...
                "probe_app", {}, 0, "Requirements", req), ...
                'probe_app:IncompatibleLabKit');
            testCase.verifyError(@() labkit.ui.app.dispatchRequest( ...
                "probe_app", {"debug"}, 0, "Requirements", req), ...
                'probe_app:IncompatibleLabKit');
        end
    end
end

function validateAppVersionShape(testCase, info, appName)
    testCase.verifyTrue(isstruct(info) && isscalar(info), ...
        appName + " version request should return one app version struct.");
    requiredFields = ["name", "displayName", "family", "version", "updated"];
    for k = 1:numel(requiredFields)
        field = requiredFields(k);
        testCase.verifyTrue(isfield(info, field), ...
            appName + " version should include " + field + ".");
        value = info.(field);
        testCase.verifyTrue(ischar(value) || (isstring(value) && isscalar(value)), ...
            appName + " version field " + field + " should be scalar text.");
        testCase.verifyGreaterThan(strlength(strtrim(string(value))), 0, ...
            appName + " version field " + field + " should be nonempty.");
    end
    testCase.verifyEqual(string(info.name), appName);
    testCase.verifyMatches(string(info.version), "^\d+\.\d+\.\d+$");
    testCase.verifyMatches(string(info.updated), "^\d{4}-\d{2}-\d{2}$");
end

function versions = currentVersions()
    versions = [
        labkit.ui.version()
        labkit.dta.version()
        labkit.rhs.version()
        labkit.biosignal.version()];
end

function validateRequirementShape(testCase, req, appName)
    testCase.verifyTrue(isstruct(req) && isfield(req, 'type') && ...
        req.type == "labkit.requirements", ...
        appName + " should return a labkit.contract.requirements struct.");
    testCase.verifyTrue(isfield(req, 'facades') && isstruct(req.facades), ...
        appName + " requirements should expose facade entries.");
    testCase.verifyNotEmpty(req.facades, ...
        appName + " should declare at least one facade dependency.");
    testCase.verifyTrue(all(contains([req.facades.range], "<")), ...
        appName + " requirements should use upper bounds.");
end

function apps = collectAppEntrypoints(root)
    listing = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
    apps = repmat(struct('functionName', ""), 0, 1);
    for k = 1:numel(listing)
        if ~listing(k).isdir
            [~, name] = fileparts(listing(k).name);
            apps(end+1, 1).functionName = string(name);
        end
    end
end
