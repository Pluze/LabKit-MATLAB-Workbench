function tf = labkitOfficialResultsHaveFailures(results)
%LABKITOFFICIALRESULTSHAVEFAILURES Distinguish failures from assumption skips.
%
% Called by runLabKitTests after matlab.unittest execution. The input is a
% TestResult array, or a struct-shaped test double with a logical Failed field.
% Returns true only when at least one result is an actual test failure.

    tf = ~isempty(results) && any([results.Failed]);
end
