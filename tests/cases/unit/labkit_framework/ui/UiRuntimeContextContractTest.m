classdef UiRuntimeContextContractTest < matlab.unittest.TestCase
    methods (Test)
        function noCapabilityContextRejectsOperations(testCase)
            setupLabKitTestPath();
            context = labkit.app.CallbackContext();

            testCase.verifyTrue(meta.class.fromName( ...
                "labkit.app.CallbackContext").Sealed);
            testCase.verifyError(@() context.alert("message", "title"), ...
                "labkit:app:runtime:InvariantFailure");
        end

        function namedOperationsUseOneSealedBackend(testCase)
            setupLabKitTestPath();
            app = application();
            store = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct( ...
                "appendStatus", @appendStatus, ...
                "choose", @choose, ...
                "sourcePaths", @sourcePaths, ...
                "setResource", @setResource, ...
                "getResource", @getResource, ...
                "removeResource", @removeResource, ...
                "clearResourceScope", @clearResourceScope);
            context = labkit.app.CallbackContext.createForRuntime(app, backend);
            context.appendStatus("ready");
            choice = context.chooseOption("Continue?", ["yes", "no"]);
            context.setResource("document", "reader", 42, []);
            value = context.getResource("document", "reader");
            paths = context.resolveSourcePaths(struct(), ["first", "second"]);

            testCase.verifyEqual(choice.Value, "yes");
            testCase.verifyEqual(value, 42);
            testCase.verifyEqual(store("status"), "ready");
            testCase.verifyEqual(paths, ["first"; "second"] + ".dat");
            testCase.verifyError(@() context.reportError( ...
                "operation", MException("probe:error", "failure")), ...
                "labkit:app:runtime:InvariantFailure");
            function appendStatus(message)
                store("status") = message;
            end

            function result = choose(~, choices)
                result = labkit.app.dialog.Choice(choices(1));
            end

            function paths = sourcePaths(~, ids)
                paths = ids + ".dat";
            end

            function setResource(scope, id, resource, ~)
                store(char(scope + ":" + id)) = resource;
            end

            function resource = getResource(scope, id)
                resource = store(char(scope + ":" + id));
            end

            function removeResource(scope, id)
                remove(store, char(scope + ":" + id));
            end

            function clearResourceScope(scope)
                keys = string(store.keys);
                selected = startsWith(keys, scope + ":");
                remove(store, cellstr(keys(selected)));
            end
        end
    end
end

function app = application()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_Probe_app", AppId="probe.context", ...
        Title="Probe", Family="Tests", AppVersion="1.0.0", ...
        Updated="2026-07-19", Requirements=[], ...
        Workbench=labkit.app.layout.workbench({}));
end
