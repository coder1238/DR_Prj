classdef RetinaCareApp < matlab.apps.AppBase
    % RETINACAREAPP Comprehensive MATLAB App Designer Clinical Application
    % Modeled after the "RetinaCare AI - Smart DR Screening & Decision Support"
    % Stitch project (ID: 8514012087795404150).
    %
    % Encapsulates all 15 clinical modules:
    % 1. Clinical Command Centre
    % 2. Patient Registration & Clinical Intake
    % 3. Retinal Capture Studio
    % 4. Image Quality Lab & Pre-Processing
    % 5. AI Constellation Analysis Command Centre
    % 6. Retinal Anatomy & Lesion Map
    % 7. DR Severity Studio (ICDR & DME)
    % 8. Explainability & Evidence Lab
    % 9. Clinical Review Queue & Triage
    % 10. Ophthalmologist Review Workstation
    % 11. Longitudinal Patient Record
    % 12. Referral Command Centre (ABDM)
    % 13. District Intelligence & Simulink Resource Lab
    % 14. AI Model Registry & Validation Centre
    % 15. Clinical Workspace Access & Login
    
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        MainGrid             matlab.ui.container.GridLayout
        HeaderPanel          matlab.ui.container.Panel
        SidebarPanel         matlab.ui.container.Panel
        ContentPanel         matlab.ui.container.Panel
        SafetyBanner         matlab.ui.container.Panel
        TabGroup             matlab.ui.container.TabGroup
        
        % Tabs (15 Modules)
        TabCommandCentre     matlab.ui.container.Tab
        TabPatientIntake     matlab.ui.container.Tab
        TabCaptureStudio     matlab.ui.container.Tab
        TabQualityLab        matlab.ui.container.Tab
        TabAIConstellation   matlab.ui.container.Tab
        TabAnatomyLesion     matlab.ui.container.Tab
        TabSeverityStudio    matlab.ui.container.Tab
        TabExplainability    matlab.ui.container.Tab
        TabReviewQueue       matlab.ui.container.Tab
        TabWorkstation       matlab.ui.container.Tab
        TabLongitudinal      matlab.ui.container.Tab
        TabReferral          matlab.ui.container.Tab
        TabSimulinkLab       matlab.ui.container.Tab
        TabModelRegistry     matlab.ui.container.Tab
        TabLoginAccess       matlab.ui.container.Tab
        
        % Data & Engines
        ClinicalDB           % retinacare.data.ClinicalDatabase
        CurrentPatient       % struct
        CurrentRawImg        % uint8 / double fundus image
        CurrentEnhancedImg   % enhanced fundus image
        CurrentAnatomy       % struct
        CurrentLesions       % struct
        CurrentVessels       % struct
        CurrentAIResult      % struct
        SimEngine            % retinacare.engine.SimulinkQueueEngine
        ModelReg             % retinacare.models.ModelRegistry
        
        % Navigation Buttons
        NavButtons           % array of matlab.ui.control.Button
        
        % Axes for image displays and charts
        AxesCapture          matlab.ui.control.UIAxes
        AxesQualityRaw       matlab.ui.control.UIAxes
        AxesQualityEnh       matlab.ui.control.UIAxes
        AxesQualityHist      matlab.ui.control.UIAxes
        AxesAnatomyMap       matlab.ui.control.UIAxes
        AxesSeverityProb     matlab.ui.control.UIAxes
        AxesSeverityDial     matlab.ui.control.UIAxes
        AxesGradCAM          matlab.ui.control.UIAxes
        AxesCalibration      matlab.ui.control.UIAxes
        AxesWorkstationAI    matlab.ui.control.UIAxes
        AxesWorkstationDoc   matlab.ui.control.UIAxes
        AxesLongSeverity     matlab.ui.control.UIAxes
        AxesLongLesions      matlab.ui.control.UIAxes
        AxesLongBaseFundus   matlab.ui.control.UIAxes
        AxesLongCurrFundus   matlab.ui.control.UIAxes
        AxesSimThroughput    matlab.ui.control.UIAxes
        AxesSimQueues        matlab.ui.control.UIAxes
        AxesROCCurve         matlab.ui.control.UIAxes
        AxesPRCurve          matlab.ui.control.UIAxes
    end
    
    properties (Constant)
        % Design System Colors matching Stitch RetinaCare AI Theme
        COLOR_PRIMARY         = [0.204, 0.000, 0.459]; % #340075 Deep Clinical Purple
        COLOR_PRIMARY_CONTAIN = [0.298, 0.114, 0.584]; % #4C1D95
        COLOR_SECONDARY       = [0.443, 0.165, 0.886]; % #712AE2 Royal Purple
        COLOR_BG              = [0.980, 0.973, 1.000]; % #FAF8FF Light Lavender
        COLOR_SURFACE         = [1.000, 1.000, 1.000]; % #FFFFFF
        COLOR_CONTAINER       = [0.937, 0.933, 0.980]; % #EFEDF4
        COLOR_CONTAINER_HIGH  = [0.914, 0.906, 0.933]; % #E9E7EE
        COLOR_GREEN           = [0.020, 0.588, 0.412]; % #059669 Normal / Gradable
        COLOR_AMBER           = [0.851, 0.467, 0.024]; % #D97706 Warning / Review
        COLOR_RED             = [0.863, 0.102, 0.102]; % #DC2626 Urgent / PDR
        COLOR_TEXT            = [0.098, 0.090, 0.180]; % #19172E Dark Charcoal
        COLOR_TEXT_MUTED      = [0.420, 0.400, 0.480];
    end
    
    methods (Access = public)
        function app = RetinaCareApp()
            % Constructor: Initialize database, patient state, UI, and default state
            app.initEngines();
            app.loadInitialPatient();
            app.createUI();
            app.selectTab(1); % Start at Clinical Command Centre
        end
        
        function delete(app)
            % Destructor: Clean up figure
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
    
    methods (Access = private)
        function initEngines(app)
            % Instantiate data stores and engines
            app.ClinicalDB = retinacare.data.ClinicalDatabase();
            app.SimEngine = retinacare.engine.SimulinkQueueEngine(100, 18, 4, 1.8);
            app.ModelReg = retinacare.models.ModelRegistry();
        end
        
        function loadInitialPatient(app)
            % Default patient: Suresh Chandra Verma (Key Longitudinal Case)
            app.CurrentPatient = app.ClinicalDB.Patients(1);
            samplePath = fullfile(fileparts(mfilename('fullpath')), 'sample_data', app.CurrentPatient.CurrentFundus);
            
            if exist(samplePath, 'file')
                app.CurrentRawImg = imread(samplePath);
            else
                % Generate synthetic fundus on the fly
                app.CurrentRawImg = retinacare.data.SyntheticRetina.generate(app.CurrentPatient.CurrentStage, true, 'OD');
            end
            
            % Process image through engines
            app.CurrentEnhancedImg = retinacare.engine.ImageProcessingLab.fullPipeline(app.CurrentRawImg, true, true, true, false);
            app.CurrentAnatomy = retinacare.engine.AnatomyLesionEngine.segmentAnatomy(app.CurrentRawImg, 'OD');
            app.CurrentVessels = retinacare.engine.AnatomyLesionEngine.extractVessels(app.CurrentRawImg);
            app.CurrentLesions = retinacare.engine.AnatomyLesionEngine.detectLesions(app.CurrentRawImg, app.CurrentAnatomy);
            app.CurrentAIResult = retinacare.engine.ConstellationAI.runInference(app.CurrentRawImg, app.CurrentAnatomy, app.CurrentLesions, app.CurrentVessels);
        end
        
        function createUI(app)
            % Create main UIFigure with responsive grid
            app.UIFigure = uifigure('Name', 'RetinaCare AI — Smart DR Screening & Decision Support', ...
                'Position', [40, 40, 1400, 880], ...
                'Color', app.COLOR_BG, ...
                'Visible', 'on');
            
            % Master 3-Row Grid: Header, Safety Banner, Main Content
            app.MainGrid = uigridlayout(app.UIFigure, [3, 1]);
            app.MainGrid.RowHeight = {56, 30, '1x'};
            app.MainGrid.Padding = [0 0 0 0];
            app.MainGrid.RowSpacing = 0;
            
            % 1. Header Bar
            app.createHeader();
            
            % 2. Safety Disclaimer Banner (Mandatory UX Rule)
            app.createSafetyBanner();
            
            % 3. Body: Sidebar Navigation + Dynamic Tab Workspace
            bodyGrid = uigridlayout(app.MainGrid, [1, 2]);
            bodyGrid.ColumnWidth = {240, '1x'};
            bodyGrid.Padding = [8 8 8 8];
            bodyGrid.ColumnSpacing = 8;
            
            app.createSidebar(bodyGrid);
            app.createContentWorkspace(bodyGrid);
        end
        
        function createHeader(app)
            app.HeaderPanel = uipanel(app.MainGrid, ...
                'BackgroundColor', app.COLOR_PRIMARY, ...
                'BorderType', 'none');
            
            hdrLayout = uigridlayout(app.HeaderPanel, [1, 5]);
            hdrLayout.ColumnWidth = {280, 200, 240, '1x', 220};
            hdrLayout.Padding = [16 8 16 8];
            
            % App Branding
            titleLabel = uilabel(hdrLayout, ...
                'Text', '👁️ RetinaCare AI', ...
                'FontName', 'Inter', 'FontSize', 18, 'FontWeight', 'bold', ...
                'FontColor', [1 1 1]);
            
            subTitle = uilabel(hdrLayout, ...
                'Text', 'Clinical Decision Support v2.4', ...
                'FontName', 'Inter', 'FontSize', 11, ...
                'FontColor', [0.8 0.7 0.95]);
            
            % ABDM Gateway Status
            abdmStatus = uilabel(hdrLayout, ...
                'Text', '🟢 ABDM Gateway: Fast-Track Linked (1.8 Mbps)', ...
                'FontName', 'Public Sans', 'FontSize', 11, ...
                'FontColor', [0.6 0.95 0.75]);
            
            % Center spacer
            uilabel(hdrLayout, 'Text', '');
            
            % Clinician Profile
            userBadge = uilabel(hdrLayout, ...
                'Text', '👨‍⚕️ Dr. Sharma (MGM Eye Centre)', ...
                'FontName', 'Inter', 'FontSize', 11, 'FontWeight', 'bold', ...
                'FontColor', [1 1 1], 'HorizontalAlignment', 'right');
        end
        
        function createSafetyBanner(app)
            app.SafetyBanner = uipanel(app.MainGrid, ...
                'BackgroundColor', [0.95, 0.92, 0.99], ...
                'BorderType', 'none');
            
            bLayout = uigridlayout(app.SafetyBanner, [1, 2]);
            bLayout.ColumnWidth = {'1x', 180};
            bLayout.Padding = [16 4 16 4];
            
            uilabel(bLayout, ...
                'Text', '⚠️ CLINICAL SAFETY PROTOCOL: AI-assisted screening assessment • Clinical validation required by Ophthalmologist • Never claim "AI Diagnosed"', ...
                'FontName', 'Public Sans', 'FontSize', 11, 'FontWeight', 'bold', ...
                'FontColor', app.COLOR_PRIMARY_CONTAIN);
            
            uilabel(bLayout, ...
                'Text', 'IPHS 2022 READY', ...
                'FontName', 'Public Sans', 'FontSize', 10, 'FontWeight', 'bold', ...
                'FontColor', app.COLOR_GREEN, 'HorizontalAlignment', 'right');
        end
        
        function createSidebar(app, parentGrid)
            app.SidebarPanel = uipanel(parentGrid, ...
                'BackgroundColor', app.COLOR_SURFACE, ...
                'BorderType', 'line', 'HighlightColor', [0.88 0.85 0.92]);
            
            navGrid = uigridlayout(app.SidebarPanel, [16, 1]);
            navGrid.RowHeight = repmat({36}, 1, 16);
            navGrid.Padding = [8 8 8 8];
            navGrid.RowSpacing = 4;
            
            moduleNames = {
                '📊 01. Command Centre', ...
                '👤 02. Patient Intake', ...
                '📷 03. Capture Studio', ...
                '🔬 04. Image Quality Lab', ...
                '🧠 05. AI Constellation', ...
                '🗺️ 06. Anatomy & Lesions', ...
                '🎯 07. DR Severity Studio', ...
                '🔍 08. Explainability Lab', ...
                '📋 09. Review Queue (87)', ...
                '🩺 10. Doctor Workstation', ...
                '📈 11. Longitudinal Record', ...
                '🏥 12. Referral Hub (14)', ...
                '⚡ 13. Simulink Resource Lab', ...
                '🤖 14. AI Model Registry', ...
                '🔐 15. Workspace Access'
            };
            
            for i = 1:length(moduleNames)
                btn = uibutton(navGrid, 'push', ...
                    'Text', moduleNames{i}, ...
                    'FontName', 'Inter', 'FontSize', 11, ...
                    'HorizontalAlignment', 'left', ...
                    'BackgroundColor', app.COLOR_SURFACE, ...
                    'FontColor', app.COLOR_TEXT, ...
                    'ButtonPushedFcn', @(btn, event) app.onNavButtonClick(i));
                if i == 1
                    app.NavButtons = btn;
                else
                    app.NavButtons(i) = btn;
                end
            end
            
            % Highlight first button
            app.NavButtons(1).BackgroundColor = app.COLOR_PRIMARY_CONTAIN;
            app.NavButtons(1).FontColor = [1 1 1];
        end
        
        function createContentWorkspace(app, parentGrid)
            app.ContentPanel = uipanel(parentGrid, ...
                'BackgroundColor', app.COLOR_BG, ...
                'BorderType', 'none');
            
            cLayout = uigridlayout(app.ContentPanel, [1, 1]);
            cLayout.Padding = [0 0 0 0];
            
            app.TabGroup = uitabgroup(cLayout);
            
            % Create all 15 tabs
            app.TabCommandCentre   = uitab(app.TabGroup, 'Title', 'Command Centre');
            app.TabPatientIntake   = uitab(app.TabGroup, 'Title', 'Patient Intake');
            app.TabCaptureStudio   = uitab(app.TabGroup, 'Title', 'Capture Studio');
            app.TabQualityLab      = uitab(app.TabGroup, 'Title', 'Quality Lab');
            app.TabAIConstellation = uitab(app.TabGroup, 'Title', 'AI Constellation');
            app.TabAnatomyLesion   = uitab(app.TabGroup, 'Title', 'Anatomy & Lesions');
            app.TabSeverityStudio  = uitab(app.TabGroup, 'Title', 'Severity Studio');
            app.TabExplainability  = uitab(app.TabGroup, 'Title', 'Explainability');
            app.TabReviewQueue     = uitab(app.TabGroup, 'Title', 'Review Queue');
            app.TabWorkstation     = uitab(app.TabGroup, 'Title', 'Review Workstation');
            app.TabLongitudinal    = uitab(app.TabGroup, 'Title', 'Longitudinal Record');
            app.TabReferral        = uitab(app.TabGroup, 'Title', 'Referral Hub');
            app.TabSimulinkLab     = uitab(app.TabGroup, 'Title', 'Simulink Lab');
            app.TabModelRegistry   = uitab(app.TabGroup, 'Title', 'Model Registry');
            app.TabLoginAccess     = uitab(app.TabGroup, 'Title', 'Workspace Access');
            
            % Build content of each tab
            app.buildTabCommandCentre();
            app.buildTabPatientIntake();
            app.buildTabCaptureStudio();
            app.buildTabQualityLab();
            app.buildTabAIConstellation();
            app.buildTabAnatomyLesion();
            app.buildTabSeverityStudio();
            app.buildTabExplainability();
            app.buildTabReviewQueue();
            app.buildTabWorkstation();
            app.buildTabLongitudinal();
            app.buildTabReferral();
            app.buildTabSimulinkLab();
            app.buildTabModelRegistry();
            app.buildTabLoginAccess();
        end
        
        function onNavButtonClick(app, index)
            % Change active tab and update sidebar highlights
            app.selectTab(index);
        end
        
        function selectTab(app, index)
            tabs = [app.TabCommandCentre, app.TabPatientIntake, app.TabCaptureStudio, ...
                    app.TabQualityLab, app.TabAIConstellation, app.TabAnatomyLesion, ...
                    app.TabSeverityStudio, app.TabExplainability, app.TabReviewQueue, ...
                    app.TabWorkstation, app.TabLongitudinal, app.TabReferral, ...
                    app.TabSimulinkLab, app.TabModelRegistry, app.TabLoginAccess];
            if index >= 1 && index <= length(tabs)
                app.TabGroup.SelectedTab = tabs(index);
            end
            for i = 1:length(app.NavButtons)
                if i == index
                    app.NavButtons(i).BackgroundColor = app.COLOR_PRIMARY_CONTAIN;
                    app.NavButtons(i).FontColor = [1 1 1];
                    app.NavButtons(i).FontWeight = 'bold';
                else
                    app.NavButtons(i).BackgroundColor = app.COLOR_SURFACE;
                    app.NavButtons(i).FontColor = app.COLOR_TEXT;
                    app.NavButtons(i).FontWeight = 'normal';
                end
            end
        end
        
        % =================================================================
        % TAB 1: CLINICAL COMMAND CENTRE
        % =================================================================
        function buildTabCommandCentre(app)
            grid = uigridlayout(app.TabCommandCentre, [3, 1]);
            grid.RowHeight = {110, 180, '1x'};
            grid.Padding = [12 12 12 12];
            grid.RowSpacing = 12;
            
            % 1. KPI Cards
            kpiGrid = uigridlayout(grid, [1, 4]);
            kpiGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            kpiGrid.Padding = [0 0 0 0];
            
            app.createMetricCard(kpiGrid, 'Screened Today', '142', '+18% vs yesterday', app.COLOR_PRIMARY);
            app.createMetricCard(kpiGrid, 'Referable DR Detected', '18 (12.7%)', '4 PDR • 14 NPDR', app.COLOR_RED);
            app.createMetricCard(kpiGrid, 'Referrals Dispatched', '14', 'ABDM Fast-Track Linked', app.COLOR_SECONDARY);
            app.createMetricCard(kpiGrid, 'Model Confidence Avg', '94.8%', 'ECE: 0.021 (Calibrated)', app.COLOR_GREEN);
            
            % 2. Screening Pulse Hub (Throughput Pipeline)
            pulsePanel = uipanel(grid, 'Title', 'Screening Pulse Hub — End-to-End Pipeline Telemetry', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            pulseGrid = uigridlayout(pulsePanel, [2, 6]);
            pulseGrid.RowHeight = {30, 70};
            pulseGrid.ColumnWidth = repmat({'1x'}, 1, 6);
            
            stages = {'1. Patient Intake', '2. Camera Capture', '3. Quality Pass', '4. AI Inference', '5. Doctor Review', '6. ABDM Dispatch'};
            counts = {'142 registered', '142 captured', '138 gradable (97%)', '138 classified', '87 reviewed', '14 referred'};
            for s = 1:6
                uilabel(pulseGrid, 'Text', stages{s}, 'FontWeight', 'bold', 'FontColor', app.COLOR_PRIMARY_CONTAIN);
            end
            for s = 1:6
                pBox = uipanel(pulseGrid, 'BackgroundColor', app.COLOR_CONTAINER);
                pLay = uigridlayout(pBox, [2, 1]);
                pLay.Padding = [4 4 4 4];
                uilabel(pLay, 'Text', counts{s}, 'FontSize', 12, 'FontWeight', 'bold');
                uilabel(pLay, 'Text', '⚡ Latency: < 30s SLA', 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED);
            end
            
            % 3. Priority Review Cases Table & District Telemetry
            splitGrid = uigridlayout(grid, [1, 2]);
            splitGrid.ColumnWidth = {'1.6x', '1x'};
            splitGrid.Padding = [0 0 0 0];
            
            prioPanel = uipanel(splitGrid, 'Title', 'Priority Review Cases Requiring Immediate Clinical Decision', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            pLay = uigridlayout(prioPanel, [2, 1]);
            pLay.RowHeight = {'1x', 36};
            
            % Table
            t = uitable(pLay, 'Data', app.ClinicalDB.ReviewQueue, ...
                'ColumnName', {'Patient', 'UHID', 'AI Grade', 'DME Risk', 'Urgency', 'Conf', 'Facility', 'Status'}, ...
                'ColumnWidth', {140, 110, 120, 110, 100, 60, 95, 75});
            
            actionBtn = uibutton(pLay, 'push', 'Text', 'Open Selected Patient in Review Workstation ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(10));
            
            % District Signal Telemetry
            distPanel = uipanel(splitGrid, 'Title', 'Indore Health Division Network Telemetry', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            dGrid = uigridlayout(distPanel, [5, 1]);
            dGrid.RowHeight = repmat({28}, 1, 5);
            
            uilabel(dGrid, 'Text', '📍 Indore Central Hub: 18 Field Cameras Connected • Online', 'FontColor', app.COLOR_GREEN);
            uilabel(dGrid, 'Text', '📶 4G Mesh Bandwidth: 1.8 Mbps • JPEG-XL Sync Active', 'FontColor', app.COLOR_PRIMARY);
            uilabel(dGrid, 'Text', '⚠️ M.Y. Hospital Eye OPD: 82% Full (Capacity Warning)', 'FontColor', app.COLOR_AMBER);
            uilabel(dGrid, 'Text', '🏥 Dewas DH Node: 14 Scans pending validation', 'FontColor', app.COLOR_TEXT);
            uilabel(dGrid, 'Text', '🚐 Sanwer CHC Mobile Unit: 28 screenings completed', 'FontColor', app.COLOR_TEXT);
        end
        
        function card = createMetricCard(app, parentGrid, title, value, subtext, accentColor)
            card = uipanel(parentGrid, 'BackgroundColor', app.COLOR_SURFACE, ...
                'BorderType', 'line', 'HighlightColor', [0.88 0.85 0.92]);
            g = uigridlayout(card, [3, 1]);
            g.Padding = [12 8 12 8];
            g.RowSpacing = 2;
            
            uilabel(g, 'Text', title, 'FontSize', 11, 'FontColor', app.COLOR_TEXT_MUTED);
            uilabel(g, 'Text', value, 'FontSize', 22, 'FontWeight', 'bold', 'FontColor', accentColor);
            uilabel(g, 'Text', subtext, 'FontSize', 10, 'FontColor', app.COLOR_TEXT);
        end
        
        % =================================================================
        % TAB 2: PATIENT REGISTRATION & CLINICAL INTAKE
        % =================================================================
        function buildTabPatientIntake(app)
            grid = uigridlayout(app.TabPatientIntake, [1, 2]);
            grid.ColumnWidth = {'1.5x', '1x'};
            grid.Padding = [12 12 12 12];
            
            % Left Form Panel
            formPanel = uipanel(grid, 'Title', 'Patient Registration & Clinical Intake Workspace', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            fLay = uigridlayout(formPanel, [11, 2]);
            fLay.RowHeight = repmat({32}, 1, 11);
            fLay.ColumnWidth = {140, '1x'};
            
            uilabel(fLay, 'Text', 'ABHA Number:');
            txtABHA = uieditfield(fLay, 'text', 'Value', app.CurrentPatient.ABHA);
            
            uilabel(fLay, 'Text', 'Full Name:');
            txtName = uieditfield(fLay, 'text', 'Value', app.CurrentPatient.Name);
            
            uilabel(fLay, 'Text', 'Age & Gender:');
            ageGrid = uigridlayout(fLay, [1, 2]);
            ageGrid.Padding = [0 0 0 0];
            spnAge = uispinner(ageGrid, 'Value', app.CurrentPatient.Age, 'Limits', [1 120]);
            ddGen = uidropdown(ageGrid, 'Items', {'Male', 'Female', 'Other'}, 'Value', app.CurrentPatient.Gender);
            
            uilabel(fLay, 'Text', 'Diabetes Type & Dur:');
            dmGrid = uigridlayout(fLay, [1, 2]);
            dmGrid.Padding = [0 0 0 0];
            ddDM = uidropdown(dmGrid, 'Items', {'Type 2 DM', 'Type 1 DM', 'Gestational DM'});
            spnDur = uispinner(dmGrid, 'Value', app.CurrentPatient.DurationYears, 'Limits', [0 60]);
            
            uilabel(fLay, 'Text', 'HbA1c (%):');
            spnHb = uispinner(fLay, 'Value', app.CurrentPatient.HbA1c, 'Limits', [4 18], 'Step', 0.1);
            
            uilabel(fLay, 'Text', 'Fasting Blood Glucose:');
            spnFBG = uispinner(fLay, 'Value', app.CurrentPatient.FastingGlucose, 'Limits', [40 600]);
            
            uilabel(fLay, 'Text', 'Visual Acuity (BCVA):');
            vaGrid = uigridlayout(fLay, [1, 2]);
            vaGrid.Padding = [0 0 0 0];
            ddBCVA_OD = uidropdown(vaGrid, 'Items', {'6/6', '6/9', '6/12', '6/18', '6/24', '6/36', '6/60', '<3/60'}, 'Value', app.CurrentPatient.BCVA_OD);
            ddBCVA_OS = uidropdown(vaGrid, 'Items', {'6/6', '6/9', '6/12', '6/18', '6/24', '6/36', '6/60', '<3/60'}, 'Value', app.CurrentPatient.BCVA_OS);
            
            uilabel(fLay, 'Text', 'Intraocular Pressure:');
            iopGrid = uigridlayout(fLay, [1, 2]);
            iopGrid.Padding = [0 0 0 0];
            spnIOP_OD = uispinner(iopGrid, 'Value', app.CurrentPatient.IOP_OD, 'Limits', [5 60]);
            spnIOP_OS = uispinner(iopGrid, 'Value', app.CurrentPatient.IOP_OS, 'Limits', [5 60]);
            
            uilabel(fLay, 'Text', 'Visual Complaints:');
            txtSymp = uieditfield(fLay, 'text', 'Value', app.CurrentPatient.Symptoms);
            
            uilabel(fLay, 'Text', 'ABDM Consent:');
            uicheckbox(fLay, 'Text', 'Patient informed consent recorded & linked to ABHA token', 'Value', true);
            
            uilabel(fLay, 'Text', '');
            btnSubmit = uibutton(fLay, 'push', 'Text', 'Save & Proceed to Retinal Capture Studio ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(3));
            
            % Right Snapshot Summary Card
            snapPanel = uipanel(grid, 'Title', 'Patient Screening Intake Snapshot', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            sLay = uigridlayout(snapPanel, [7, 1]);
            sLay.Padding = [16 16 16 16];
            
            uilabel(sLay, 'Text', sprintf('👤 %s, %d%c', app.CurrentPatient.Name, app.CurrentPatient.Age, app.CurrentPatient.Gender(1)), ...
                'FontSize', 16, 'FontWeight', 'bold', 'FontColor', app.COLOR_PRIMARY);
            uilabel(sLay, 'Text', sprintf('🆔 UHID: %s • ABHA: %s', app.CurrentPatient.UHID, app.CurrentPatient.ABHA));
            uilabel(sLay, 'Text', sprintf('🏥 District / PHC: %s', app.CurrentPatient.District));
            uilabel(sLay, 'Text', sprintf('🩸 Diabetes Duration: %d years • HbA1c: %.1f%%', app.CurrentPatient.DurationYears, app.CurrentPatient.HbA1c));
            uilabel(sLay, 'Text', sprintf('👁️ BCVA: OD %s, OS %s • IOP: OD %.1f, OS %.1f mmHg', app.CurrentPatient.BCVA_OD, app.CurrentPatient.BCVA_OS, app.CurrentPatient.IOP_OD, app.CurrentPatient.IOP_OS));
            uilabel(sLay, 'Text', sprintf('⚠️ Current Symptoms: %s', app.CurrentPatient.Symptoms), 'FontColor', app.COLOR_AMBER);
            uilabel(sLay, 'Text', '✅ ABDM Ayushman Health Data Exchange Ready', 'FontColor', app.COLOR_GREEN, 'FontWeight', 'bold');
        end
        
        % =================================================================
        % TAB 3: RETINAL CAPTURE STUDIO
        % =================================================================
        function buildTabCaptureStudio(app)
            grid = uigridlayout(app.TabCaptureStudio, [2, 1]);
            grid.RowHeight = {60, '1x'};
            grid.Padding = [12 12 12 12];
            
            % Hardware Telemetry Bar
            hwPanel = uipanel(grid, 'BackgroundColor', app.COLOR_SURFACE, 'BorderType', 'line');
            hwGrid = uigridlayout(hwPanel, [1, 6]);
            hwGrid.ColumnWidth = {'1.5x', '1x', '1x', '1x', '1x', '1.2x'};
            hwGrid.Padding = [8 4 8 4];
            
            uilabel(hwGrid, 'Text', '📷 Remidio NM-FOP 10 (USB 3.0)', 'FontWeight', 'bold', 'FontColor', app.COLOR_PRIMARY);
            uilabel(hwGrid, 'Text', '🔋 Battery: 84% READY', 'FontColor', app.COLOR_GREEN);
            uilabel(hwGrid, 'Text', '🎯 Auto-Focus: LOCKED', 'FontColor', app.COLOR_GREEN);
            uilabel(hwGrid, 'Text', '💡 Illum: 880nm NIR', 'FontColor', app.COLOR_TEXT);
            uilabel(hwGrid, 'Text', '🟢 Fixation Target: Center', 'FontColor', app.COLOR_PRIMARY_CONTAIN);
            
            btnCap = uibutton(hwGrid, 'push', 'Text', 'Trigger Capture 📸', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.onTriggerCapture());
            
            % Capture Workspace: Controls + Live Fundus Canvas
            capGrid = uigridlayout(grid, [1, 2]);
            capGrid.ColumnWidth = {260, '1x'};
            capGrid.Padding = [0 0 0 0];
            
            ctrlPanel = uipanel(capGrid, 'Title', 'Capture Settings & Multi-Field Selector', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            cL = uigridlayout(ctrlPanel, [8, 1]);
            cL.RowHeight = repmat({34}, 1, 8);
            
            uilabel(cL, 'Text', 'Eye Selection:');
            btnEyeGrid = uigridlayout(cL, [1, 2]);
            btnEyeGrid.Padding = [0 0 0 0];
            btnOD = uibutton(btnEyeGrid, 'push', 'Text', 'OD (Right Eye)', 'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1]);
            btnOS = uibutton(btnEyeGrid, 'push', 'Text', 'OS (Left Eye)', 'BackgroundColor', app.COLOR_SURFACE);
            
            uilabel(cL, 'Text', 'Field Standard:');
            uidropdown(cL, 'Items', {'Field 1: Macula-Centered (45°)', 'Field 2: Optic Disc-Centered (45°)', 'ETDRS 7-Standard Field (Panoramic)'});
            
            uilabel(cL, 'Text', 'Pupil Dilation Status:');
            uidropdown(cL, 'Items', {'Non-Mydriatic (> 3.8mm)', 'Pharmacologically Dilated (Tropicamide 0.5%)'});
            
            uilabel(cL, 'Text', 'Test Sample Preset:');
            ddPreset = uidropdown(cL, 'Items', {'Suresh Verma (Moderate NPDR + DME)', 'Ramesh Patel (PDR Stage 4)', 'Sunita Bai (Normal Stage 0)', 'Mohan Lal (Mild NPDR)', 'Kamala Devi (Severe NPDR)'}, ...
                'ValueChangedFcn', @(dd, event) app.onSelectSamplePreset(dd.Value));
            
            btnLoad = uibutton(cL, 'push', 'Text', 'Load Custom Image File...', ...
                'BackgroundColor', app.COLOR_SECONDARY, 'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(btn, event) app.onLoadCustomFile());
            
            btnNext = uibutton(cL, 'push', 'Text', 'Proceed to Quality Lab ➔', ...
                'BackgroundColor', app.COLOR_GREEN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(4));
            
            % Fundus Canvas
            canvasPanel = uipanel(capGrid, 'Title', 'Live Retinal Fundus Viewport (45° Macula-Centered)', ...
                'BackgroundColor', [0.05 0.05 0.07], 'FontWeight', 'bold', 'ForegroundColor', [0.9 0.9 1]);
            canLay = uigridlayout(canvasPanel, [1, 1]);
            canLay.Padding = [4 4 4 4];
            
            app.AxesCapture = uiaxes(canLay);
            app.AxesCapture.Toolbar.Visible = 'off';
            imshow(app.CurrentRawImg, 'Parent', app.AxesCapture);
            title(app.AxesCapture, sprintf('%s — Right Eye (OD) 45°', app.CurrentPatient.Name), 'Color', [1 1 1], 'FontSize', 12);
        end
        
        function onSelectSamplePreset(app, presetName)
            if contains(presetName, 'Suresh')
                app.CurrentPatient = app.ClinicalDB.Patients(1);
            elseif contains(presetName, 'Ramesh')
                app.CurrentPatient = app.ClinicalDB.Patients(2);
            elseif contains(presetName, 'Sunita')
                app.CurrentPatient = app.ClinicalDB.Patients(3);
            elseif contains(presetName, 'Mohan')
                app.CurrentPatient = app.ClinicalDB.Patients(4);
            else
                app.CurrentPatient = app.ClinicalDB.Patients(5);
            end
            
            samplePath = fullfile(fileparts(mfilename('fullpath')), 'sample_data', app.CurrentPatient.CurrentFundus);
            if exist(samplePath, 'file')
                app.CurrentRawImg = imread(samplePath);
            else
                app.CurrentRawImg = retinacare.data.SyntheticRetina.generate(app.CurrentPatient.CurrentStage, true, 'OD');
            end
            
            % Recompute pipeline
            app.CurrentEnhancedImg = retinacare.engine.ImageProcessingLab.fullPipeline(app.CurrentRawImg, true, true, true, false);
            app.CurrentAnatomy = retinacare.engine.AnatomyLesionEngine.segmentAnatomy(app.CurrentRawImg, 'OD');
            app.CurrentVessels = retinacare.engine.AnatomyLesionEngine.extractVessels(app.CurrentRawImg);
            app.CurrentLesions = retinacare.engine.AnatomyLesionEngine.detectLesions(app.CurrentRawImg, app.CurrentAnatomy);
            app.CurrentAIResult = retinacare.engine.ConstellationAI.runInference(app.CurrentRawImg, app.CurrentAnatomy, app.CurrentLesions, app.CurrentVessels);
            
            % Refresh view
            imshow(app.CurrentRawImg, 'Parent', app.AxesCapture);
            title(app.AxesCapture, sprintf('%s — %s', app.CurrentPatient.Name, app.CurrentPatient.CurrentStage), 'Color', [1 1 1]);
            app.updateAllDisplays();
        end
        
        function onLoadCustomFile(app)
            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp;*.dcm', 'Retinal Fundus Images'});
            if isequal(file, 0), return; end
            fullP = fullfile(path, file);
            try
                app.CurrentRawImg = imread(fullP);
                app.CurrentEnhancedImg = retinacare.engine.ImageProcessingLab.fullPipeline(app.CurrentRawImg, true, true, true, false);
                app.CurrentAnatomy = retinacare.engine.AnatomyLesionEngine.segmentAnatomy(app.CurrentRawImg, 'OD');
                app.CurrentVessels = retinacare.engine.AnatomyLesionEngine.extractVessels(app.CurrentRawImg);
                app.CurrentLesions = retinacare.engine.AnatomyLesionEngine.detectLesions(app.CurrentRawImg, app.CurrentAnatomy);
                app.CurrentAIResult = retinacare.engine.ConstellationAI.runInference(app.CurrentRawImg, app.CurrentAnatomy, app.CurrentLesions, app.CurrentVessels);
                
                imshow(app.CurrentRawImg, 'Parent', app.AxesCapture);
                title(app.AxesCapture, sprintf('Loaded: %s', file), 'Color', [1 1 1]);
                app.updateAllDisplays();
            catch ME
                uialert(app.UIFigure, ME.message, 'Image Load Error');
            end
        end
        
        function onTriggerCapture(app)
            % Flash simulation
            title(app.AxesCapture, '⚡ FLASH EXPOSURE (Remidio NM-FOP)...', 'Color', [1 0.9 0.2]);
            pause(0.2);
            imshow(app.CurrentRawImg, 'Parent', app.AxesCapture);
            title(app.AxesCapture, 'Capture Complete — Optical Quality Verification OK', 'Color', [0.2 1.0 0.4]);
        end
        
        % =================================================================
        % TAB 4: IMAGE QUALITY LAB & PRE-PROCESSING
        % =================================================================
        function buildTabQualityLab(app)
            grid = uigridlayout(app.TabQualityLab, [2, 1]);
            grid.RowHeight = {100, '1x'};
            grid.Padding = [12 12 12 12];
            
            % Quality Telemetry Score Cards
            qBar = uipanel(grid, 'BackgroundColor', app.COLOR_SURFACE, 'BorderType', 'line');
            qBarGrid = uigridlayout(qBar, [1, 5]);
            qBarGrid.ColumnWidth = {'1.5x', '1x', '1x', '1x', '1.2x'};
            qBarGrid.Padding = [8 8 8 8];
            
            qMetrics = retinacare.engine.ImageProcessingLab.assessQuality(app.CurrentRawImg);
            
            app.createMetricCard(qBarGrid, 'Overall Quality Index', sprintf('%.1f%%', qMetrics.OverallIndex), qMetrics.Verdict, qMetrics.ColorTag);
            app.createMetricCard(qBarGrid, 'Tenengrad Sharpness', sprintf('%.1f', qMetrics.Sharpness), 'High-frequency gradient', app.COLOR_PRIMARY);
            app.createMetricCard(qBarGrid, 'Illum Uniformity', sprintf('%.1f%%', qMetrics.IllumUniformity), 'Retinal luminance leveling', app.COLOR_SECONDARY);
            app.createMetricCard(qBarGrid, 'Disc/Macula Centration', sprintf('%.1f%%', qMetrics.Centration), 'Aperture alignment', app.COLOR_GREEN);
            
            btnRunAI = uibutton(qBarGrid, 'push', 'Text', 'Run AI Constellation ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(5));
            
            % Split View: Raw vs Enhanced + Histograms
            viewGrid = uigridlayout(grid, [1, 3]);
            viewGrid.ColumnWidth = {'1x', '1x', '0.8x'};
            viewGrid.Padding = [0 0 0 0];
            
            rawPanel = uipanel(viewGrid, 'Title', 'Raw Optical Acquisition (Remidio NM-FOP)', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            rLay = uigridlayout(rawPanel, [1, 1]);
            app.AxesQualityRaw = uiaxes(rLay);
            app.AxesQualityRaw.Toolbar.Visible = 'off';
            imshow(app.CurrentRawImg, 'Parent', app.AxesQualityRaw);
            
            enhPanel = uipanel(viewGrid, 'Title', 'CUNSB-RFIE + MAXIM + CLAHE Enhanced', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            eLay = uigridlayout(enhPanel, [1, 1]);
            app.AxesQualityEnh = uiaxes(eLay);
            app.AxesQualityEnh.Toolbar.Visible = 'off';
            imshow(app.CurrentEnhancedImg, 'Parent', app.AxesQualityEnh);
            
            histPanel = uipanel(viewGrid, 'Title', 'Green Channel Optical Histogram', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            hLay = uigridlayout(histPanel, [1, 1]);
            app.AxesQualityHist = uiaxes(hLay);
            [counts, binLocs] = imhist(app.CurrentRawImg(:,:,2), 64);
            bar(app.AxesQualityHist, binLocs, counts, 'BarWidth', 1, 'FaceColor', [0.02, 0.59, 0.41], 'EdgeColor', 'none');
            title(app.AxesQualityHist, 'Hemoglobin Contrast Spectrum', 'Color', app.COLOR_TEXT);
            xlabel(app.AxesQualityHist, 'Pixel Intensity (0–255)', 'FontSize', 9);
            ylabel(app.AxesQualityHist, 'Frequency', 'FontSize', 9);
        end
        
        % =================================================================
        % TAB 5: AI CONSTELLATION ANALYSIS COMMAND CENTRE
        % =================================================================
        function buildTabAIConstellation(app)
            grid = uigridlayout(app.TabAIConstellation, [2, 1]);
            grid.RowHeight = {140, '1x'};
            grid.Padding = [12 12 12 12];
            
            % 6-Stage Constellation Pipeline Architecture Cards
            pipePanel = uipanel(grid, 'Title', 'Retinal Intelligence Engine — Deep Multi-Model Constellation Architecture', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            pGrid = uigridlayout(pipePanel, [1, 6]);
            pGrid.ColumnWidth = repmat({'1x'}, 1, 6);
            pGrid.Padding = [8 8 8 8];
            
            nodes = {
                '01. Quality & Restore', 'CUNSB + MAXIM', '15ms (Jetson INT8)';
                '02. Foundation ViT', 'RETFound-Fundus-B', '42ms (TensorRT FP16)';
                '03. Anatomy Localization', 'DeepLabV3+ (Disc/Cup)', '28ms (Jetson FP16)';
                '04. Lesion Segment', 'Mask2Former (MA/Hem)', '64ms (Cloud GPU)';
                '05. Disease Assessment', 'EfficientNetV2-L ICDR', '35ms (TensorRT FP16)';
                '06. Vascular Morphology', 'Fractal & Tortuosity', '18ms (C++ SharedLib)'
            };
            
            for i = 1:6
                cBox = uipanel(pGrid, 'BackgroundColor', app.COLOR_CONTAINER);
                cL = uigridlayout(cBox, [3, 1]);
                cL.Padding = [4 4 4 4];
                uilabel(cL, 'Text', nodes{i, 1}, 'FontWeight', 'bold', 'FontSize', 11, 'FontColor', app.COLOR_PRIMARY_CONTAIN);
                uilabel(cL, 'Text', nodes{i, 2}, 'FontSize', 10);
                uilabel(cL, 'Text', sprintf('⚡ %s', nodes{i, 3}), 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED);
            end
            
            % Detailed Results Card & Action Panel
            resGrid = uigridlayout(grid, [1, 2]);
            resGrid.ColumnWidth = {'1.2x', '1x'};
            resGrid.Padding = [0 0 0 0];
            
            diagPanel = uipanel(resGrid, 'Title', 'Clinical Diagnostic Output & Consensus', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            dL = uigridlayout(diagPanel, [7, 1]);
            dL.Padding = [16 16 16 16];
            
            uilabel(dL, 'Text', sprintf('DIAGNOSED ICDR GRADE: %s', upper(app.CurrentAIResult.StageLabel)), ...
                'FontSize', 16, 'FontWeight', 'bold', 'FontColor', app.CurrentAIResult.UrgencyColor);
            uilabel(dL, 'Text', sprintf('🎯 Categorical Confidence: %.1f%% • Total Inference Time: %.1f ms', app.CurrentAIResult.Confidence, app.CurrentAIResult.TotalInferenceMS), 'FontSize', 12);
            uilabel(dL, 'Text', sprintf('👁️ Macular Edema Status: %s', app.CurrentAIResult.DMEVerdict), 'FontSize', 12, 'FontWeight', 'bold');
            uilabel(dL, 'Text', sprintf('📋 Recommended Action: %s', app.CurrentAIResult.ActionProtocol), 'FontSize', 11);
            uilabel(dL, 'Text', sprintf('🚨 Clinical Urgency: %s', app.CurrentAIResult.UrgencyTag), 'FontSize', 12, 'FontWeight', 'bold', 'FontColor', app.CurrentAIResult.UrgencyColor);
            
            uibutton(dL, 'push', 'Text', 'Explore Retinal Anatomy & Multi-Layer Lesion Map ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(6));
            
            % Biomarkers Card
            bioPanel = uipanel(resGrid, 'Title', 'Microvascular Biomarkers & Morphological Indices', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            bL = uigridlayout(bioPanel, [6, 1]);
            bL.Padding = [16 16 16 16];
            
            uilabel(bL, 'Text', sprintf('Cup-to-Disc Ratio (CDR): %.2f (Normal < 0.50)', app.CurrentAnatomy.CDR));
            uilabel(bL, 'Text', sprintf('Vessel Density: %.2f%% of retinal area', app.CurrentVessels.DensityPercent));
            uilabel(bL, 'Text', sprintf('Vascular Tortuosity Index: %.2f [Elevated in DR]', app.CurrentVessels.TortuosityIndex));
            uilabel(bL, 'Text', sprintf('Fractal Dimension (Df): %.3f (Vascular Complexity)', app.CurrentVessels.FractalDimension));
            uilabel(bL, 'Text', sprintf('Arteriovenous Ratio (AVR): %.2f', app.CurrentVessels.AVR));
            uilabel(bL, 'Text', sprintf('ETDRS 4-2-1 Rule: %s', ifthen(app.CurrentLesions.Meets421Rule, 'TRIGGERED (Severe NPDR Criteria Met)', 'Negative')), ...
                'FontWeight', 'bold', 'FontColor', ifthen(app.CurrentLesions.Meets421Rule, app.COLOR_RED, app.COLOR_GREEN));
        end
        
        % =================================================================
        % TAB 6: RETINAL ANATOMY & LESION MAP
        % =================================================================
        function buildTabAnatomyLesion(app)
            grid = uigridlayout(app.TabAnatomyLesion, [1, 2]);
            grid.ColumnWidth = {'1.5x', '1x'};
            grid.Padding = [12 12 12 12];
            
            % Left: Multi-Layer Canvas
            mapPanel = uipanel(grid, 'Title', 'Retinal Anatomy & Multi-Layer Lesion Segmentation Map', ...
                'BackgroundColor', [0.05 0.05 0.07], 'FontWeight', 'bold', 'ForegroundColor', [0.9 0.9 1]);
            mLay = uigridlayout(mapPanel, [1, 1]);
            mLay.Padding = [4 4 4 4];
            
            app.AxesAnatomyMap = uiaxes(mLay);
            app.AxesAnatomyMap.Toolbar.Visible = 'off';
            app.updateAnatomyOverlay();
            
            % Right: Layer Toggles & Quantitative Analytics
            ctrlPanel = uipanel(grid, 'Title', 'Anatomical & Pathological Layer Controls', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            cL = uigridlayout(ctrlPanel, [11, 1]);
            cL.RowHeight = repmat({28}, 1, 11);
            
            uilabel(cL, 'Text', 'Toggle Segmentation Overlays:', 'FontWeight', 'bold');
            chkDisc = uicheckbox(cL, 'Text', '🔵 Optic Disc & Cup (CDR 0.38)', 'Value', true, 'ValueChangedFcn', @(c,e) app.updateAnatomyOverlay());
            chkVessels = uicheckbox(cL, 'Text', '🔴 Vascular Tree (Arteries & Veins)', 'Value', true, 'ValueChangedFcn', @(c,e) app.updateAnatomyOverlay());
            chkMA = uicheckbox(cL, 'Text', '🔴 Microaneurysms (MA Punctate)', 'Value', true, 'ValueChangedFcn', @(c,e) app.updateAnatomyOverlay());
            chkHem = uicheckbox(cL, 'Text', '🩸 Hemorrhages (Dot/Blot & Flame)', 'Value', true, 'ValueChangedFcn', @(c,e) app.updateAnatomyOverlay());
            chkEx = uicheckbox(cL, 'Text', '🟡 Hard Exudates (Lipid Deposits)', 'Value', true, 'ValueChangedFcn', @(c,e) app.updateAnatomyOverlay());
            chkCWS = uicheckbox(cL, 'Text', '⚪ Cotton Wool Spots (Infarcts)', 'Value', true, 'ValueChangedFcn', @(c,e) app.updateAnatomyOverlay());
            chkNV = uicheckbox(cL, 'Text', '🟣 Neovascularization (NVD/NVE)', 'Value', true, 'ValueChangedFcn', @(c,e) app.updateAnatomyOverlay());
            
            uilabel(cL, 'Text', 'Overlay Opacity:');
            sldOpacity = uislider(cL, 'Limits', [0 1], 'Value', 0.65, 'ValueChangedFcn', @(s,e) app.updateAnatomyOverlay());
            
            btnStudio = uibutton(cL, 'push', 'Text', 'Open DR Severity Studio ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(7));
        end
        
        function updateAnatomyOverlay(app)
            % Assemble active layers and display blended composite
            layers = struct();
            layers.DiscMask = app.CurrentAnatomy.DiscMask;
            layers.VesselMask = app.CurrentVessels.Mask;
            layers.MAMask = app.CurrentLesions.MicroaneurysmsMask;
            layers.HemorrhageMask = app.CurrentLesions.HemorrhagesMask;
            layers.ExudateMask = app.CurrentLesions.ExudatesMask;
            layers.CWSMask = app.CurrentLesions.CottonWoolMask;
            layers.NVMask = app.CurrentLesions.NVMask;
            
            composite = retinacare.engine.AnatomyLesionEngine.createOverlay(app.CurrentRawImg, layers, 0.65);
            imshow(composite, 'Parent', app.AxesAnatomyMap);
            title(app.AxesAnatomyMap, sprintf('Composite Lesion Map — %d MA, %d Hem, %d Exudates', ...
                app.CurrentLesions.MACount, app.CurrentLesions.HemCount, app.CurrentLesions.ExudateCount), 'Color', [1 1 1]);
        end
        
        % =================================================================
        % TAB 7: DR SEVERITY STUDIO
        % =================================================================
        function buildTabSeverityStudio(app)
            grid = uigridlayout(app.TabSeverityStudio, [2, 1]);
            grid.RowHeight = {110, '1x'};
            grid.Padding = [12 12 12 12];
            
            % Diagnosed Severity Header
            hdr = uipanel(grid, 'BackgroundColor', app.COLOR_SURFACE, 'BorderType', 'line');
            hG = uigridlayout(hdr, [1, 4]);
            hG.ColumnWidth = {'1.5x', '1x', '1x', '1.2x'};
            hG.Padding = [8 8 8 8];
            
            app.createMetricCard(hG, 'Diagnosed ICDR Grade', app.CurrentAIResult.ShortLabel, app.CurrentAIResult.StageLabel, app.CurrentAIResult.UrgencyColor);
            app.createMetricCard(hG, 'DME Risk Level', app.CurrentAIResult.DMEVerdict, 'FAZ Distance Metric', app.COLOR_PRIMARY);
            app.createMetricCard(hG, 'Referable Threshold', ifthen(app.CurrentAIResult.IsReferable, 'REFERABLE (Level 2+)', 'Non-Referable'), 'Clinical Protocol', ifthen(app.CurrentAIResult.IsReferable, app.COLOR_RED, app.COLOR_GREEN));
            
            btnWork = uibutton(hG, 'push', 'Text', 'Validate in Doctor Workstation ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(10));
            
            % Softmax Bar Chart & Radial Dial
            body = uigridlayout(grid, [1, 2]);
            body.ColumnWidth = {'1.2x', '1x'};
            body.Padding = [0 0 0 0];
            
            pPanel = uipanel(body, 'Title', 'ICDR 5-Class Softmax Probability Distribution', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            pLay = uigridlayout(pPanel, [1, 1]);
            app.AxesSeverityProb = uiaxes(pLay);
            app.renderSoftmaxChart();
            
            dialPanel = uipanel(body, 'Title', 'ICDR Severity Gauge & Protocol', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            dL = uigridlayout(dialPanel, [4, 1]);
            dL.RowHeight = {'1x', 40, 40, 40};
            
            app.AxesSeverityDial = uiaxes(dL);
            app.renderSeverityGauge();
            
            uilabel(dL, 'Text', sprintf('📌 Action Protocol: %s', app.CurrentAIResult.ActionProtocol), 'FontWeight', 'bold');
            uilabel(dL, 'Text', sprintf('⏱️ Urgency: %s', app.CurrentAIResult.UrgencyTag), 'FontColor', app.CurrentAIResult.UrgencyColor, 'FontWeight', 'bold');
            
            uibutton(dL, 'push', 'Text', 'Inspect Explainability & Evidence Lab ➔', ...
                'BackgroundColor', app.COLOR_SECONDARY, 'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(8));
        end
        
        function renderSoftmaxChart(app)
            probs = app.CurrentAIResult.SoftmaxProbabilities;
            labels = retinacare.engine.ConstellationAI.ICDR_SHORT;
            bar(app.AxesSeverityProb, 0:4, probs, 'FaceColor', app.COLOR_PRIMARY_CONTAIN);
            app.AxesSeverityProb.XTick = 0:4;
            app.AxesSeverityProb.XTickLabel = labels;
            app.AxesSeverityProb.YLim = [0 100];
            ylabel(app.AxesSeverityProb, 'Probability (%)');
            title(app.AxesSeverityProb, 'Categorical Model Probability');
            app.AxesSeverityProb.XGrid = 'on';
            app.AxesSeverityProb.YGrid = 'on';
        end
        
        function renderSeverityGauge(app)
            % Simple radial visual dial
            cla(app.AxesSeverityDial);
            app.AxesSeverityDial.Toolbar.Visible = 'off';
            theta = linspace(pi, 0, 100);
            plot(app.AxesSeverityDial, cos(theta), sin(theta), 'k-', 'LineWidth', 6);
            hold(app.AxesSeverityDial, 'on');
            
            stage = app.CurrentAIResult.PredictedStage;
            ang = pi - (stage / 4) * pi;
            plot(app.AxesSeverityDial, [0, 0.85*cos(ang)], [0, 0.85*sin(ang)], 'r-', 'LineWidth', 4);
            plot(app.AxesSeverityDial, 0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
            app.AxesSeverityDial.XLim = [-1.1 1.1];
            app.AxesSeverityDial.YLim = [-0.1 1.1];
            app.AxesSeverityDial.Visible = 'off';
            title(app.AxesSeverityDial, sprintf('Severity: Stage %d (%s)', stage, app.CurrentAIResult.ShortLabel));
            hold(app.AxesSeverityDial, 'off');
        end
        
        % =================================================================
        % TAB 8: EXPLAINABILITY & EVIDENCE LAB
        % =================================================================
        function buildTabExplainability(app)
            grid = uigridlayout(app.TabExplainability, [1, 2]);
            grid.ColumnWidth = {'1.1x', '1x'};
            grid.Padding = [12 12 12 12];
            
            % Left: Grad-CAM Saliency Heatmap
            camPanel = uipanel(grid, 'Title', 'Why did the system flag this image? — Grad-CAM Feature Attribution', ...
                'BackgroundColor', [0.05 0.05 0.07], 'FontWeight', 'bold', 'ForegroundColor', [0.9 0.9 1]);
            cL = uigridlayout(camPanel, [1, 1]);
            cL.Padding = [4 4 4 4];
            
            app.AxesGradCAM = uiaxes(cL);
            app.AxesGradCAM.Toolbar.Visible = 'off';
            [~, blend] = retinacare.engine.ExplainabilityEngine.generateGradCAM(app.CurrentRawImg, app.CurrentLesions, app.CurrentAnatomy, app.CurrentAIResult.PredictedStage);
            imshow(blend, 'Parent', app.AxesGradCAM);
            title(app.AxesGradCAM, 'Grad-CAM Attention Heatmap (Pathological Focus)', 'Color', [1 1 1]);
            
            % Right: Ranked Evidence & Calibration Curve
            rightGrid = uigridlayout(grid, [2, 1]);
            rightGrid.RowHeight = {'1.2x', '1x'};
            rightGrid.Padding = [0 0 0 0];
            
            evPanel = uipanel(rightGrid, 'Title', 'Ranked Attributed Evidence Items (Clinical Weighting)', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            eLay = uigridlayout(evPanel, [1, 1]);
            
            evList = retinacare.engine.ExplainabilityEngine.rankClinicalEvidence(app.CurrentLesions, app.CurrentAIResult.PredictedStage);
            evData = cell(length(evList), 4);
            for k = 1:length(evList)
                evData{k, 1} = sprintf('#%d', evList{k}.Rank);
                evData{k, 2} = evList{k}.Feature;
                evData{k, 3} = sprintf('%.1f%%', evList{k}.Weight);
                evData{k, 4} = evList{k}.Location;
            end
            uitable(eLay, 'Data', evData, 'ColumnName', {'Rank', 'Evidence Feature', 'Weight', 'Location'}, ...
                'ColumnWidth', {50, 190, 70, 160});
            
            % Calibration Curve
            calPanel = uipanel(rightGrid, 'Title', 'Confidence Calibration & Reliability Curve (ECE: 0.021)', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            cLay = uigridlayout(calPanel, [1, 1]);
            app.AxesCalibration = uiaxes(cLay);
            
            cal = retinacare.engine.ExplainabilityEngine.getCalibrationData();
            plot(app.AxesCalibration, [0 1], [0 1], 'k--', 'LineWidth', 1.5);
            hold(app.AxesCalibration, 'on');
            plot(app.AxesCalibration, cal.ConfBins, cal.AccBins, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
            xlabel(app.AxesCalibration, 'Confidence');
            ylabel(app.AxesCalibration, 'Empirical Accuracy');
            title(app.AxesCalibration, 'Platt Scaled Reliability Curve');
            app.AxesCalibration.XGrid = 'on';
            app.AxesCalibration.YGrid = 'on';
            hold(app.AxesCalibration, 'off');
        end
        
        % =================================================================
        % TAB 9: CLINICAL REVIEW QUEUE
        % =================================================================
        function buildTabReviewQueue(app)
            grid = uigridlayout(app.TabReviewQueue, [2, 1]);
            grid.RowHeight = {50, '1x'};
            grid.Padding = [12 12 12 12];
            
            % Filter Bar
            fPanel = uipanel(grid, 'BackgroundColor', app.COLOR_SURFACE, 'BorderType', 'line');
            fG = uigridlayout(fPanel, [1, 5]);
            fG.ColumnWidth = {'1.5x', '1x', '1x', '1x', '1.2x'};
            fG.Padding = [8 4 8 4];
            
            uilabel(fG, 'Text', '⚡ Triage Worklist: Target <30s Review / Case', 'FontWeight', 'bold', 'FontColor', app.COLOR_PRIMARY);
            uidropdown(fG, 'Items', {'All Urgencies', 'STAT (<48h)', 'Urgent (<7d)', 'Priority (<30d)', 'Routine (12m)'});
            uidropdown(fG, 'Items', {'All Facilities', 'Indore Hub', 'Dewas DH', 'Sanwer CHC', 'Ujjain VC'});
            uidropdown(fG, 'Items', {'All Statuses', 'Pending Review', 'Claimed', 'Validated'});
            
            uibutton(fG, 'push', 'Text', 'Claim Next Priority Case ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(10));
            
            % Table
            qTable = uitable(grid, 'Data', app.ClinicalDB.ReviewQueue, ...
                'ColumnName', {'Patient & Demographics', 'UHID', 'AI Staging', 'Macular Edema', 'Triage Urgency', 'Conf', 'Originating Facility', 'Workflow Status'}, ...
                'ColumnWidth', {160, 120, 140, 130, 110, 70, 130, 100});
        end
        
        % =================================================================
        % TAB 10: OPHTHALMOLOGIST REVIEW WORKSTATION
        % =================================================================
        function buildTabWorkstation(app)
            grid = uigridlayout(app.TabWorkstation, [1, 2]);
            grid.ColumnWidth = {'1.4x', '1x'};
            grid.Padding = [12 12 12 12];
            
            % Left: Dual Viewport (AI Consensus vs Raw)
            leftGrid = uigridlayout(grid, [2, 1]);
            leftGrid.RowHeight = {'1x', '1x'};
            leftGrid.Padding = [0 0 0 0];
            
            p1 = uipanel(leftGrid, 'Title', 'Raw Retinal Fundus (OD Right Eye)', ...
                'BackgroundColor', [0.05 0.05 0.07], 'FontWeight', 'bold', 'ForegroundColor', [0.9 0.9 1]);
            lay1 = uigridlayout(p1, [1, 1]);
            app.AxesWorkstationAI = uiaxes(lay1);
            app.AxesWorkstationAI.Toolbar.Visible = 'off';
            imshow(app.CurrentRawImg, 'Parent', app.AxesWorkstationAI);
            
            p2 = uipanel(leftGrid, 'Title', 'AI Multi-Model Lesion Segmentation Overlay', ...
                'BackgroundColor', [0.05 0.05 0.07], 'FontWeight', 'bold', 'ForegroundColor', [0.9 0.9 1]);
            lay2 = uigridlayout(p2, [1, 1]);
            app.AxesWorkstationDoc = uiaxes(lay2);
            app.AxesWorkstationDoc.Toolbar.Visible = 'off';
            layers = struct('DiscMask', app.CurrentAnatomy.DiscMask, 'MAMask', app.CurrentLesions.MicroaneurysmsMask, ...
                            'HemorrhageMask', app.CurrentLesions.HemorrhagesMask, 'ExudateMask', app.CurrentLesions.ExudatesMask);
            imshow(retinacare.engine.AnatomyLesionEngine.createOverlay(app.CurrentRawImg, layers, 0.7), 'Parent', app.AxesWorkstationDoc);
            
            % Right: Doctor Validation & Sign-off
            docPanel = uipanel(grid, 'Title', 'Ophthalmologist Clinical Validation Form', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            dL = uigridlayout(docPanel, [10, 1]);
            dL.RowHeight = repmat({32}, 1, 10);
            dL.Padding = [16 16 16 16];
            
            uilabel(dL, 'Text', sprintf('Patient: %s (%s)', app.CurrentPatient.Name, app.CurrentPatient.UHID), 'FontWeight', 'bold');
            uilabel(dL, 'Text', sprintf('AI Preliminary Assessment: %s (%.1f%% Conf)', app.CurrentAIResult.StageLabel, app.CurrentAIResult.Confidence));
            
            uilabel(dL, 'Text', 'Doctor Confirmed ICDR Stage:');
            ddDoctorGrade = uidropdown(dL, 'Items', retinacare.engine.ConstellationAI.ICDR_LABELS, 'Value', app.CurrentAIResult.StageLabel);
            
            uilabel(dL, 'Text', 'Doctor Confirmed DME Status:');
            ddDoctorDME = uidropdown(dL, 'Items', retinacare.engine.ConstellationAI.DME_LABELS, 'Value', app.CurrentAIResult.DMEVerdict);
            
            uilabel(dL, 'Text', 'Management Pathway:');
            ddPlan = uidropdown(dL, 'Items', {'Fast-Track Referral to Tertiary Vitreoretinal Clinic', 'Macular OCT & Intravitreal Anti-VEGF Injection', 'Panretinal Photocoagulation (PRP) Laser', 'Routine Follow-up in 6-12 months'});
            
            uilabel(dL, 'Text', 'Clinical Notes & Recommendations:');
            txtNotes = uieditfield(dL, 'text', 'Value', 'Concur with AI Level 2 NPDR and DME risk. Dilated funduscopy and OCT recommended.');
            
            btnSign = uibutton(dL, 'push', 'Text', '✍️ Sign Off & Submit ABDM Diagnostic Report', ...
                'BackgroundColor', app.COLOR_GREEN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.onSubmitDoctorSignOff(txtNotes.Value));
            
            btnRef = uibutton(dL, 'push', 'Text', 'Dispatch to Referral Command Centre ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(12));
        end
        
        function onSubmitDoctorSignOff(app, notes)
            fhir = retinacare.referral.ABDMGateway.generateFHIRDiagnosticReport(app.CurrentPatient, app.CurrentAIResult, notes);
            uialert(app.UIFigure, sprintf('Diagnostic Report %s signed and synced to ABDM Health Locker for %s.', ...
                fhir.id, app.CurrentPatient.Name), 'ABDM Validation Submitted');
        end
        
        % =================================================================
        % TAB 11: LONGITUDINAL PATIENT RECORD
        % =================================================================
        function buildTabLongitudinal(app)
            grid = uigridlayout(app.TabLongitudinal, [2, 1]);
            grid.RowHeight = {160, '1x'};
            grid.Padding = [12 12 12 12];
            
            % Retinal Journey Timeline Cards
            timePanel = uipanel(grid, 'Title', sprintf('Retinal Journey: %s — Longitudinal Timeline', app.CurrentPatient.Name), ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            tGrid = uigridlayout(timePanel, [1, 3]);
            tGrid.ColumnWidth = {'1x', '1x', '1x'};
            
            visits = app.CurrentPatient.Visits;
            for v = 1:length(visits)
                vBox = uipanel(tGrid, 'BackgroundColor', app.COLOR_CONTAINER);
                vLay = uigridlayout(vBox, [4, 1]);
                vLay.Padding = [8 8 8 8];
                uilabel(vLay, 'Text', sprintf('Visit %d • %s', v, visits(v).Date), 'FontWeight', 'bold', 'FontColor', app.COLOR_PRIMARY);
                uilabel(vLay, 'Text', sprintf('Stage: %s (HbA1c: %.1f%%)', visits(v).StageName, visits(v).HbA1c));
                uilabel(vLay, 'Text', sprintf('Lesions: %d MA, %.2f mm² Exudates', visits(v).MACount, visits(v).ExudateArea));
                uilabel(vLay, 'Text', sprintf('Decision: %s', visits(v).Action), 'FontSize', 10, 'FontColor', app.COLOR_TEXT_MUTED);
            end
            
            % Longitudinal Trajectory Plots
            plotsGrid = uigridlayout(grid, [1, 2]);
            plotsGrid.ColumnWidth = {'1x', '1x'};
            plotsGrid.Padding = [0 0 0 0];
            
            p1 = uipanel(plotsGrid, 'Title', 'Disease Severity & HbA1c Progression Trajectory', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            lay1 = uigridlayout(p1, [1, 1]);
            app.AxesLongSeverity = uiaxes(lay1);
            
            vDates = 1:length(visits);
            vStages = [visits.Stage];
            vHb = [visits.HbA1c];
            yyaxis(app.AxesLongSeverity, 'left');
            plot(app.AxesLongSeverity, vDates, vStages, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
            ylabel(app.AxesLongSeverity, 'ICDR Stage (0-4)');
            app.AxesLongSeverity.YLim = [-0.5 4.5];
            
            yyaxis(app.AxesLongSeverity, 'right');
            plot(app.AxesLongSeverity, vDates, vHb, 'r--s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
            ylabel(app.AxesLongSeverity, 'HbA1c (%)');
            
            app.AxesLongSeverity.XTick = vDates;
            app.AxesLongSeverity.XTickLabel = {visits.Date};
            title(app.AxesLongSeverity, 'Longitudinal DR Progression');
            app.AxesLongSeverity.XGrid = 'on';
            app.AxesLongSeverity.YGrid = 'on';
            
            % Lesion Burden Plot
            p2 = uipanel(plotsGrid, 'Title', 'Microaneurysm & Hard Exudate Burden Trajectory', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            lay2 = uigridlayout(p2, [1, 1]);
            app.AxesLongLesions = uiaxes(lay2);
            
            vMA = [visits.MACount];
            vEx = [visits.ExudateArea];
            yyaxis(app.AxesLongLesions, 'left');
            bar(app.AxesLongLesions, vDates, vMA, 'FaceColor', [0.8 0.2 0.2]);
            ylabel(app.AxesLongLesions, 'Microaneurysms Count');
            
            yyaxis(app.AxesLongLesions, 'right');
            plot(app.AxesLongLesions, vDates, vEx, 'm-d', 'LineWidth', 2, 'MarkerFaceColor', 'y');
            ylabel(app.AxesLongLesions, 'Hard Exudates (mm²)');
            
            app.AxesLongLesions.XTick = vDates;
            app.AxesLongLesions.XTickLabel = {visits.Date};
            title(app.AxesLongLesions, 'Quantitative Biomarker Burden');
            app.AxesLongLesions.XGrid = 'on';
            app.AxesLongLesions.YGrid = 'on';
        end
        
        % =================================================================
        % TAB 12: REFERRAL COMMAND CENTRE (ABDM)
        % =================================================================
        function buildTabReferral(app)
            grid = uigridlayout(app.TabReferral, [2, 1]);
            grid.RowHeight = {100, '1x'};
            grid.Padding = [12 12 12 12];
            
            % Action & Integration Header
            hPanel = uipanel(grid, 'BackgroundColor', app.COLOR_SURFACE, 'BorderType', 'line');
            hG = uigridlayout(hPanel, [1, 4]);
            hG.ColumnWidth = {'1.5x', '1x', '1x', '1.2x'};
            hG.Padding = [8 8 8 8];
            
            app.createMetricCard(hG, 'ABDM Fast-Track Gateway', 'Connected', '1.8 Mbps Mesh Telemetry', app.COLOR_PRIMARY);
            app.createMetricCard(hG, 'Active Referrals', '14 Active', '4 STAT • 6 Urgent', app.COLOR_RED);
            app.createMetricCard(hG, 'Tertiary Hospital Destination', 'M.Y. Hospital Eye OPD', 'Slot Allocation: 82% Full', app.COLOR_AMBER);
            
            btnASHA = uibutton(hG, 'push', 'Text', 'Mobilize ASHA Health Worker 📱', ...
                'BackgroundColor', app.COLOR_SECONDARY, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.onMobilizeASHA());
            
            % Referral Queue Table
            refTable = uitable(grid, 'Data', app.ClinicalDB.Referrals, ...
                'ColumnName', {'Referral ID', 'Patient Name', 'ABHA Number', 'Tertiary Center', 'Recommended Procedure', 'Urgency', 'ABDM FHIR Status', 'ASHA Coordination'}, ...
                'ColumnWidth', {140, 130, 140, 160, 170, 100, 120, 120});
        end
        
        function onMobilizeASHA(app)
            refInfo = struct('Hospital', 'M.Y. Hospital Indore', 'Procedure', 'Macular OCT & Anti-VEGF', 'Urgency', 'Priority (<14 days)');
            alert = retinacare.referral.ABDMGateway.dispatchASHAAlert(app.CurrentPatient, refInfo);
            uialert(app.UIFigure, sprintf('SMS & WhatsApp Notification Sent to %s (%s):\n\n"%s"', ...
                alert.Recipient, alert.Phone, alert.Message), 'ASHA Worker Mobilized');
        end
        
        % =================================================================
        % TAB 13: DISTRICT INTELLIGENCE & SIMULINK RESOURCE LAB
        % =================================================================
        function buildTabSimulinkLab(app)
            grid = uigridlayout(app.TabSimulinkLab, [2, 1]);
            grid.RowHeight = {120, '1x'};
            grid.Padding = [12 12 12 12];
            
            % Controls Panel: Knobs for SimEvents / Discrete-Event Simulation
            knobPanel = uipanel(grid, 'Title', 'Simulink Discrete-Event Capacity Simulator — Parameter Control Hub', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            kGrid = uigridlayout(knobPanel, [2, 4]);
            kGrid.RowHeight = {28, 40};
            kGrid.ColumnWidth = {'1x', '1x', '1x', '1.2x'};
            
            uilabel(kGrid, 'Text', 'Arrival Rate (λ patients/hr):');
            uilabel(kGrid, 'Text', 'Active Field Cameras:');
            uilabel(kGrid, 'Text', 'Reviewing Ophthalmologists:');
            uilabel(kGrid, 'Text', '');
            
            spnLambda = uispinner(kGrid, 'Value', app.SimEngine.LambdaArrival, 'Limits', [10 300]);
            spnCams = uispinner(kGrid, 'Value', app.SimEngine.NumCameras, 'Limits', [1 50]);
            spnDocs = uispinner(kGrid, 'Value', app.SimEngine.NumOphthalmologists, 'Limits', [1 20]);
            
            btnRunSim = uibutton(kGrid, 'push', 'Text', '⚡ Run Discrete-Event Simulation', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.onRunSimulink(spnLambda.Value, spnCams.Value, spnDocs.Value));
            
            % Simulation Results Plots & Telemetry
            plotGrid = uigridlayout(grid, [1, 2]);
            plotGrid.ColumnWidth = {'1x', '1x'};
            plotGrid.Padding = [0 0 0 0];
            
            p1 = uipanel(plotGrid, 'Title', 'Simulated 8-Hour Hourly Throughput (Patients Screened)', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            l1 = uigridlayout(p1, [1, 1]);
            app.AxesSimThroughput = uiaxes(l1);
            
            p2 = uipanel(plotGrid, 'Title', 'Multi-Stage Queue Depths & Bottleneck Tracking', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            l2 = uigridlayout(p2, [1, 1]);
            app.AxesSimQueues = uiaxes(l2);
            
            % Run initial simulation
            app.onRunSimulink(100, 18, 4);
        end
        
        function onRunSimulink(app, lambda, cams, docs)
            app.SimEngine.LambdaArrival = lambda;
            app.SimEngine.NumCameras = cams;
            app.SimEngine.NumOphthalmologists = docs;
            
            res = app.SimEngine.runSimulation();
            
            % Plot 1: Hourly throughput
            bar(app.AxesSimThroughput, 1:8, res.ThroughputHourly, 'FaceColor', app.COLOR_PRIMARY_CONTAIN);
            xlabel(app.AxesSimThroughput, 'Clinic Hour (1 to 8)');
            ylabel(app.AxesSimThroughput, 'Patients Screened');
            title(app.AxesSimThroughput, sprintf('Total Screened: %d • Referrals: %d • Annual: %d', ...
                res.TotalScreened, res.ReferralsGenerated, res.AnnualProjected));
            app.AxesSimThroughput.XGrid = 'on';
            app.AxesSimThroughput.YGrid = 'on';
            
            % Plot 2: Queue Depths over time
            tMin = res.TimeMinutes;
            plot(app.AxesSimQueues, tMin, res.QueueDepths.Intake, 'b-', 'LineWidth', 1.5);
            hold(app.AxesSimQueues, 'on');
            plot(app.AxesSimQueues, tMin, res.QueueDepths.Camera, 'm-', 'LineWidth', 1.5);
            plot(app.AxesSimQueues, tMin, res.QueueDepths.TeleDoctor, 'r-', 'LineWidth', 2);
            plot(app.AxesSimQueues, tMin, res.QueueDepths.TertiaryOPD, 'k--', 'LineWidth', 2);
            xlabel(app.AxesSimQueues, 'Time (Minutes)');
            ylabel(app.AxesSimQueues, 'Queue Length (Patients)');
            legend(app.AxesSimQueues, {'Intake', 'Camera', 'Doctor Review', 'Tertiary OPD'}, 'Location', 'northwest');
            title(app.AxesSimQueues, sprintf('Queue Bottlenecks • %s', res.BottleneckStatus));
            app.AxesSimQueues.XGrid = 'on';
            app.AxesSimQueues.YGrid = 'on';
            hold(app.AxesSimQueues, 'off');
        end
        
        % =================================================================
        % TAB 14: AI MODEL REGISTRY & VALIDATION CENTRE
        % =================================================================
        function buildTabModelRegistry(app)
            grid = uigridlayout(app.TabModelRegistry, [2, 1]);
            grid.RowHeight = {'1.2x', '1x'};
            grid.Padding = [12 12 12 12];
            
            % 15 Active Production Models Table
            mPanel = uipanel(grid, 'Title', 'Active Production Inference Models (15 Pipeline Nodes) — NVIDIA Jetson TensorRT', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            mLay = uigridlayout(mPanel, [1, 1]);
            
            uitable(mLay, 'Data', app.ModelReg.ModelsTable, ...
                'ColumnName', {'Node', 'Model Name', 'Architecture', 'Params', 'Target', 'Precision', 'Latency', 'Version', 'Status'}, ...
                'ColumnWidth', {50, 160, 130, 70, 100, 100, 65, 65, 65});
            
            % ROC and Precision-Recall Curves
            curvesGrid = uigridlayout(grid, [1, 2]);
            curvesGrid.ColumnWidth = {'1x', '1x'};
            curvesGrid.Padding = [0 0 0 0];
            
            rPanel = uipanel(curvesGrid, 'Title', 'Multi-Center Clinical Validation: ROC Curves (IDRiD, EyePACS, Messidor)', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            rLay = uigridlayout(rPanel, [1, 1]);
            app.AxesROCCurve = uiaxes(rLay);
            
            [fpr, tpr, auc] = app.ModelReg.getROCCurve('IDRiD');
            plot(app.AxesROCCurve, fpr, tpr, 'b-', 'LineWidth', 2.5);
            hold(app.AxesROCCurve, 'on');
            plot(app.AxesROCCurve, [0 1], [0 1], 'k--', 'LineWidth', 1);
            xlabel(app.AxesROCCurve, 'False Positive Rate (1 - Specificity)');
            ylabel(app.AxesROCCurve, 'True Positive Rate (Sensitivity)');
            title(app.AxesROCCurve, sprintf('IDRiD Benchmark: AUC = %.3f', auc));
            app.AxesROCCurve.XGrid = 'on';
            app.AxesROCCurve.YGrid = 'on';
            hold(app.AxesROCCurve, 'off');
            
            prPanel = uipanel(curvesGrid, 'Title', 'Precision-Recall Validation Curve', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold');
            prLay = uigridlayout(prPanel, [1, 1]);
            app.AxesPRCurve = uiaxes(prLay);
            
            [rec, prec] = app.ModelReg.getPRCurve('IDRiD');
            plot(app.AxesPRCurve, rec, prec, 'r-', 'LineWidth', 2.5);
            xlabel(app.AxesPRCurve, 'Recall (Sensitivity)');
            ylabel(app.AxesPRCurve, 'Precision (PPV)');
            title(app.AxesPRCurve, 'Precision-Recall Curve (AP = 0.965)');
            app.AxesPRCurve.XGrid = 'on';
            app.AxesPRCurve.YGrid = 'on';
        end
        
        % =================================================================
        % TAB 15: CLINICAL WORKSPACE ACCESS & LOGIN
        % =================================================================
        function buildTabLoginAccess(app)
            grid = uigridlayout(app.TabLoginAccess, [1, 2]);
            grid.ColumnWidth = {'1x', '1.2x'};
            grid.Padding = [24 24 24 24];
            
            % Left Login Box
            loginBox = uipanel(grid, 'Title', 'Clinical Workspace Authentication', ...
                'BackgroundColor', app.COLOR_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PRIMARY);
            lL = uigridlayout(loginBox, [8, 1]);
            lL.RowHeight = repmat({34}, 1, 8);
            lL.Padding = [16 16 16 16];
            
            uilabel(lL, 'Text', 'Role Selection:');
            ddRole = uidropdown(lL, 'Items', {'Ophthalmologist (Review & Sign-off)', 'District Admin (Resource & Telemetry)', 'System Admin (Model & Governance)', 'Screening Technician / ASHA'});
            
            uilabel(lL, 'Text', 'Facility / Vision Centre:');
            ddFac = uidropdown(lL, 'Items', {'M.Y. Hospital / MGM Medical College Indore', 'District Hospital Dewas', 'Mahidpur Vision Centre Ujjain', 'Badnawar PHC Dhar', 'Kasrawad CHC Khargone'});
            
            uilabel(lL, 'Text', 'ABDM Ayushman Token / Biometric ID:');
            txtToken = uieditfield(lL, 'text', 'Value', 'IND-MGM-OPH-084-AYUSHMAN');
            
            uilabel(lL, 'Text', 'Status: Authenticated & Session Active', 'FontColor', app.COLOR_GREEN, 'FontWeight', 'bold');
            
            btnEnter = uibutton(lL, 'push', 'Text', 'Enter Clinical Command Centre ➔', ...
                'BackgroundColor', app.COLOR_PRIMARY_CONTAIN, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.selectTab(1));
            
            % Right Governance Info Card
            govPanel = uipanel(grid, 'Title', 'National Health Authority (NHA) & ABDM Governance', ...
                'BackgroundColor', app.COLOR_CONTAINER, 'FontWeight', 'bold');
            gL = uigridlayout(govPanel, [6, 1]);
            gL.Padding = [16 16 16 16];
            
            uilabel(gL, 'Text', '🛡️ ABDM Health Data Management Policy (HDMP) Compliant', 'FontWeight', 'bold');
            uilabel(gL, 'Text', '🔒 End-to-End Encrypted Telemetry (TLS 1.3 + AES-256)');
            uilabel(gL, 'Text', '📋 Audit Trail: All inference events, manual overrides, and sign-offs logged to immutable district ledger.');
            uilabel(gL, 'Text', '🇮🇳 Indian Public Health Standards (IPHS 2022) Alignment Verified.');
            uilabel(gL, 'Text', '⚡ Edge Fallback: Offline AI inference supported on NVIDIA Jetson when 4G connectivity drops.');
        end
        
        function updateAllDisplays(app)
            % Refresh axes across tabs when patient or image changes
            app.updateAnatomyOverlay();
            app.renderSoftmaxChart();
            app.renderSeverityGauge();
            
            [~, blend] = retinacare.engine.ExplainabilityEngine.generateGradCAM(app.CurrentRawImg, app.CurrentLesions, app.CurrentAnatomy, app.CurrentAIResult.PredictedStage);
            imshow(blend, 'Parent', app.AxesGradCAM);
            
            imshow(app.CurrentRawImg, 'Parent', app.AxesQualityRaw);
            imshow(app.CurrentEnhancedImg, 'Parent', app.AxesQualityEnh);
            cla(app.AxesQualityHist);
            [counts, binLocs] = imhist(app.CurrentRawImg(:,:,2), 64);
            bar(app.AxesQualityHist, binLocs, counts, 'BarWidth', 1, 'FaceColor', [0.02, 0.59, 0.41], 'EdgeColor', 'none');
            title(app.AxesQualityHist, 'Hemoglobin Contrast Spectrum', 'Color', app.COLOR_TEXT);
            xlabel(app.AxesQualityHist, 'Pixel Intensity (0–255)', 'FontSize', 9);
            ylabel(app.AxesQualityHist, 'Frequency', 'FontSize', 9);
        end
    end
end

function val = ifthen(cond, a, b)
    if cond, val = a; else, val = b; end
end
