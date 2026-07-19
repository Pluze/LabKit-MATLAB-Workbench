classdef UiRuntimeContextContractTest < matlab.unittest.TestCase
    methods (Test)
        function noCapabilityContextRejectsOperations(testCase)
            setupLabKitTestPath();
            context = labkit.ui.RuntimeContext();

            testCase.verifyTrue(meta.class.fromName( ...
                "labkit.ui.RuntimeContext").Sealed);
            testCase.verifyError(@() context.alert("message", "title"), ...
                "labkit:ui:runtime:InvariantFailure");
        end

        function declaredCapabilitiesUseOneSealedBackend(testCase)
            setupLabKitTestPath();
            command = labkit.ui.Command("run", @runCommand);
            app = applicationWith(command, ...
                ["dispatch", "workflow", "dialogs", "project", "resources"]);
            store = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct( ...
                "dispatch", @dispatch, ...
                "appendStatus", @appendStatus, ...
                "choose", @choose, ...
                "sourcePaths", @sourcePaths, ...
                "setResource", @setResource, ...
                "getResource", @getResource, ...
                "removeResource", @removeResource, ...
                "clearResourceScope", @clearResourceScope);
            context = labkit.ui.RuntimeContext.createForRuntime(app, backend);
            context.appendStatus("ready");
            choice = context.choose("Continue?", ["yes", "no"]);
            context.setResource("document", "reader", 42, []);
            value = context.getResource("document", "reader");
            context.dispatch(command, []);
            paths = context.sourcePaths(struct(), ["first", "second"]);

            testCase.verifyEqual(choice.Value, "yes");
            testCase.verifyEqual(value, 42);
            testCase.verifyEqual(store("status"), "ready");
            testCase.verifyEqual(paths, ["first"; "second"] + ".dat");
            testCase.verifyError(@() context.reportError( ...
                "operation", MException("probe:error", "failure")), ...
                "labkit:ui:runtime:InvariantFailure");
            testCase.verifyError(@() context.dispatch( ...
                labkit.ui.Command("other", @runCommand), []), ...
                "labkit:ui:contract:UnknownReference");

            function dispatch(~, ~)
            end

            function appendStatus(message)
                store("status") = message;
            end

            function result = choose(~, choices)
                result = labkit.ui.DialogResult(choices(1));
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

function app = applicationWith(command, capabilities)
    app = labkit.ui.Application( ...
        Command="labkit_Probe_app", Id="probe.context", ...
        Title="Probe", Family="Tests", AppVersion="1.0.0", ...
        Updated="2026-07-19", Requirements=[], ...
        Layout=labkit.ui.Layout.workbench({}), ...
        ExtraCommands={command}, Capabilities=capabilities);
end

function state = runCommand(state, ~)
end
