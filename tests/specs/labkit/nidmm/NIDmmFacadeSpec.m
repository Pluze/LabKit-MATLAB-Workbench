classdef NIDmmFacadeSpec < matlab.unittest.TestCase
    % NIDMMFACADESPEC Invariant: NI-DMM configuration, runtime diagnostics, sampling, and failures remain MATLAB-native facade contracts.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesNIDmmFacade(testCase)
            info = labkit.nidmm.version();
            testCase.verifyEqual(info.current, "1.0.0");

            status = labkit.nidmm.availability();
            testCase.verifyTrue(all(isfield(status, ["Available", "Status", ...
                "Message", "DriverVersion", "RequiredComponent"])));
            testCase.verifyClass(status.Available, "logical");

            calls = containers.Map("KeyType", "char", "ValueType", "any");
            calls("mode") = "";
            calls("range") = [];
            calls("digits") = [];
            backend = struct( ...
                "configure", @(mode, range, digits) configureFake( ...
                    calls, mode, range, digits), ...
                "measurementPeriod", @() 0.016, ...
                "read", @readFake, "close", @() []);
            connection = fakeConnection(backend);

            [connection, configuration] = labkit.nidmm.configure(connection, ...
                Mode="resistance_4wire", Range="auto", Digits=5.5);
            testCase.verifyEqual(calls("mode"), "resistance_4wire");
            testCase.verifyEqual(calls("range"), "auto");
            testCase.verifyEqual(calls("digits"), 5.5);
            testCase.verifyEqual(configuration.Range, 1000);
            testCase.verifyEqual(configuration.RangeMode, "auto_locked");
            testCase.verifyEqual(configuration.Unit, "ohm");
            testCase.verifyEqual(configuration.MeasurementPeriod_s, 0.016);

            [~, sample] = labkit.nidmm.readSample(connection);
            testCase.verifyTrue(sample.Valid);
            testCase.verifyEqual(sample.Value, 200.25);
            testCase.verifyEqual(sample.Unit, "ohm");
            testCase.verifyEqual(sample.TimeUncertainty_s, 0.003);
            testCase.verifyEqual(string(sample.TimestampUTC.TimeZone), "UTC");
            testCase.verifyClass(sample.Value, "double", ...
                "Vendor runtime objects must not cross the facade boundary.");

            testCase.verifyError(@() labkit.nidmm.configure(connection, ...
                Mode="wrong"), "labkit:nidmm:InvalidMode");
            testCase.verifyError(@() labkit.nidmm.configure(connection, ...
                Range=-1), "labkit:nidmm:InvalidRange");
            testCase.verifyError(@() labkit.nidmm.configure(connection, ...
                Digits=7.5), "labkit:nidmm:InvalidDigits");
        end
    end
end

function value = fakeConnection(backend)
state = containers.Map("KeyType", "char", "ValueType", "any");
state("backend") = backend;
state("configured") = false;
state("configuration") = struct();
state("closed") = false;
value = struct("Type", "labkit.nidmm.connection", "Resource", "SYNTHETIC", ...
    "Model", "Synthetic DMM", "DriverVersion", "0", "State", state);
end

function value = configureFake(calls, mode, range, digits)
calls("mode") = mode;
calls("range") = range;
calls("digits") = digits;
assert(calls("digits") == digits);
value = 1000;
end

function value = readFake()
received = datetime(2026, 1, 2, 3, 4, 5, "TimeZone", "UTC");
value = struct("Value", 200.25, ...
    "TimestampUTC", received - seconds(0.003), ...
    "ReceivedAtUTC", received, "TimeUncertainty_s", 0.003);
end
