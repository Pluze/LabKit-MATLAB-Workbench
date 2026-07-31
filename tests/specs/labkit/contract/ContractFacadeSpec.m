classdef ContractFacadeSpec < matlab.unittest.TestCase
    %CONTRACTFACADESPEC Specify facade requirement and version compatibility.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function normalizesRequirementPairsAndRejectsAmbiguity(testCase)
            requirements = labkit.contract.requirements( ...
                "LABKIT.APP", " >=1 <2 ", ...
                "image", ">=4 <5");

            testCase.verifyEqual([requirements.facades.facade], ["app" "image"]);
            testCase.verifyEqual([requirements.facades.range], [">=1 <2" ">=4 <5"]);
            testCase.verifyError( ...
                @() labkit.contract.requirements("app", ">=1", "APP", "<2"), ...
                "labkit:contract:DuplicateRequirement");
            testCase.verifyError( ...
                @() labkit.contract.requirements("app"), ...
                "labkit:contract:InvalidRequirements");
        end

        function requiresCurrentVersionAndAdvertisedRangeCompatibility(testCase)
            available = labkit.contract.versionInfo( ...
                "app", "2.2.1", ">=2 <3", "stable", "Synthetic App SDK.");

            compatible = labkit.contract.checkRequirements( ...
                labkit.contract.requirements("app", ">=2.1 <2.5"), available);
            future = labkit.contract.checkRequirements( ...
                labkit.contract.requirements("app", ">=2.9 <3"), available);
            unsupported = labkit.contract.versionInfo( ...
                "app", "5.0.0", ">=2 <3", "stable", "Synthetic App SDK.");
            disjoint = labkit.contract.checkRequirements( ...
                labkit.contract.requirements("app", ">=5 <6"), unsupported);

            testCase.verifyTrue(compatible.ok, compatible.message);
            testCase.verifyFalse(future.ok);
            testCase.verifySubstring(future.message, ...
                "current 2.2.1 does not satisfy");
            testCase.verifyFalse(disjoint.ok);
            testCase.verifySubstring(disjoint.message, ...
                "supports >=2 <3, but the app requires >=5 <6");
        end

        function reportsUnknownFacadesAndAssertionFailures(testCase)
            available = labkit.contract.versionInfo( ...
                "image", "4.1.0", ">=4 <5", "stable", "Synthetic image facade.");
            requirements = labkit.contract.requirements("missing", ">=1 <2");
            report = labkit.contract.checkRequirements(requirements, available);

            testCase.verifyFalse(report.ok);
            testCase.verifyEqual(report.failures.facade, "missing");
            testCase.verifyEmpty(report.failures.available);
            testCase.verifySubstring(report.message, "Unknown LabKit facade");
            testCase.verifyError(@() labkit.contract.assertRequirements( ...
                "probe_app", requirements, available), ...
                "probe_app:IncompatibleLabKit");
        end

        function createsNormalizedVersionInformation(testCase)
            info = labkit.contract.versionInfo( ...
                "LabKit.Image", "4.1.0", [">=4 <5" ""], ...
                "STABLE", "Image facade.");

            testCase.verifyEqual(info.name, "labkit.image");
            testCase.verifyEqual(info.facade, "image");
            testCase.verifyEqual(info.compatible, ">=4 <5");
            testCase.verifyEqual(info.status, "stable");
            testCase.verifyError(@() labkit.contract.versionInfo( ...
                "image", "4.1.0", ">=4 <5", "unknown", "Image facade."), ...
                "labkit:contract:InvalidVersionInfo");
        end
    end
end
