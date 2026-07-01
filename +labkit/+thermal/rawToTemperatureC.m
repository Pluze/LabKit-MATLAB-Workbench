function temperatureC = rawToTemperatureC(raw, calibration, opts)
%RAWTOTEMPERATUREC Convert FLIR raw sensor values to Celsius.
%
% App-facing contract:
%   temperatureC = labkit.thermal.rawToTemperatureC(raw, calibration)
%   temperatureC = labkit.thermal.rawToTemperatureC(raw, calibration, opts)
%
% Inputs:
%   raw - numeric raw sensor matrix.
%   calibration - scalar struct with PlanckR1, PlanckB, PlanckF, PlanckO,
%       PlanckR2, and optional environmental fields Emissivity,
%       ObjectDistanceM, ReflectedApparentTemperatureC,
%       AtmosphericTemperatureC, IRWindowTemperatureC, IRWindowTransmission,
%       RelativeHumidity, AtmosphericTransAlpha1/2, AtmosphericTransBeta1/2,
%       and AtmosphericTransX.
%   opts - optional scalar struct with field Correction: "environment" or
%       "planck-basic", default "environment".
%
% Outputs:
%   temperatureC - double matrix in degrees Celsius. Invalid conversion pixels
%       become NaN.

    if nargin < 3 || isempty(opts)
        opts = struct();
    end
    mode = string(optionValue(opts, 'Correction', "environment"));
    if ~any(mode == ["environment", "planck-basic"])
        error('labkit:thermal:InvalidOptions', ...
            'Correction must be "environment" or "planck-basic".');
    end
    assertPlanckCalibration(calibration);

    raw = double(raw);
    if mode == "environment"
        rawObject = environmentCorrectedRaw(raw, calibration);
    else
        rawObject = raw;
    end
    temperatureC = planckTemperature(rawObject, calibration);
end

function assertPlanckCalibration(calibration)
    required = ["PlanckR1", "PlanckB", "PlanckF", "PlanckO", "PlanckR2"];
    for k = 1:numel(required)
        field = required(k);
        if ~isfield(calibration, field) || ~isfinite(double(calibration.(field)))
            error('labkit:thermal:MissingCalibration', ...
                'Missing FLIR calibration field: %s', field);
        end
    end
end

function rawObject = environmentCorrectedRaw(raw, calibration)
    E = scalarField(calibration, 'Emissivity', 1);
    OD = scalarField(calibration, 'ObjectDistanceM', 1);
    RTemp = scalarField(calibration, 'ReflectedApparentTemperatureC', 20);
    ATemp = scalarField(calibration, 'AtmosphericTemperatureC', 20);
    IRWTemp = scalarField(calibration, 'IRWindowTemperatureC', RTemp);
    IRT = scalarField(calibration, 'IRWindowTransmission', 1);
    RH = scalarField(calibration, 'RelativeHumidity', 0.5);
    if RH > 2
        RH = RH / 100;
    end
    ATA1 = scalarField(calibration, 'AtmosphericTransAlpha1', 0.006569);
    ATA2 = scalarField(calibration, 'AtmosphericTransAlpha2', 0.01262);
    ATB1 = scalarField(calibration, 'AtmosphericTransBeta1', -0.002276);
    ATB2 = scalarField(calibration, 'AtmosphericTransBeta2', -0.00667);
    ATX = scalarField(calibration, 'AtmosphericTransX', 1.9);

    E = clampPositive(E, 1);
    IRT = clampPositive(IRT, 1);
    OD = max(0, double(OD));
    h2o = RH .* exp(1.5587 + 0.06939 .* ATemp - ...
        0.00027816 .* ATemp.^2 + 0.00000068455 .* ATemp.^3);
    h2o = max(0, h2o);
    tau1 = atmosphericTau(OD / 2, h2o, ATA1, ATA2, ATB1, ATB2, ATX);
    tau2 = atmosphericTau(OD / 2, h2o, ATA1, ATA2, ATB1, ATB2, ATX);
    tau1 = clampPositive(tau1, 1);
    tau2 = clampPositive(tau2, 1);

    rawRefl1 = rawFromTemperatureC(RTemp, calibration);
    rawAtm1 = rawFromTemperatureC(ATemp, calibration);
    rawWindow = rawFromTemperatureC(IRWTemp, calibration);
    rawRefl2 = rawFromTemperatureC(RTemp, calibration);
    rawAtm2 = rawFromTemperatureC(ATemp, calibration);

    emissWindow = 1 - IRT;
    reflWindow = 0;
    rawObject = raw ./ E ./ tau1 ./ IRT ./ tau2 - ...
        (1 - E) ./ E .* rawRefl1 - ...
        (1 - tau1) ./ E ./ tau1 .* rawAtm1 - ...
        emissWindow ./ E ./ tau1 ./ IRT .* rawWindow - ...
        reflWindow ./ E ./ tau1 ./ IRT .* rawRefl2 - ...
        (1 - tau2) ./ E ./ tau1 ./ IRT ./ tau2 .* rawAtm2;
end

function tau = atmosphericTau(distancePart, h2o, alpha1, alpha2, beta1, beta2, x)
    distanceRoot = sqrt(max(0, distancePart));
    h2oRoot = sqrt(max(0, h2o));
    tau = x .* exp(-distanceRoot .* (alpha1 + beta1 .* h2oRoot)) + ...
        (1 - x) .* exp(-distanceRoot .* (alpha2 + beta2 .* h2oRoot));
end

function raw = rawFromTemperatureC(temperatureC, calibration)
    kelvin = double(temperatureC) + 273.15;
    raw = calibration.PlanckR1 ./ ...
        (calibration.PlanckR2 .* (exp(calibration.PlanckB ./ kelvin) - ...
        calibration.PlanckF)) - calibration.PlanckO;
end

function temperatureC = planckTemperature(rawObject, calibration)
    denominator = calibration.PlanckR2 .* (rawObject + calibration.PlanckO);
    argument = calibration.PlanckR1 ./ denominator + calibration.PlanckF;
    temperatureC = calibration.PlanckB ./ log(argument) - 273.15;
    temperatureC(~isfinite(temperatureC) | argument <= 0 | denominator <= 0) = NaN;
end

function value = scalarField(calibration, field, defaultValue)
    value = defaultValue;
    if isfield(calibration, field) && ~isempty(calibration.(field)) && ...
            isfinite(double(calibration.(field)))
        value = double(calibration.(field));
    end
end

function value = clampPositive(value, fallback)
    value = double(value);
    if ~isfinite(value) || value <= 0
        value = fallback;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
