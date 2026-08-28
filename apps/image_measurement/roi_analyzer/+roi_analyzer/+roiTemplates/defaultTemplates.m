function templates = defaultTemplates()
%DEFAULTTEMPLATES Create the initial shared 20-by-20 rectangle template.
templates = roi_analyzer.roiTemplates.emptyTemplate();
templates.id = "template-1";
templates.name = "Default 20 × 20";
end
