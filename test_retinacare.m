% TEST_RETINACARE Automated Test Suite for RetinaCare AI MATLAB Application
%
% Usage in MATLAB:
%   >> test_retinacare

fprintf('========================================================================\n');
fprintf('  RetinaCare AI - Automated Test Suite & Engine Verification           \n');
fprintf('========================================================================\n\n');

projectRoot = fileparts(mfilename('fullpath'));
addpath(projectRoot);
addpath(fullfile(projectRoot, 'sample_data'));

passCount = 0;
totalTests = 11;

%% Test 1: Clinical Database Initialization
fprintf('[Test 1/9] Initializing ClinicalDatabase... ');
try
    db = retinacare.data.ClinicalDatabase();
    assert(length(db.Patients) >= 5, 'Must contain at least 5 patient cohorts');
    assert(~isempty(db.ReviewQueue), 'Review queue must not be empty');
    assert(~isempty(db.Referrals), 'Referrals table must not be empty');
    assert(~isempty(db.PHCCenters), 'PHC Centers must not be empty');
    assert(isfield(db.DistrictMetrics, 'TotalScreened'), 'DistrictMetrics must exist');
    fprintf('PASSED (5 Patients, %d Queue items, %d Referrals, %d PHCs)\n', size(db.ReviewQueue, 1), size(db.Referrals, 1), size(db.PHCCenters, 1));
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 2: Synthetic Retina Generation
fprintf('[Test 2/9] Generating Synthetic Retinal Fundus (Stage 2 + DME)... ');
try
    [synImg, anatomy, lesions] = retinacare.data.SyntheticRetina.generate(2, true, 'OD', 640);
    assert(isequal(size(synImg), [640, 640, 3]), 'Image size must be 640x640x3');
    assert(isfield(anatomy, 'DiscCenter'), 'Anatomy must contain DiscCenter');
    assert(lesions.ExudateCount > 0, 'Stage 2 must have exudates');
    fprintf('PASSED (Image: 640x640x3, Exudates: %d, CDR: %.2f)\n', lesions.ExudateCount, anatomy.CDR);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 3: Optical Image Quality & Pre-Processing Lab
fprintf('[Test 3/9] Running Image Quality Lab & Multi-Stage Optical Pipeline... ');
try
    q = retinacare.engine.ImageProcessingLab.assessQuality(synImg);
    assert(q.OverallIndex >= 0 && q.OverallIndex <= 100, 'Quality index must be 0-100');
    assert(~isempty(q.Verdict), 'Verdict string must exist');
    
    enh = retinacare.engine.ImageProcessingLab.fullPipeline(synImg, true, true, true, false);
    assert(isequal(size(enh), size(synImg)), 'Enhanced image size must match');
    fprintf('PASSED (Quality Index: %.1f%%, Verdict: %s)\n', q.OverallIndex, q.Verdict);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 4: Anatomical & Pathological Lesion Segmentation
fprintf('[Test 4/9] Segmenting Anatomy, Vessels, and Lesions... ');
try
    anat = retinacare.engine.AnatomyLesionEngine.segmentAnatomy(synImg, 'OD');
    vess = retinacare.engine.AnatomyLesionEngine.extractVessels(synImg);
    les = retinacare.engine.AnatomyLesionEngine.detectLesions(synImg, anat);
    
    assert(anat.CDR > 0.1 && anat.CDR < 0.9, 'CDR must be in physiological range');
    assert(vess.DensityPercent > 0, 'Vessel density must be > 0');
    assert(isfield(les, 'MicroaneurysmsMask'), 'Lesions must contain MA mask');
    fprintf('PASSED (CDR: %.2f, Vessel Density: %.2f%%, Tortuosity: %.2f)\n', anat.CDR, vess.DensityPercent, vess.TortuosityIndex);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 5: 6-Stage AI Constellation Inference
fprintf('[Test 5/9] Executing Deep Multi-Model Constellation Inference... ');
try
    aiRes = retinacare.engine.ConstellationAI.runInference(synImg, anat, les, vess);
    assert(aiRes.PredictedStage >= 0 && aiRes.PredictedStage <= 4, 'Stage must be 0 to 4');
    assert(length(aiRes.SoftmaxProbabilities) == 5, 'Must have 5 class probabilities');
    assert(aiRes.Confidence > 0 && aiRes.Confidence <= 100, 'Confidence must be 0-100%');
    fprintf('PASSED (Diagnosis: %s, Conf: %.1f%%, DME: %s)\n', aiRes.ShortLabel, aiRes.Confidence, aiRes.DMEVerdict);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 6: Explainability Lab & Grad-CAM
fprintf('[Test 6/9] Generating Grad-CAM Heatmap & Ranked Evidence... ');
try
    [hmap, blend] = retinacare.engine.ExplainabilityEngine.generateGradCAM(synImg, les, anat, aiRes.PredictedStage);
    evList = retinacare.engine.ExplainabilityEngine.rankClinicalEvidence(les, aiRes.PredictedStage);
    calib = retinacare.engine.ExplainabilityEngine.getCalibrationData();
    
    assert(isequal(size(blend), size(synImg)), 'Blend image size must match');
    assert(~isempty(evList), 'Evidence list must not be empty');
    assert(calib.ECE < 0.05, 'Expected Calibration Error must be low');
    fprintf('PASSED (%d Evidence items, ECE: %.3f)\n', length(evList), calib.ECE);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 7: Simulink Discrete-Event Capacity Simulator
fprintf('[Test 7/9] Running Simulink Discrete-Event Healthcare Simulator... ');
try
    simEng = retinacare.engine.SimulinkQueueEngine(100, 18, 4, 1.8);
    simRes = simEng.runSimulation();
    assert(simRes.TotalScreened > 0, 'Must process patients');
    assert(length(simRes.ThroughputHourly) == 8, 'Must return 8 hourly values');
    assert(isfield(simRes.QueueDepths, 'TeleDoctor'), 'Must track doctor queue');
    fprintf('PASSED (Screened: %d, Referrals: %d, Saturation: %.1f%%)\n', simRes.TotalScreened, simRes.ReferralsGenerated, simRes.TertiarySaturationPercent);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 8: ABDM Gateway & FHIR Protocol
fprintf('[Test 8/9] Testing ABDM FHIR Resource Generator & ASHA Dispatch... ');
try
    pat = db.Patients(1);
    fhir = retinacare.referral.ABDMGateway.generateFHIRDiagnosticReport(pat, aiRes);
    assert(strcmp(fhir.resourceType, 'DiagnosticReport'), 'Resource must be DiagnosticReport');
    
    alert = retinacare.referral.ABDMGateway.dispatchASHAAlert(pat, struct('Hospital', 'M.Y. Hospital', 'Procedure', 'OCT', 'Urgency', 'Urgent'));
    assert(contains(alert.Status, 'SENT'), 'Alert must be sent');
    fprintf('PASSED (FHIR ID: %s, ASHA Status: %s)\n', fhir.id, alert.Status);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 9: Model Registry & Benchmark Curves
fprintf('[Test 9/10] Verifying 15 Active Production Models & ROC Benchmarks... ');
try
    mReg = retinacare.models.ModelRegistry();
    assert(size(mReg.ModelsTable, 1) == 15, 'Must have 15 production models');
    [fpr, tpr, auc] = mReg.getROCCurve('IDRiD');
    assert(auc > 0.95, 'IDRiD AUC must exceed 0.95');
    fprintf('PASSED (15 Models verified, IDRiD AUC: %.3f)\n', auc);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 10: RetinaCareApp UI Initialization
fprintf('[Test 10/11] Launching and verifying RetinaCareApp UI instantiation... ');
try
    testApp = RetinaCareApp();
    assert(isvalid(testApp.UIFigure), 'UIFigure must be valid and visible');
    assert(length(testApp.NavButtons) == 15, 'Must have 15 navigation buttons');
    assert(length(testApp.TabGroup.Children) == 15, 'Must have 15 module tabs');
    delete(testApp);
    fprintf('PASSED (15 Tabs, 15 Nav Buttons, UIFigure created & verified)\n');
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

%% Test 11: App Designer .mlapp Package Verification
fprintf('[Test 11/11] Verifying RetinaCareApp.mlapp archive & metadata... ');
try
    mlappPath = fullfile(projectRoot, 'RetinaCareApp.mlapp');
    assert(isfile(mlappPath), 'RetinaCareApp.mlapp must exist');
    mlInfo = dir(mlappPath);
    assert(mlInfo.bytes > 50000, 'RetinaCareApp.mlapp size must be valid (>50KB)');
    fprintf('PASSED (Package: RetinaCareApp.mlapp, Size: %.1f KB)\n', mlInfo.bytes/1024);
    passCount = passCount + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n========================================================================\n');
fprintf('  Test Results: %d / %d Tests Passed (%.1f%%)\n', passCount, totalTests, (passCount/totalTests)*100);
fprintf('========================================================================\n');
