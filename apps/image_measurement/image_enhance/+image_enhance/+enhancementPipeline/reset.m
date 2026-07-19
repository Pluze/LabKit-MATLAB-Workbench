function state=reset(state,~)
state.project.annotations.sharedSteps=repmat(image_enhance.analysisRun.emptyStep(),0,1);
end
