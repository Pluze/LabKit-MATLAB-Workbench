classdef Mark10AcquisitionSpec < matlab.unittest.TestCase
    %MARK10ACQUISITIONSPEC Specify monitor rate and bounded buffer defaults.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function mapsDeclaredRatesAndCreatesEmptyBuffer(testCase)
            buffer = mark10_monitor.acquisition.createBuffer();

            labels = ["10 Hz", "20 Hz", "30 Hz", "40 Hz", "50 Hz"];
            periods = arrayfun(@mark10_monitor.acquisition.ratePeriod, labels);
            testCase.verifyEqual(periods, 1 ./ [10, 20, 30, 40, 50], ...
                "AbsTol", eps);
            testCase.verifyEqual(mark10_monitor.viewRefreshPeriod(), 0.034);
            testCase.verifyEmpty(buffer("plotTime_s"));
            testCase.verifyFalse(buffer("recording"));
            testCase.verifyEqual(buffer("lastRefresh_s"), -Inf);
            testCase.verifyError(@() ...
                mark10_monitor.acquisition.ratePeriod("unsupported"), ...
                "mark10_monitor:InvalidRate");
        end

        function highRateSamplingDoesNotForceOnePresentationPerSample(testCase)
            posts = containers.Map("KeyType", "char", "ValueType", "any");
            posts("count") = 0;
            context = labkittest.createCallbackContext(struct( ...
                "postEvent", @(~, ~) increment(posts)));
            transport = struct( ...
                "Write", @(~) [], "Flush", @() [], ...
                "ReadUntil", @(~, ~) uint8(sprintf('1.00 N\r\n2.00 mm\r\n')), ...
                "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
                "Close", @() [], "IsOpen", @() true);
            connection = struct( ...
                "Type", "labkit.mark10.connection", "Port", "SYNTHETIC", ...
                "Timeout", 0.01, "Transport", transport, ...
                "Identity", struct(), "Capabilities", struct(), ...
                "Settings", struct(), "RestoreAutoOutput", "AOUT0", ...
                "AcquisitionMode", "Unknown", "SampleCount", uint64(0), ...
                "LastFailure", struct("Status", "", "Message", ""));
            connectionBox = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
            connectionBox("connection") = connection;
            buffer = mark10_monitor.acquisition.createBuffer();
            buffer("lastRefresh_s") = Inf;

            for index = 1:50
                mark10_monitor.acquisition.poll( ...
                    connectionBox, buffer, context);
            end
            testCase.verifyEqual(buffer("sampleCount"), 50);
            testCase.verifyEqual(posts("count"), 0);

            buffer("lastRefresh_s") = -Inf;
            mark10_monitor.acquisition.poll(connectionBox, buffer, context);
            testCase.verifyEqual(posts("count"), 1);
        end
    end
end

function increment(posts)
posts("count") = posts("count") + 1;
end
