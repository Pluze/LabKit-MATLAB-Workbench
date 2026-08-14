classdef Mark10ActionsSpec < matlab.unittest.TestCase
    %MARK10ACTIONSSPEC Specify mode-gated software travel zero behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function adoptsSoftwareZeroWhenStandStatusIsUnavailable(testCase)
            command = containers.Map("KeyType", "char", "ValueType", "any");
            command("value") = "";
            connection = Mark10ActionsSpec.connection(command);
            box = containers.Map("KeyType", "char", "ValueType", "any");
            box("connection") = connection;
            backend = struct( ...
                "getResource", @(~, ~) box, ...
                "alert", @(~, ~) []);
            context = labkittest.createCallbackContext(backend);
            state = struct("session", struct( ...
                "acquisition", struct("travelZeroOffset_mm", 0), ...
                "connection", struct("status", "", "lastFailure", "")));

            state = mark10_monitor.actions.zeroTravel(state, context);

            testCase.verifyEqual( ...
                state.session.acquisition.travelZeroOffset_mm, 2);
            testCase.verifySubstring(state.session.connection.status, ...
                "software zero active");
        end
    end

    methods (Static, Access = private)
        function value = connection(command)
            transport = struct( ...
                "Write", @(bytes) Mark10ActionsSpec.write(command, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(~, ~) Mark10ActionsSpec.read(command), ...
                "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
                "Close", @() [], "IsOpen", @() true);
            value = struct("Type", "labkit.mark10.connection", ...
                "Port", "SYNTHETIC", "Timeout", 0.01, ...
                "Transport", transport, "Identity", struct(), ...
                "Capabilities", struct(), "Settings", struct(), ...
                "RestoreAutoOutput", "AOUT0", "AcquisitionMode", "Unknown", ...
                "SampleCount", uint64(0), ...
                "LastFailure", struct("Status", "", "Message", ""));
        end

        function write(command, bytes)
            command("value") = string(native2unicode(uint8(bytes(:).'), "UTF-8"));
        end

        function raw = read(command)
            if command("value") == "x"
                raw = uint8(sprintf('2.00 mm\r\n'));
            else
                raw = uint8([]);
            end
        end
    end
end
