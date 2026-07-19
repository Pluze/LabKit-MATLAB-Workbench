% App numeric helper; returns one Student-t quantile using Base MATLAB beta functions.
function value = studentTQuantile(probability, degreesOfFreedom)
%STUDENTTQUANTILE Evaluate one Student-t quantile with Base MATLAB.
%
% Expected callers: runTTest and plot-summary preparation. probability is a
% finite scalar strictly between zero and one; degreesOfFreedom is positive.
% The returned scalar uses the inverse incomplete beta relationship. Side
% effects are none.

    assert(isnumeric(probability) && isscalar(probability) && ...
        isfinite(probability) && probability > 0 && probability < 1 && ...
        isnumeric(degreesOfFreedom) && isscalar(degreesOfFreedom) && ...
        isfinite(degreesOfFreedom) && degreesOfFreedom > 0, ...
        'ttest_wizard:InvalidTDistributionParameters', ...
        'Student-t probability and degrees of freedom are invalid.');
    if probability == 0.5
        value = 0;
        return;
    end
    tailProbability = min(probability, 1 - probability);
    betaArgument = betaincinv(2 * tailProbability, ...
        degreesOfFreedom / 2, 0.5);
    magnitude = sqrt(degreesOfFreedom * ...
        (1 / betaArgument - 1));
    if probability < 0.5
        value = -magnitude;
    else
        value = magnitude;
    end
end
