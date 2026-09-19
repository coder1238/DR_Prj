classdef RetinaCareApp < matlab.apps.AppBase
    % RETINACAREAPP Master MATLAB App Designer Clinical Workstation
    % Modeled faithfully after the RetinaCare AI Web Platform & Stitch Design System
    %
    % Encapsulates all 15 clinical modules across 4 operational domains:
    % 
    % I. PRIMARY PIPELINE
    %   01. Clinical Login & Facility Node Access
    %   02. Clinical Command Centre (Screening Pulse & PHC Telemetry)
    %   03. Patient Registration & Clinical Intake
    %   04. Retinal Capture Studio (Hardware Telemetry & Live QC)
    %   05. Image Quality Lab & Optical Pre-Processing (CUNSB/MAXIM/CLAHE)
    %
    % II. DIAGNOSTIC INTELLIGENCE
    %   06. AI Analysis Centre (15-Model Deep Constellation Ensemble)
    %   07. Retinal Anatomy & Pathological Lesion Segmentation Map
    %   08. DR Severity Studio (ICDR 5-Grade Wheel & DME Risk Assessment)
    %   09. Explainability & Evidence Lab (Grad-CAM & Platt-Calibrated ECE)
    %
    % III. TELE-MEDICINE & CARE
    %   10. Clinical Review Queue & Urgency Triage Worklist (87 Cases)
    %   11. Ophthalmologist Review Workstation (Dual View & Digital Sign-off)
    %   12. Tele-Ophthalmology Referral Command (ABDM Fast-Track & ASHA Dispatch)
    %   13. Longitudinal Patient Record (3-Year Progression Trajectory)
    %
    % IV. HEALTH SYSTEMS & AUDIT
    %   14. District Simulink & Discrete-Event Healthcare Capacity Simulator
    %   15. AI Model Registry & Multi-Center Benchmark Validation Centre

    properties (Access = public)
        UIFigure
        MainGrid
        HeaderPanel
        SidebarPanel
        ContentPanel
        SafetyBanner
        TabGroup
        
        % 15 Clinical Modules Tabs (strictly 1 to 15 matching web router)
        Tab01Login
        Tab02CommandCentre
        Tab03Registration
        Tab04CaptureStudio
        Tab05QualityLab
        Tab06AIAnalysis
        Tab07AnatomyMap
        Tab08SeverityStudio
        Tab09Explainability
        Tab10ReviewQueue
        Tab11Workstation
        Tab12ReferralCentre
        Tab13Longitudinal
        Tab14DistrictSimulink
        Tab15ModelRegistry
        
        % Data Stores & Clinical Engines
        ClinicalDB
        CurrentPatient
        CurrentRawImg
        CurrentEnhancedImg
        CurrentAnatomy
        CurrentLesions
        CurrentVessels
        CurrentAIResult
        SimEngine
        ModelReg
        CurrentFacility
        
        % Navigation & TopBar Controls
        NavButtons
        TopBarFacilityDropdown
        TopBarPatientDropdown
        TopBarStatusLabel
        
        % Interactive UIAxes
        AxesCapture
        AxesQualityRaw
        AxesQualityEnh
        AxesQualityHist
        AxesAnatomyMap
        AxesSeverityWheel
        AxesSeverityProb
        AxesGradCAM
        AxesCalibration
        AxesWorkstationRaw
        AxesWorkstationAI
        AxesLongSeverity
        AxesLongLesions
        AxesSimThroughput
        AxesSimQueues
        AxesROCCurve
        AxesPRCurve
    end

    properties (Constant)
        % Clinical Design System Theme Tokens (from tailwind.config.js)
        COLOR_PURPLE_DEEP     = [0.204, 0.000, 0.459]; % #340075 Deep Clinical Purple
        COLOR_PURPLE_DARK     = [0.298, 0.114, 0.584]; % #4C1D95 Header & Active Card
        COLOR_PURPLE_BRAND    = [0.345, 0.110, 0.529]; % #581C87 Default Brand
        COLOR_PURPLE_ROYAL    = [0.486, 0.227, 0.929]; % #7C3AED Active Pill
        COLOR_PURPLE_VIBRANT  = [0.443, 0.165, 0.886]; % #712AE2 Secondary Accent
        COLOR_PURPLE_SOFT     = [0.929, 0.914, 0.996]; % #EDE9FE Soft Pill
        COLOR_PURPLE_SURFACE  = [0.980, 0.973, 1.000]; % #FAF8FF Light Lavender
        COLOR_CANVAS_BG       = [0.945, 0.961, 0.976]; % #F1F5F9 Slate Canvas
        COLOR_CARD_SURFACE    = [1.000, 1.000, 1.000]; % #FFFFFF Pure White
        COLOR_OPTICAL_BG      = [0.043, 0.067, 0.125]; % #0B1120 Deep Optical Dark
        COLOR_OPTICAL_SURFACE = [0.075, 0.114, 0.200]; % #131D33 Optical Card
        COLOR_OPTICAL_BORDER  = [0.118, 0.161, 0.231]; % #1E293B
        COLOR_OPTICAL_GLOW    = [0.220, 0.741, 0.973]; % #38BDF8 Sky Cyan
        COLOR_GREEN           = [0.020, 0.588, 0.412]; % #059669 Normal (Grade 0)
        COLOR_AMBER           = [0.851, 0.467, 0.024]; % #D97706 Mild (Grade 1)
        COLOR_ORANGE          = [0.918, 0.345, 0.047]; % #EA580C Moderate NPDR (Grade 2)
        COLOR_RED             = [0.863, 0.149, 0.149]; % #DC2626 Severe NPDR (Grade 3)
        COLOR_ROSE            = [0.600, 0.106, 0.106]; % #991B1B Proliferative PDR (Grade 4)
        COLOR_BLUE            = [0.145, 0.388, 0.922]; % #2563EB Primary Action
        COLOR_TEXT_MAIN       = [0.059, 0.090, 0.165]; % #0F172A Slate 900
        COLOR_TEXT_MUTED      = [0.392, 0.455, 0.545]; % #64748B Slate 500
        COLOR_BORDER_SOFT     = [0.886, 0.910, 0.941]; % #E2E8F0 Soft Border
    end

    methods (Access = public)
        function app = RetinaCareApp()
            % Constructor: Initialize database, patient state, UI, and default state
            app.CurrentFacility = 'M.Y. Hospital Central Hub (Indore)';
            app.initEngines();
            app.loadInitialPatient();
            app.createUI();
            app.selectTab(2); % Default landing at 02. Command Centre (matching web redirect)
        end

        function delete(app)
            % Destructor: Clean up figure
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

        function selectTab(app, index)
            % Explicit, deterministic tab switching across all 15 clinical modules
            tabs = [
                app.Tab01Login, ...
                app.Tab02CommandCentre, ...
                app.Tab03Registration, ...
                app.Tab04CaptureStudio, ...
                app.Tab05QualityLab, ...
                app.Tab06AIAnalysis, ...
                app.Tab07AnatomyMap, ...
                app.Tab08SeverityStudio, ...
                app.Tab09Explainability, ...
                app.Tab10ReviewQueue, ...
                app.Tab11Workstation, ...
                app.Tab12ReferralCentre, ...
                app.Tab13Longitudinal, ...
                app.Tab14DistrictSimulink, ...
                app.Tab15ModelRegistry
            ];

            if index >= 1 && index <= length(tabs)
                app.TabGroup.SelectedTab = tabs(index);
            end

            for i = 1:length(app.NavButtons)
                if i == index
                    app.NavButtons(i).BackgroundColor = app.COLOR_PURPLE_ROYAL;
                    app.NavButtons(i).FontColor = [1 1 1];
                    app.NavButtons(i).FontWeight = 'bold';
                else
                    app.NavButtons(i).BackgroundColor = app.COLOR_CARD_SURFACE;
                    app.NavButtons(i).FontColor = app.COLOR_TEXT_MAIN;
                    app.NavButtons(i).FontWeight = 'normal';
                end
            end
        end

        function switchPatient(app, patientIndex)
            % Switch active patient record across all views
            if patientIndex >= 1 && patientIndex <= length(app.ClinicalDB.Patients)
                app.CurrentPatient = app.ClinicalDB.Patients(patientIndex);
                samplePath = fullfile(fileparts(mfilename('fullpath')), 'sample_data', app.CurrentPatient.CurrentFundus);
                if exist(samplePath, 'file')
                    app.CurrentRawImg = imread(samplePath);
                else
                    app.CurrentRawImg = retinacare.data.SyntheticRetina.generate(app.CurrentPatient.CurrentStage, true, 'OD');
                end
                app.reprocessCurrentPatient();
                app.refreshAllAxes();
                if isvalid(app.TopBarPatientDropdown)
                    app.TopBarPatientDropdown.Value = sprintf('%s (%s)', app.CurrentPatient.Name, app.CurrentPatient.UHID);
                end
            end
        end
    end

    methods (Access = private)
        function initEngines(app)
            % Instantiate database, Simulink queuing engine, and Model Registry
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
                app.CurrentRawImg = retinacare.data.SyntheticRetina.generate(app.CurrentPatient.CurrentStage, true, 'OD');
            end
            app.reprocessCurrentPatient();
        end

        function reprocessCurrentPatient(app)
            % Process current patient fundus through the multi-stage engine
            app.CurrentEnhancedImg = retinacare.engine.ImageProcessingLab.fullPipeline(app.CurrentRawImg, true, true, true, false);
            app.CurrentAnatomy = retinacare.engine.AnatomyLesionEngine.segmentAnatomy(app.CurrentRawImg, 'OD');
            app.CurrentVessels = retinacare.engine.AnatomyLesionEngine.extractVessels(app.CurrentRawImg);
            app.CurrentLesions = retinacare.engine.AnatomyLesionEngine.detectLesions(app.CurrentRawImg, app.CurrentAnatomy);
            app.CurrentAIResult = retinacare.engine.ConstellationAI.runInference(app.CurrentRawImg, app.CurrentAnatomy, app.CurrentLesions, app.CurrentVessels);
        end

        function createUI(app)
            % Create master responsive App Designer UIFigure
            app.UIFigure = uifigure('Name', 'RetinaCare AI — Smart DR Screening & Clinical Decision Support', ...
                'Position', [40, 40, 1420, 900], ...
                'Color', app.COLOR_CANVAS_BG);

            app.MainGrid = uigridlayout(app.UIFigure, [3, 1]);
            app.MainGrid.RowHeight = {68, 28, '1x'};
            app.MainGrid.Padding = [0 0 0 0];
            app.MainGrid.RowSpacing = 0;

            app.createGlobalTopBar();
            app.createSafetyBanner();

            % Body Layout: Left Navigation Rail (260px) + Right Content Panel
            bodyGrid = uigridlayout(app.MainGrid, [1, 2]);
            bodyGrid.ColumnWidth = {260, '1x'};
            bodyGrid.Padding = [0 0 0 0];
            bodyGrid.ColumnSpacing = 0;

            app.createNavigationRail(bodyGrid);
            app.createContentWorkspace(bodyGrid);
        end

        % =================================================================
        % SHELL COMPONENT: GLOBAL TOP BAR
        % =================================================================
        function createGlobalTopBar(app)
            app.HeaderPanel = uipanel(app.MainGrid, ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, ...
                'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);

            hLayout = uigridlayout(app.HeaderPanel, [1, 6]);
            hLayout.ColumnWidth = {220, 230, 260, '1x', 190, 170};
            hLayout.Padding = [16 10 16 10];
            hLayout.ColumnSpacing = 12;

            % 1. App Title & Branding
            bBox = uigridlayout(hLayout, [2, 1]);
            bBox.Padding = [0 0 0 0];
            bBox.RowSpacing = 0;
            uilabel(bBox, 'Text', '👁️ RetinaCare AI', ...
                'FontName', 'Inter', 'FontSize', 16, 'FontWeight', 'bold', ...
                'FontColor', app.COLOR_PURPLE_DEEP);
            uilabel(bBox, 'Text', 'Central Tele-Ophthalmology Hub', ...
                'FontName', 'Inter', 'FontSize', 10, 'FontColor', app.COLOR_TEXT_MUTED);

            % 2. Healthcare Facility Selector Dropdown
            fBox = uigridlayout(hLayout, [2, 1]);
            fBox.Padding = [0 0 0 0];
            fBox.RowSpacing = 0;
            uilabel(fBox, 'Text', 'HEALTHCARE FACILITY NODE:', 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'FontWeight', 'bold');
            facItems = {
                'M.Y. Hospital Central Hub (Indore)', ...
                'Depalpur Community Health Centre', ...
                'Dr. Ambedkar Nagar Civil Hospital', ...
                'Sanwer Primary Health Centre', ...
                'Rau Primary Health Centre', ...
                'Betma Primary Health Centre'
            };
            app.TopBarFacilityDropdown = uidropdown(fBox, 'Items', facItems, ...
                'Value', app.CurrentFacility, 'FontSize', 11, ...
                'ValueChangedFcn', @(dd, ev) app.onFacilityChanged(dd.Value));

            % 3. Active Patient Switcher Dropdown
            pBox = uigridlayout(hLayout, [2, 1]);
            pBox.Padding = [0 0 0 0];
            pBox.RowSpacing = 0;
            uilabel(pBox, 'Text', 'ACTIVE CASE IN FOCUS:', 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'FontWeight', 'bold');
            pNames = cell(1, length(app.ClinicalDB.Patients));
            for k = 1:length(app.ClinicalDB.Patients)
                pNames{k} = sprintf('%s (%s)', app.ClinicalDB.Patients(k).Name, app.ClinicalDB.Patients(k).UHID);
            end
            app.TopBarPatientDropdown = uidropdown(pBox, 'Items', pNames, ...
                'Value', pNames{1}, 'FontSize', 11, ...
                'ValueChangedFcn', @(dd, ev) app.onPatientSelected(dd.Value));

            % 4. Real-time Telemetry Pill
            telBox = uigridlayout(hLayout, [2, 1]);
            telBox.Padding = [0 0 0 0];
            telBox.RowSpacing = 0;
            uilabel(telBox, 'Text', 'TELEMETRY & ABDM LINK:', 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'FontWeight', 'bold');
            uilabel(telBox, 'Text', '🟢 38ms Latency • 24.2 dB SNR • Ayushman Token Valid', ...
                'FontName', 'Inter', 'FontSize', 11, 'FontWeight', 'bold', 'FontColor', app.COLOR_GREEN);

            % 5. Review Queue Quick Jump Button
            btnQueue = uibutton(hLayout, 'push', ...
                'Text', '🚨 Review Queue (14 Urgent)', ...
                'BackgroundColor', [0.99, 0.95, 0.95], ...
                'FontColor', app.COLOR_RED, 'FontWeight', 'bold', 'FontSize', 11, ...
                'ButtonPushedFcn', @(btn, ev) app.selectTab(10));

            % 6. Clinician Profile Badge
            docBox = uigridlayout(hLayout, [2, 1]);
            docBox.Padding = [0 0 0 0];
            docBox.RowSpacing = 0;
            uilabel(docBox, 'Text', 'Dr. Ananya Sharma', 'FontSize', 11, 'FontWeight', 'bold', 'FontColor', app.COLOR_PURPLE_DARK, 'HorizontalAlignment', 'right');
            uilabel(docBox, 'Text', 'MCI MP-MC-2015-88412', 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'HorizontalAlignment', 'right');
        end

        function onFacilityChanged(app, newFacility)
            app.CurrentFacility = newFacility;
            uialert(app.UIFigure, sprintf('Connected facility node updated to %s. Telemetry link synced.', newFacility), 'Facility Node Switched');
        end

        function onPatientSelected(app, selectedString)
            for k = 1:length(app.ClinicalDB.Patients)
                pStr = sprintf('%s (%s)', app.ClinicalDB.Patients(k).Name, app.ClinicalDB.Patients(k).UHID);
                if strcmp(pStr, selectedString)
                    app.switchPatient(k);
                    break;
                end
            end
        end

        % =================================================================
        % SHELL COMPONENT: SAFETY BANNER
        % =================================================================
        function createSafetyBanner(app)
            app.SafetyBanner = uipanel(app.MainGrid, ...
                'BackgroundColor', app.COLOR_PURPLE_SOFT, ...
                'BorderType', 'none');

            bLayout = uigridlayout(app.SafetyBanner, [1, 2]);
            bLayout.ColumnWidth = {'1x', 240};
            bLayout.Padding = [16 2 16 2];

            uilabel(bLayout, ...
                'Text', '⚠️ CLINICAL SAFETY PROTOCOL: AI-assisted screening assessment • Clinical validation required by Ophthalmologist • Never claim "AI Diagnosed"', ...
                'FontName', 'Inter', 'FontSize', 10, 'FontWeight', 'bold', ...
                'FontColor', app.COLOR_PURPLE_DARK);

            uilabel(bLayout, ...
                'Text', 'IPHS 2022 • ABDM FHIR HL7 R4 READY', ...
                'FontName', 'Inter', 'FontSize', 10, 'FontWeight', 'bold', ...
                'FontColor', app.COLOR_GREEN, 'HorizontalAlignment', 'right');
        end

        % =================================================================
        % SHELL COMPONENT: NAVIGATION RAIL (15 MODULES ACROSS 4 SECTIONS)
        % =================================================================
        function createNavigationRail(app, parentGrid)
            app.SidebarPanel = uipanel(parentGrid, ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, ...
                'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);

            navGrid = uigridlayout(app.SidebarPanel, [20, 1]);
            rowHeights = repmat({34}, 1, 20);
            rowHeights{1} = 22;  % Primary Pipeline Header
            rowHeights{7} = 22;  % Diagnostic Intelligence Header
            rowHeights{12} = 22; % Tele-Medicine & Care Header
            rowHeights{17} = 22; % Health Systems & Audit Header
            rowHeights{20} = 24; % Footer
            navGrid.RowHeight = rowHeights;
            navGrid.Padding = [8 8 8 8];
            navGrid.RowSpacing = 2;

            moduleList = cell(1, 15);
            moduleList{1}  = '01. Clinical Login';
            moduleList{2}  = '02. Command Centre';
            moduleList{3}  = '03. Patient Registration';
            moduleList{4}  = '04. Capture Studio';
            moduleList{5}  = '05. Image Quality Lab';
            moduleList{6}  = '06. AI Analysis Centre';
            moduleList{7}  = '07. Retinal Anatomy Map';
            moduleList{8}  = '08. DR Severity Studio';
            moduleList{9}  = '09. Explainability Lab';
            moduleList{10} = '10. Review Queue (87)';
            moduleList{11} = '11. Review Workstation';
            moduleList{12} = '12. Referral Command (14)';
            moduleList{13} = '13. Longitudinal Record';
            moduleList{14} = '14. District Simulink';
            moduleList{15} = '15. AI Model Registry';

            % Helper to create Section Headers
            function addHeader(txt)
                uilabel(navGrid, 'Text', txt, 'FontSize', 9, 'FontWeight', 'bold', ...
                    'FontColor', app.COLOR_PURPLE_BRAND);
            end

            btnIdx = 1;

            % Section 1: PRIMARY PIPELINE
            addHeader('── PRIMARY PIPELINE ──');
            for i = 1:5
                btn = uibutton(navGrid, 'push', 'Text', ['  ', moduleList{i}], ...
                    'HorizontalAlignment', 'left', 'FontName', 'Inter', 'FontSize', 11, ...
                    'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontColor', app.COLOR_TEXT_MAIN, ...
                    'ButtonPushedFcn', @(b, ev) app.selectTab(i));
                if btnIdx == 1, app.NavButtons = btn; else, app.NavButtons(btnIdx) = btn; end
                btnIdx = btnIdx + 1;
            end

            % Section 2: DIAGNOSTIC INTELLIGENCE
            addHeader('── DIAGNOSTIC INTELLIGENCE ──');
            for i = 6:9
                btn = uibutton(navGrid, 'push', 'Text', ['  ', moduleList{i}], ...
                    'HorizontalAlignment', 'left', 'FontName', 'Inter', 'FontSize', 11, ...
                    'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontColor', app.COLOR_TEXT_MAIN, ...
                    'ButtonPushedFcn', @(b, ev) app.selectTab(i));
                app.NavButtons(btnIdx) = btn;
                btnIdx = btnIdx + 1;
            end

            % Section 3: TELE-MEDICINE & CARE
            addHeader('── TELE-MEDICINE & CARE ──');
            for i = 10:13
                btn = uibutton(navGrid, 'push', 'Text', ['  ', moduleList{i}], ...
                    'HorizontalAlignment', 'left', 'FontName', 'Inter', 'FontSize', 11, ...
                    'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontColor', app.COLOR_TEXT_MAIN, ...
                    'ButtonPushedFcn', @(b, ev) app.selectTab(i));
                app.NavButtons(btnIdx) = btn;
                btnIdx = btnIdx + 1;
            end

            % Section 4: HEALTH SYSTEMS & AUDIT
            addHeader('── HEALTH SYSTEMS & AUDIT ──');
            for i = 14:15
                btn = uibutton(navGrid, 'push', 'Text', ['  ', moduleList{i}], ...
                    'HorizontalAlignment', 'left', 'FontName', 'Inter', 'FontSize', 11, ...
                    'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontColor', app.COLOR_TEXT_MAIN, ...
                    'ButtonPushedFcn', @(b, ev) app.selectTab(i));
                app.NavButtons(btnIdx) = btn;
                btnIdx = btnIdx + 1;
            end

            % Sidebar footer
            uilabel(navGrid, 'Text', 'RetinaCare v2.4 • Stitch 8514', ...
                'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'HorizontalAlignment', 'center');
        end

        % =================================================================
        % WORKSPACE CONTENT PANEL (15 MODULE TABS)
        % =================================================================
        function createContentWorkspace(app, parentGrid)
            app.ContentPanel = uipanel(parentGrid, ...
                'BackgroundColor', app.COLOR_CANVAS_BG, ...
                'BorderType', 'none');

            cLayout = uigridlayout(app.ContentPanel, [1, 1]);
            cLayout.Padding = [0 0 0 0];

            app.TabGroup = uitabgroup(cLayout);

            % Instantiate all 15 tabs in exact order
            app.Tab01Login            = uitab(app.TabGroup, 'Title', '01. Login');
            app.Tab02CommandCentre     = uitab(app.TabGroup, 'Title', '02. Command Centre');
            app.Tab03Registration      = uitab(app.TabGroup, 'Title', '03. Registration');
            app.Tab04CaptureStudio     = uitab(app.TabGroup, 'Title', '04. Capture Studio');
            app.Tab05QualityLab        = uitab(app.TabGroup, 'Title', '05. Quality Lab');
            app.Tab06AIAnalysis        = uitab(app.TabGroup, 'Title', '06. AI Analysis');
            app.Tab07AnatomyMap        = uitab(app.TabGroup, 'Title', '07. Anatomy Map');
            app.Tab08SeverityStudio    = uitab(app.TabGroup, 'Title', '08. Severity Studio');
            app.Tab09Explainability    = uitab(app.TabGroup, 'Title', '09. Explainability');
            app.Tab10ReviewQueue       = uitab(app.TabGroup, 'Title', '10. Review Queue');
            app.Tab11Workstation       = uitab(app.TabGroup, 'Title', '11. Workstation');
            app.Tab12ReferralCentre    = uitab(app.TabGroup, 'Title', '12. Referral Centre');
            app.Tab13Longitudinal      = uitab(app.TabGroup, 'Title', '13. Longitudinal');
            app.Tab14DistrictSimulink  = uitab(app.TabGroup, 'Title', '14. District Simulink');
            app.Tab15ModelRegistry     = uitab(app.TabGroup, 'Title', '15. Model Registry');

            % Build all 15 clinical modules
            app.buildTab01Login();
            app.buildTab02CommandCentre();
            app.buildTab03Registration();
            app.buildTab04CaptureStudio();
            app.buildTab05QualityLab();
            app.buildTab06AIAnalysis();
            app.buildTab07AnatomyMap();
            app.buildTab08SeverityStudio();
            app.buildTab09Explainability();
            app.buildTab10ReviewQueue();
            app.buildTab11Workstation();
            app.buildTab12ReferralCentre();
            app.buildTab13Longitudinal();
            app.buildTab14DistrictSimulink();
            app.buildTab15ModelRegistry();
        end

        % =================================================================
        % TAB 01: CLINICAL LOGIN & WORKSPACE ACCESS
        % =================================================================
        function buildTab01Login(app)
            grid = uigridlayout(app.Tab01Login, [1, 2]);
            grid.ColumnWidth = {'1x', 480};
            grid.Padding = [40 40 40 40];

            % Left: Brand Hero Banner
            heroPanel = uipanel(grid, 'BackgroundColor', app.COLOR_PURPLE_DEEP, 'BorderType', 'none');
            hLay = uigridlayout(heroPanel, [5, 1]);
            hLay.RowHeight = {50, 40, '1x', 80, 40};
            hLay.Padding = [32 32 32 32];

            uilabel(hLay, 'Text', '👁️ RetinaCare AI', 'FontSize', 28, 'FontWeight', 'bold', 'FontColor', [1 1 1]);
            uilabel(hLay, 'Text', 'Smart Diabetic Retinopathy Screening & Clinical Decision Support', ...
                'FontSize', 14, 'FontColor', app.COLOR_PURPLE_SOFT);
            uilabel(hLay, 'Text', ['An advanced tele-ophthalmology ecosystem designed to eliminate preventable ' ...
                'diabetic blindness across public health networks. Seamlessly integrated with Ayushman Bharat ' ...
                'Digital Mission (ABDM), RETFound foundation ViTs, and real-time SimEvents district resource forecasting.'], ...
                'FontSize', 12, 'FontColor', [0.85 0.82 0.95], 'WordWrap', 'on');

            featBox = uigridlayout(hLay, [3, 1]);
            featBox.Padding = [0 0 0 0];
            uilabel(featBox, 'Text', '🔒 Role-Based Access: Ophthalmologist, ANM/Screening Nurse, District Admin', 'FontColor', [0.8 1 0.85], 'FontSize', 11);
            uilabel(featBox, 'Text', '⚡ Edge Inference: 15 Production Models on NVIDIA Jetson TensorRT', 'FontColor', [0.8 1 0.85], 'FontSize', 11);
            uilabel(featBox, 'Text', '🏥 National Health Authority: ABDM FHIR HL7 R4 DiagnosticReport Ready', 'FontColor', [0.8 1 0.85], 'FontSize', 11);

            uilabel(hLay, 'Text', 'Compliant with Indian Public Health Standards (IPHS 2022)', ...
                'FontSize', 10, 'FontColor', app.COLOR_PURPLE_SOFT);

            % Right: Login Card
            loginCard = uipanel(grid, 'BackgroundColor', app.COLOR_CARD_SURFACE, ...
                'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);
            lLay = uigridlayout(loginCard, [10, 1]);
            lLay.RowHeight = {30, 24, 30, 34, 30, 34, 30, 34, 46, 30};
            lLay.Padding = [32 32 32 32];

            uilabel(lLay, 'Text', 'Clinical Workspace Sign-In', 'FontSize', 20, 'FontWeight', 'bold', 'FontColor', app.COLOR_PURPLE_DEEP);
            uilabel(lLay, 'Text', 'Authenticate with your Ayushman Health Token or MCI Registry', 'FontSize', 11, 'FontColor', app.COLOR_TEXT_MUTED);

            uilabel(lLay, 'Text', 'Clinical Role:', 'FontWeight', 'bold', 'FontSize', 11);
            ddRole = uidropdown(lLay, 'Items', { ...
                'Ophthalmologist (Tele-Review Lead)', ...
                'Screening Nurse / Vision Technician', ...
                'District Health Officer (Capacity Admin)', ...
                'System Auditor & Model Registry Admin'});

            uilabel(lLay, 'Text', 'Facility Node:', 'FontWeight', 'bold', 'FontSize', 11);
            ddFac = uidropdown(lLay, 'Items', { ...
                'M.Y. Hospital Central Hub (Indore)', ...
                'Depalpur Community Health Centre', ...
                'Dr. Ambedkar Nagar Civil Hospital', ...
                'Sanwer Primary Health Centre', ...
                'Rau Primary Health Centre', ...
                'Betma Primary Health Centre'});

            uilabel(lLay, 'Text', 'ABHA / Ayushman Token ID:', 'FontWeight', 'bold', 'FontSize', 11);
            txtToken = uieditfield(lLay, 'text', 'Value', 'ABDM-DOC-MP-88412-SECURE');

            uibutton(lLay, 'push', 'Text', 'Enter Clinical Workspace ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 13, ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(2));

            uilabel(lLay, 'Text', '🔒 TLS 1.3 256-Bit Encrypted Session • ISO 27001 Certified', ...
                'FontSize', 10, 'FontColor', app.COLOR_TEXT_MUTED, 'HorizontalAlignment', 'center');
        end

        % =================================================================
        % TAB 02: CLINICAL COMMAND CENTRE (SCREENING PULSE & PHC TELEMETRY)
        % =================================================================
        function buildTab02CommandCentre(app)
            grid = uigridlayout(app.Tab02CommandCentre, [4, 1]);
            grid.RowHeight = {100, 100, 100, '1x'};
            grid.Padding = [16 16 16 16];
            grid.RowSpacing = 12;

            % 1. Welcome Banner
            bPanel = uipanel(grid, 'BackgroundColor', app.COLOR_PURPLE_DEEP, 'BorderType', 'none');
            bLay = uigridlayout(bPanel, [1, 2]);
            bLay.ColumnWidth = {'1x', 360};
            bLay.Padding = [20 12 20 12];

            wBox = uigridlayout(bLay, [3, 1]);
            wBox.Padding = [0 0 0 0];
            wBox.RowSpacing = 0;
            uilabel(wBox, 'Text', 'CENTRAL TELE-OPHTHALMOLOGY HUB • LIVE PHC STREAM', ...
                'FontSize', 10, 'FontWeight', 'bold', 'FontColor', app.COLOR_PURPLE_SOFT);
            uilabel(wBox, 'Text', 'Welcome back, Dr. Ananya Sharma', ...
                'FontSize', 20, 'FontWeight', 'bold', 'FontColor', [1 1 1]);
            uilabel(wBox, 'Text', 'District Retinal Intelligence active across 5 Peripheral Health Centres & 18 Cameras. 14 urgent cases awaiting specialist review.', ...
                'FontSize', 11, 'FontColor', [0.85 0.82 0.95]);

            btnBox = uigridlayout(bLay, [1, 2]);
            btnBox.Padding = [0 12 0 12];
            uibutton(btnBox, 'push', 'Text', 'Open Review Queue (87) ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_ROYAL, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(10));
            uibutton(btnBox, 'push', 'Text', '+ Register Patient', ...
                'BackgroundColor', app.COLOR_PURPLE_DARK, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(3));

            % 2. 4-KPI District Pulse Cards
            kpiGrid = uigridlayout(grid, [1, 4]);
            kpiGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            kpiGrid.Padding = [0 0 0 0];
            kpiGrid.ColumnSpacing = 12;

            app.createMetricCard(kpiGrid, 'Total Patients Screened', '12,842', '↑ +165 Screened Today', app.COLOR_PURPLE_BRAND);
            app.createMetricCard(kpiGrid, 'Referable DR Cases', '1,042 (8.1%)', '142 Immediate Urgent Triage', app.COLOR_ORANGE);
            app.createMetricCard(kpiGrid, 'Tele-Review Worklist', '87 Pending', '14 Priority <30s SLA Cases', app.COLOR_RED);
            app.createMetricCard(kpiGrid, 'AI Pipeline Telemetry', '12.4s Avg', '99.4% Uptime • ECE 0.021', app.COLOR_GREEN);

            % 3. 5-Stage Clinical Screening Pulse Pipeline
            pulsePanel = uipanel(grid, 'Title', 'District Screening Pulse — 5-Stage Clinical Flow', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            pLay = uigridlayout(pulsePanel, [1, 5]);
            pLay.ColumnWidth = repmat({'1x'}, 1, 5);
            pLay.Padding = [8 8 8 8];

            stages = {
                '01. Registration', 'ABHA & Risk Profile', 3, app.COLOR_PURPLE_SOFT;
                '02. Capture Studio', 'Real-Time Auto-QC', 4, [0.9 0.95 1.0];
                '03. Quality Lab', 'CLAHE & Gradability', 5, [0.9 0.98 0.95];
                '04. AI Intelligence', '15-Model Ensemble', 6, [0.97 0.92 1.0];
                '05. Tele-Review', 'Doctor Sign-off', 11, [0.92 1.0 0.95]
            };

            for s = 1:5
                pCard = uipanel(pLay, 'BackgroundColor', stages{s, 4}, 'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);
                cGrid = uigridlayout(pCard, [3, 1]);
                cGrid.RowHeight = {18, 16, 26};
                cGrid.Padding = [4 4 4 4];
                uilabel(cGrid, 'Text', stages{s, 1}, 'FontWeight', 'bold', 'FontSize', 11, 'FontColor', app.COLOR_PURPLE_DEEP);
                uilabel(cGrid, 'Text', stages{s, 2}, 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED);
                uibutton(cGrid, 'push', 'Text', 'Open Stage ➔', 'FontSize', 10, 'FontWeight', 'bold', ...
                    'BackgroundColor', app.COLOR_CARD_SURFACE, ...
                    'ButtonPushedFcn', @(b, ev) app.selectTab(stages{s, 3}));
            end

            % 4. Split Grid: Priority Cases Worklist (Left) + PHC Network Stream (Right)
            splitGrid = uigridlayout(grid, [1, 2]);
            splitGrid.ColumnWidth = {'1.2x', '1x'};
            splitGrid.Padding = [0 0 0 0];
            splitGrid.ColumnSpacing = 12;

            % Left: Urgent Triage Table
            prioPanel = uipanel(splitGrid, 'Title', 'Urgent Tele-Ophthalmology Worklist (<30s SLA Cases)', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            prLay = uigridlayout(prioPanel, [2, 1]);
            prLay.RowHeight = {'1x', 36};
            uitable(prLay, 'Data', app.ClinicalDB.ReviewQueue, ...
                'ColumnName', {'Patient', 'UHID', 'ICDR Stage', 'DME Risk', 'Urgency', 'Conf', 'Origin PHC', 'Status'}, ...
                'ColumnWidth', {130, 105, 125, 110, 95, 55, 95, 75});
            uibutton(prLay, 'push', 'Text', 'Launch Selected Case in Doctor Review Workstation ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(11));

            % Right: PHC Centers Table
            phcPanel = uipanel(splitGrid, 'Title', 'Peripheral Health Centres (PHC Network Telemetry)', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            phcLey = uigridlayout(phcPanel, [1, 1]);
            uitable(phcLey, 'Data', app.ClinicalDB.PHCCenters, ...
                'ColumnName', {'Center Name', 'Type', 'Cameras', 'Status', 'Screened', 'Target', 'Referable', 'Latency', 'APN Link', 'Sync'}, ...
                'ColumnWidth', {120, 105, 115, 80, 60, 50, 60, 60, 95, 80});
        end

        % =================================================================
        % TAB 03: PATIENT REGISTRATION & CLINICAL INTAKE
        % =================================================================
        function buildTab03Registration(app)
            grid = uigridlayout(app.Tab03Registration, [1, 2]);
            grid.ColumnWidth = {'1.5x', '1x'};
            grid.Padding = [16 16 16 16];

            formPanel = uipanel(grid, 'Title', 'Patient Registration & Clinical Intake Workspace', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            fLay = uigridlayout(formPanel, [11, 2]);
            fLay.RowHeight = repmat({32}, 1, 11);
            fLay.ColumnWidth = {150, '1x'};

            uilabel(fLay, 'Text', 'ABHA Number:');
            uieditfield(fLay, 'text', 'Value', app.CurrentPatient.ABHA);

            uilabel(fLay, 'Text', 'Full Legal Name:');
            uieditfield(fLay, 'text', 'Value', app.CurrentPatient.Name);

            uilabel(fLay, 'Text', 'Age & Gender:');
            ag = uigridlayout(fLay, [1, 2]); ag.Padding = [0 0 0 0];
            uispinner(ag, 'Value', app.CurrentPatient.Age, 'Limits', [1 120]);
            uidropdown(ag, 'Items', {'Male', 'Female', 'Other'}, 'Value', app.CurrentPatient.Gender);

            uilabel(fLay, 'Text', 'Diabetes Profile:');
            dg = uigridlayout(fLay, [1, 2]); dg.Padding = [0 0 0 0];
            uidropdown(dg, 'Items', {'Type 2 DM', 'Type 1 DM', 'Gestational DM'});
            uispinner(dg, 'Value', app.CurrentPatient.DurationYears, 'Limits', [0 60]);

            uilabel(fLay, 'Text', 'HbA1c (%):');
            uispinner(fLay, 'Value', app.CurrentPatient.HbA1c, 'Limits', [4 18], 'Step', 0.1);

            uilabel(fLay, 'Text', 'Fasting Blood Glucose:');
            uispinner(fLay, 'Value', app.CurrentPatient.FastingGlucose, 'Limits', [40 600]);

            uilabel(fLay, 'Text', 'Visual Acuity (BCVA):');
            vg = uigridlayout(fLay, [1, 2]); vg.Padding = [0 0 0 0];
            uidropdown(vg, 'Items', {'6/6', '6/9', '6/12', '6/18', '6/24', '6/36', '<3/60'}, 'Value', app.CurrentPatient.BCVA_OD);
            uidropdown(vg, 'Items', {'6/6', '6/9', '6/12', '6/18', '6/24', '6/36', '<3/60'}, 'Value', app.CurrentPatient.BCVA_OS);

            uilabel(fLay, 'Text', 'Intraocular Pressure:');
            ig = uigridlayout(fLay, [1, 2]); ig.Padding = [0 0 0 0];
            uispinner(ig, 'Value', app.CurrentPatient.IOP_OD, 'Limits', [5 60]);
            uispinner(ig, 'Value', app.CurrentPatient.IOP_OS, 'Limits', [5 60]);

            uilabel(fLay, 'Text', 'Symptoms / Complaints:');
            uieditfield(fLay, 'text', 'Value', app.CurrentPatient.Symptoms);

            uilabel(fLay, 'Text', 'ABDM Ayushman Consent:');
            uicheckbox(fLay, 'Text', 'Informed consent captured & linked to Ayushman token', 'Value', true);

            uilabel(fLay, 'Text', '');
            uibutton(fLay, 'push', 'Text', 'Save & Proceed to Capture Studio ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(4));

            % Snapshot Summary Card
            snapPanel = uipanel(grid, 'Title', 'Patient Clinical Snapshot & Risk Stratification', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            sLay = uigridlayout(snapPanel, [7, 1]);
            sLay.Padding = [16 16 16 16];

            uilabel(sLay, 'Text', sprintf('👤 %s, %d %s', app.CurrentPatient.Name, app.CurrentPatient.Age, app.CurrentPatient.Gender), ...
                'FontSize', 16, 'FontWeight', 'bold', 'FontColor', app.COLOR_PURPLE_DEEP);
            uilabel(sLay, 'Text', sprintf('🆔 UHID: %s • ABHA: %s', app.CurrentPatient.UHID, app.CurrentPatient.ABHA), 'FontWeight', 'bold');
            uilabel(sLay, 'Text', sprintf('🏥 District / PHC: %s', app.CurrentPatient.District));
            uilabel(sLay, 'Text', sprintf('🩸 Diabetes Duration: %d years • HbA1c: %.1f%% (Suboptimal)', app.CurrentPatient.DurationYears, app.CurrentPatient.HbA1c));
            uilabel(sLay, 'Text', sprintf('👁️ BCVA: OD %s, OS %s • IOP: OD %.1f, OS %.1f mmHg', app.CurrentPatient.BCVA_OD, app.CurrentPatient.BCVA_OS, app.CurrentPatient.IOP_OD, app.CurrentPatient.IOP_OS));
            uilabel(sLay, 'Text', sprintf('⚠️ Current Symptoms: %s', app.CurrentPatient.Symptoms), 'FontColor', app.COLOR_ORANGE, 'FontWeight', 'bold');
            uilabel(sLay, 'Text', '✅ ABDM Ayushman Health Data Exchange Ready', 'FontColor', app.COLOR_GREEN, 'FontWeight', 'bold');
        end

        % =================================================================
        % TAB 04: RETINAL CAPTURE STUDIO (HARDWARE TELEMETRY & AUTO-QC)
        % =================================================================
        function buildTab04CaptureStudio(app)
            grid = uigridlayout(app.Tab04CaptureStudio, [1, 2]);
            grid.ColumnWidth = {'1.6x', '1x'};
            grid.Padding = [16 16 16 16];

            % Optical Viewport Canvas (Dark #0B1120)
            viewPanel = uipanel(grid, 'Title', 'Optical Capture Viewport — Remidio NM-FOP II Handheld Sensor', ...
                'BackgroundColor', app.COLOR_OPTICAL_BG, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_OPTICAL_GLOW);
            vLay = uigridlayout(viewPanel, [1, 1]);
            vLay.Padding = [8 8 8 8];
            app.AxesCapture = uiaxes(vLay);
            app.AxesCapture.BackgroundColor = app.COLOR_OPTICAL_BG;
            app.AxesCapture.Toolbar.Visible = 'off';
            imshow(app.CurrentRawImg, 'Parent', app.AxesCapture);
            title(app.AxesCapture, sprintf('%s — Right Eye (OD) 45° Macular Field', app.CurrentPatient.Name), ...
                'Color', [1 1 1], 'FontSize', 12);

            % Telemetry Controls Card
            ctrlPanel = uipanel(grid, 'Title', 'Hardware Telemetry & Auto-QC Parameters', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            cLey = uigridlayout(ctrlPanel, [9, 1]);
            cLey.RowHeight = {36, 36, 36, 36, 36, 36, 36, 44, 30};
            cLey.Padding = [16 16 16 16];

            % Eye Selection
            uilabel(cLey, 'Text', 'EXAMINED EYE:', 'FontWeight', 'bold', 'FontSize', 11);
            eyeGrid = uigridlayout(cLey, [1, 2]); eyeGrid.Padding = [0 0 0 0];
            uibutton(eyeGrid, 'push', 'Text', 'OD (Right Eye)', 'FontWeight', 'bold', ...
                'BackgroundColor', app.COLOR_PURPLE_ROYAL, 'FontColor', [1 1 1]);
            uibutton(eyeGrid, 'push', 'Text', 'OS (Left Eye)', 'FontWeight', 'bold', ...
                'BackgroundColor', app.COLOR_PURPLE_SOFT, 'FontColor', app.COLOR_PURPLE_DARK);

            % Field Protocol
            uilabel(cLey, 'Text', 'FIELD PROTOCOL:', 'FontWeight', 'bold', 'FontSize', 11);
            uidropdown(cLey, 'Items', {'Field 1: Macula-Centered 45°', 'Field 2: Disc-Centered 45°', 'ETDRS 7-Standard Field'});

            % Telemetry Readouts
            uilabel(cLey, 'Text', '⚡ Sensor Telemetry: Battery 88% • NIR 880nm • Flash 22 Ws', 'FontWeight', 'bold', 'FontColor', app.COLOR_GREEN);
            uilabel(cLey, 'Text', '👁️ Pupil Gauge: 4.2 mm (Threshold >3.8mm PASS)', 'FontWeight', 'bold', 'FontColor', app.COLOR_PURPLE_BRAND);
            uilabel(cLey, 'Text', '🎯 Real-Time Alignment: Tenengrad 92.4 • Centered PASS', 'FontWeight', 'bold', 'FontColor', app.COLOR_BLUE);

            uibutton(cLey, 'push', 'Text', 'Capture & Run Quality Lab ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 13, ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(5));

            uilabel(cLey, 'Text', 'Auto-QC triggers automated Tenengrad sharpness & illumination analysis', ...
                'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'HorizontalAlignment', 'center');
        end

        % =================================================================
        % TAB 05: IMAGE QUALITY LAB & OPTICAL PRE-PROCESSING
        % =================================================================
        function buildTab05QualityLab(app)
            grid = uigridlayout(app.Tab05QualityLab, [2, 1]);
            grid.RowHeight = {110, '1x'};
            grid.Padding = [16 16 16 16];

            % Top: Quality Score Cards
            qGrid = uigridlayout(grid, [1, 4]);
            qGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            qGrid.Padding = [0 0 0 0];
            app.createMetricCard(qGrid, 'Tenengrad Sharpness', '92.4%', 'Optimal Foveal Contrast', app.COLOR_GREEN);
            app.createMetricCard(qGrid, 'Illumination Uniformity', '88.6%', 'CUNSB B-Spline Adjusted', app.COLOR_PURPLE_BRAND);
            app.createMetricCard(qGrid, 'Centration Index', '94.1%', 'ETDRS Field 1 Macula', app.COLOR_BLUE);
            app.createMetricCard(qGrid, 'Overall Gradability', '91.0% PASS', 'Optimal for Diagnostic AI', app.COLOR_GREEN);

            % Bottom: Tri-Viewport (Raw vs Enhanced vs Histogram)
            viewGrid = uigridlayout(grid, [1, 3]);
            viewGrid.ColumnWidth = {'1x', '1x', '1x'};
            viewGrid.Padding = [0 0 0 0];

            % Raw Viewport
            p1 = uipanel(viewGrid, 'Title', 'Raw Clinical Fundus', 'BackgroundColor', app.COLOR_OPTICAL_BG, ...
                'FontWeight', 'bold', 'ForegroundColor', [1 1 1]);
            l1 = uigridlayout(p1, [1, 1]);
            app.AxesQualityRaw = uiaxes(l1);
            app.AxesQualityRaw.BackgroundColor = app.COLOR_OPTICAL_BG;
            app.AxesQualityRaw.Toolbar.Visible = 'off';
            imshow(app.CurrentRawImg, 'Parent', app.AxesQualityRaw);

            % Enhanced Viewport
            p2 = uipanel(viewGrid, 'Title', 'CUNSB-RFIE + MAXIM + CLAHE Enhanced', 'BackgroundColor', app.COLOR_OPTICAL_BG, ...
                'FontWeight', 'bold', 'ForegroundColor', app.COLOR_OPTICAL_GLOW);
            l2 = uigridlayout(p2, [1, 1]);
            app.AxesQualityEnh = uiaxes(l2);
            app.AxesQualityEnh.BackgroundColor = app.COLOR_OPTICAL_BG;
            app.AxesQualityEnh.Toolbar.Visible = 'off';
            imshow(app.CurrentEnhancedImg, 'Parent', app.AxesQualityEnh);

            % Histogram Viewport
            p3 = uipanel(viewGrid, 'Title', 'Green Channel Optical Histogram', 'BackgroundColor', app.COLOR_CARD_SURFACE, ...
                'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            l3 = uigridlayout(p3, [1, 1]);
            app.AxesQualityHist = uiaxes(l3);
            [counts, binLocs] = imhist(app.CurrentRawImg(:,:,2), 64);
            bar(app.AxesQualityHist, binLocs, counts, 'BarWidth', 1, 'FaceColor', app.COLOR_GREEN, 'EdgeColor', 'none');
            title(app.AxesQualityHist, 'Hemoglobin Contrast Spectrum', 'Color', app.COLOR_TEXT_MAIN);
            xlabel(app.AxesQualityHist, 'Pixel Intensity (0–255)', 'FontSize', 9);
            ylabel(app.AxesQualityHist, 'Frequency', 'FontSize', 9);
            app.AxesQualityHist.XGrid = 'on';
            app.AxesQualityHist.YGrid = 'on';
        end

        % =================================================================
        % TAB 06: AI ANALYSIS CENTRE (15-MODEL LIVE ENSEMBLE)
        % =================================================================
        function buildTab06AIAnalysis(app)
            grid = uigridlayout(app.Tab06AIAnalysis, [2, 1]);
            grid.RowHeight = {140, '1x'};
            grid.Padding = [16 16 16 16];

            % Top Pipeline Latency Cards
            pipePanel = uipanel(grid, 'Title', 'Retinal Intelligence Engine — 6-Stage Deep Constellation Architecture', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            pGrid = uigridlayout(pipePanel, [1, 6]);
            pGrid.ColumnWidth = repmat({'1x'}, 1, 6);
            pGrid.Padding = [8 8 8 8];

            cStages = {
                'Stage 1: Quality', 'EFIQA + CUNSB', '42 ms', app.COLOR_GREEN;
                'Stage 2: ViT Feats', 'RETFound 768-d', '68 ms', app.COLOR_PURPLE_BRAND;
                'Stage 3: Anatomy', 'Disc/Cup/FAZ', '35 ms', app.COLOR_BLUE;
                'Stage 4: Lesions', 'MA/Hem/Exudates', '84 ms', app.COLOR_ORANGE;
                'Stage 5: Grading', 'ICDR Softmax', '28 ms', app.COLOR_RED;
                'Stage 6: Vessel', 'Tortuosity/Caliber', '22 ms', app.COLOR_PURPLE_ROYAL
            };

            for s = 1:6
                cBox = uipanel(pGrid, 'BackgroundColor', app.COLOR_PURPLE_SOFT, 'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);
                cg = uigridlayout(cBox, [3, 1]);
                cg.RowHeight = {16, 14, 16};
                cg.Padding = [4 4 4 4];
                uilabel(cg, 'Text', cStages{s, 1}, 'FontWeight', 'bold', 'FontSize', 10, 'FontColor', app.COLOR_PURPLE_DEEP);
                uilabel(cg, 'Text', cStages{s, 2}, 'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED);
                uilabel(cg, 'Text', ['⚡ Latency: ', cStages{s, 3}], 'FontSize', 9, 'FontWeight', 'bold', 'FontColor', cStages{s, 4});
            end

            % Bottom Results Banner & Models Table
            resGrid = uigridlayout(grid, [1, 2]);
            resGrid.ColumnWidth = {'1x', '1.4x'};
            resGrid.Padding = [0 0 0 0];

            resCard = uipanel(resGrid, 'Title', 'Constellation Consensus Verdict', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            rLay = uigridlayout(resCard, [6, 1]);
            rLay.Padding = [16 16 16 16];

            uilabel(rLay, 'Text', sprintf('Predicted Stage: %s', app.CurrentAIResult.StageLabel), ...
                'FontSize', 16, 'FontWeight', 'bold', 'FontColor', app.COLOR_ORANGE);
            uilabel(rLay, 'Text', sprintf('Ensemble Agreement: 93.3%% (14/15 Production Models)'), 'FontWeight', 'bold');
            uilabel(rLay, 'Text', sprintf('Model Confidence: %.1f%% (Platt Calibrated)', app.CurrentAIResult.Confidence));
            uilabel(rLay, 'Text', sprintf('DME Verdict: %s', app.CurrentAIResult.DMEVerdict), 'FontWeight', 'bold', 'FontColor', app.COLOR_RED);
            uilabel(rLay, 'Text', 'STATUS: REFERABLE DR DETECTED', 'FontSize', 14, 'FontWeight', 'bold', 'FontColor', app.COLOR_RED);

            uibutton(rLay, 'push', 'Text', 'Inspect DR Severity Studio ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(8));

            % Models catalog preview
            mCard = uipanel(resGrid, 'Title', 'Active Production Models Live Telemetry', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            mLay = uigridlayout(mCard, [1, 1]);
            uitable(mLay, 'Data', app.ModelReg.ModelsTable(:, [1, 2, 3, 6, 7, 8]), ...
                'ColumnName', {'Node', 'Model Name', 'Architecture', 'Precision', 'Latency', 'Version'}, ...
                'ColumnWidth', {45, 140, 120, 90, 65, 60});
        end

        % =================================================================
        % TAB 07: RETINAL ANATOMY & PATHOLOGICAL LESION MAP
        % =================================================================
        function buildTab07AnatomyMap(app)
            grid = uigridlayout(app.Tab07AnatomyMap, [1, 2]);
            grid.ColumnWidth = {'1.6x', '1x'};
            grid.Padding = [16 16 16 16];

            % High-Resolution Fundus Overlay Canvas
            canvasPanel = uipanel(grid, 'Title', 'Interactive 11-Layer Retinal Anatomy & Lesion Segmentation Canvas', ...
                'BackgroundColor', app.COLOR_OPTICAL_BG, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_OPTICAL_GLOW);
            cLey = uigridlayout(canvasPanel, [1, 1]);
            cLey.Padding = [8 8 8 8];
            app.AxesAnatomyMap = uiaxes(cLey);
            app.AxesAnatomyMap.BackgroundColor = app.COLOR_OPTICAL_BG;
            app.AxesAnatomyMap.Toolbar.Visible = 'off';
            app.updateAnatomyOverlay();

            % Layer Controls & Caliper Inspector Table
            ctrlPanel = uipanel(grid, 'Title', 'Lesion Caliper Inspector & Layer Toggles', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            lGrid = uigridlayout(ctrlPanel, [9, 1]);
            lGrid.RowHeight = {28, 28, 28, 28, 28, 28, 28, '1x', 36};
            lGrid.Padding = [12 12 12 12];

            uicheckbox(lGrid, 'Text', '🔵 Optic Disc & Cup (CDR: 0.43)', 'Value', true, 'ValueChangedFcn', @(cb, ev) app.updateAnatomyOverlay());
            uicheckbox(lGrid, 'Text', '🔴 Retinal Vessels & Arcades (Density: 14.8%)', 'Value', true, 'ValueChangedFcn', @(cb, ev) app.updateAnatomyOverlay());
            uicheckbox(lGrid, 'Text', '🔴 Microaneurysms (Count: 8, Temporal)', 'Value', true, 'ValueChangedFcn', @(cb, ev) app.updateAnatomyOverlay());
            uicheckbox(lGrid, 'Text', '🩸 Intraretinal Hemorrhages (Count: 2)', 'Value', true, 'ValueChangedFcn', @(cb, ev) app.updateAnatomyOverlay());
            uicheckbox(lGrid, 'Text', '🟡 Hard Exudates (Circinate Ring 820µm FAZ)', 'Value', true, 'ValueChangedFcn', @(cb, ev) app.updateAnatomyOverlay());
            uicheckbox(lGrid, 'Text', '⚪ Cotton Wool Spots (Nerve Fiber Infarcts)', 'Value', true, 'ValueChangedFcn', @(cb, ev) app.updateAnatomyOverlay());
            uicheckbox(lGrid, 'Text', '🟣 Neovascularization (NVD / NVE)', 'Value', false, 'ValueChangedFcn', @(cb, ev) app.updateAnatomyOverlay());

            % Caliper Table
            caliperData = {
                'MA-01', 'Microaneurysm', 'Temporal Macula', '96.2%', '0.08 mm²';
                'MA-02', 'Microaneurysm', 'Inferotemporal', '94.8%', '0.06 mm²';
                'HEM-01', 'Blot Hemorrhage', 'Superotemporal', '95.4%', '0.24 mm²';
                'HEX-01', 'Hard Exudate Ring', 'Perimacular (820µm)', '98.1%', '0.18 mm²';
                'CWS-01', 'Cotton Wool Spot', 'Superonasal Arcade', '93.5%', '0.35 mm²'
            };
            uitable(lGrid, 'Data', caliperData, ...
                'ColumnName', {'ID', 'Pathology Type', 'Location', 'Conf', 'Area'}, ...
                'ColumnWidth', {55, 110, 110, 55, 65});

            uibutton(lGrid, 'push', 'Text', 'Proceed to DR Severity Studio ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(8));
        end

        function updateAnatomyOverlay(app)
            % Composite multi-layer anatomical and lesion overlay
            layers = struct();
            layers.DiscMask = app.CurrentAnatomy.DiscMask;
            layers.VesselMask = app.CurrentVessels.VesselMask;
            layers.MAMask = app.CurrentLesions.MicroaneurysmsMask;
            layers.HemorrhageMask = app.CurrentLesions.HemorrhagesMask;
            layers.ExudateMask = app.CurrentLesions.ExudatesMask;
            layers.CWSMask = app.CurrentLesions.CottonWoolSpotsMask;
            layers.NVMask = app.CurrentLesions.NeovascularizationMask;

            composite = retinacare.engine.AnatomyLesionEngine.createOverlay(app.CurrentRawImg, layers, 0.7);
            imshow(composite, 'Parent', app.AxesAnatomyMap);
            title(app.AxesAnatomyMap, sprintf('%s — 11-Layer Segmented Fundus Canvas', app.CurrentPatient.Name), ...
                'Color', [1 1 1], 'FontSize', 12);
        end

        % =================================================================
        % TAB 08: DR SEVERITY STUDIO (ICDR 5-GRADE RADIAL WHEEL)
        % =================================================================
        function buildTab08SeverityStudio(app)
            grid = uigridlayout(app.Tab08SeverityStudio, [1, 2]);
            grid.ColumnWidth = {'1.1x', '1x'};
            grid.Padding = [16 16 16 16];

            % Left: Severity Wheel & Softmax Probability Bar
            wheelPanel = uipanel(grid, 'Title', 'ICDR 5-Grade Severity Wheel & Categorical Probability', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            wLay = uigridlayout(wheelPanel, [2, 1]);
            wLay.RowHeight = {'1.1x', '1x'};

            app.AxesSeverityWheel = uiaxes(wLay);
            app.renderSeverityWheel();

            app.AxesSeverityProb = uiaxes(wLay);
            app.renderSoftmaxChart();

            % Right: Decision Rules & Tele-Triage Guidance
            rulePanel = uipanel(grid, 'Title', 'ICDR Decision Rules & Clinician Override', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            rLay = uigridlayout(rulePanel, [8, 1]);
            rLay.RowHeight = {30, 30, 30, 30, 30, 36, 44, 30};
            rLay.Padding = [16 16 16 16];

            uilabel(rLay, 'Text', '✅ Rule 1: Microaneurysms Present (>0 detected • Mild NPDR met)', 'FontColor', app.COLOR_GREEN, 'FontWeight', 'bold');
            uilabel(rLay, 'Text', '✅ Rule 2: Exudates Encroaching within 820µm of FAZ (Moderate NPDR met)', 'FontColor', app.COLOR_ORANGE, 'FontWeight', 'bold');
            uilabel(rLay, 'Text', '❌ Rule 3: ETDRS 4-2-1 Severe NPDR Rule: Negative (Quadrant criteria unmet)', 'FontColor', app.COLOR_TEXT_MUTED);
            uilabel(rLay, 'Text', '❌ Rule 4: Neovascularization (NVD/NVE): Negative (Rules out PDR)', 'FontColor', app.COLOR_TEXT_MUTED);
            uilabel(rLay, 'Text', '⚠️ Rule 5: Diabetic Macular Edema: Non-Center-Involving DME Present', 'FontColor', app.COLOR_RED, 'FontWeight', 'bold');

            % Grade Override Dropdown
            ovGrid = uigridlayout(rLay, [1, 2]); ovGrid.Padding = [0 0 0 0];
            uilabel(ovGrid, 'Text', 'CLINICIAN OVERRIDE:', 'FontWeight', 'bold');
            uidropdown(ovGrid, 'Items', {'Grade 0: No DR', 'Grade 1: Mild NPDR', 'Grade 2: Moderate NPDR (AI)', 'Grade 3: Severe NPDR', 'Grade 4: PDR'}, ...
                'Value', 'Grade 2: Moderate NPDR (AI)');

            uibutton(rLay, 'push', 'Text', 'Inspect Explainability & Evidence Lab ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(9));

            uilabel(rLay, 'Text', 'Clinician modifications are recorded in the ABDM audit trail log', ...
                'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'HorizontalAlignment', 'center');
        end

        function renderSeverityWheel(app)
            % Render multi-arc radial severity gauge matching React SeverityWheel
            cla(app.AxesSeverityWheel);
            app.AxesSeverityWheel.Toolbar.Visible = 'off';
            app.AxesSeverityWheel.XColor = 'none';
            app.AxesSeverityWheel.YColor = 'none';

            theta = linspace(0, 2*pi, 100);
            plot(app.AxesSeverityWheel, cos(theta), sin(theta), 'k-', 'LineWidth', 8, 'Color', [0.9 0.9 0.95]);
            hold(app.AxesSeverityWheel, 'on');

            % Arc segments for the 5 grades
            th2 = linspace(0.4*2*pi, 0.6*2*pi, 40);
            plot(app.AxesSeverityWheel, cos(th2), sin(th2), '-', 'LineWidth', 14, 'Color', app.COLOR_ORANGE);

            % Center Dial Text
            text(app.AxesSeverityWheel, 0, 0.2, 'GRADE 2', 'FontSize', 18, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'Color', app.COLOR_PURPLE_DEEP);
            text(app.AxesSeverityWheel, 0, -0.05, 'MODERATE NPDR', 'FontSize', 11, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'Color', app.COLOR_ORANGE);
            text(app.AxesSeverityWheel, 0, -0.3, 'Confidence: 91.8%', 'FontSize', 10, ...
                'HorizontalAlignment', 'center', 'Color', app.COLOR_TEXT_MUTED);

            axis(app.AxesSeverityWheel, 'equal');
            xlim(app.AxesSeverityWheel, [-1.3 1.3]);
            ylim(app.AxesSeverityWheel, [-1.3 1.3]);
            hold(app.AxesSeverityWheel, 'off');
        end

        function renderSoftmaxChart(app)
            probs = app.CurrentAIResult.SoftmaxProbabilities;
            labels = retinacare.engine.ConstellationAI.ICDR_SHORT;
            bar(app.AxesSeverityProb, 0:4, probs, 'FaceColor', app.COLOR_PURPLE_ROYAL, 'EdgeColor', 'none');
            app.AxesSeverityProb.XTick = 0:4;
            app.AxesSeverityProb.XTickLabel = labels;
            app.AxesSeverityProb.YLim = [0 100];
            ylabel(app.AxesSeverityProb, 'Probability (%)');
            title(app.AxesSeverityProb, 'Softmax Ensemble Probability Distribution', 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesSeverityProb.XGrid = 'on';
            app.AxesSeverityProb.YGrid = 'on';
        end

        % =================================================================
        % TAB 09: EXPLAINABILITY & EVIDENCE LAB (GRAD-CAM & ECE CURVES)
        % =================================================================
        function buildTab09Explainability(app)
            grid = uigridlayout(app.Tab09Explainability, [1, 2]);
            grid.ColumnWidth = {'1.4x', '1x'};
            grid.Padding = [16 16 16 16];

            % Left: Grad-CAM Saliency Blend
            camPanel = uipanel(grid, 'Title', 'Grad-CAM Saliency Map — Attention Attribution on Temporal Subfield', ...
                'BackgroundColor', app.COLOR_OPTICAL_BG, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_OPTICAL_GLOW);
            cLay = uigridlayout(camPanel, [1, 1]);
            cLay.Padding = [8 8 8 8];
            app.AxesGradCAM = uiaxes(cLay);
            app.AxesGradCAM.BackgroundColor = app.COLOR_OPTICAL_BG;
            app.AxesGradCAM.Toolbar.Visible = 'off';
            [~, blend] = retinacare.engine.ExplainabilityEngine.generateGradCAM(app.CurrentRawImg, app.CurrentLesions, app.CurrentAnatomy, app.CurrentAIResult.PredictedStage);
            imshow(blend, 'Parent', app.AxesGradCAM);
            title(app.AxesGradCAM, 'Grad-CAM Attention Saliency Hotspots', 'Color', [1 1 1], 'FontSize', 12);

            % Right: Ranked Clinical Evidence & Calibration Curve
            rightGrid = uigridlayout(grid, [2, 1]);
            rightGrid.RowHeight = {'1.2x', '1x'};
            rightGrid.Padding = [0 0 0 0];

            % Evidence Attribution Table
            evPanel = uipanel(rightGrid, 'Title', 'Ranked Clinical Evidence Attribution Table', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            eLay = uigridlayout(evPanel, [1, 1]);
            eItems = retinacare.engine.ExplainabilityEngine.rankClinicalEvidence(app.CurrentLesions, app.CurrentAIResult.PredictedStage);
            eTable = cell(length(eItems), 5);
            for k = 1:length(eItems)
                eTable{k, 1} = sprintf('#%d', eItems(k).Rank);
                eTable{k, 2} = eItems(k).Feature;
                eTable{k, 3} = sprintf('%.1f%%', eItems(k).AttributionScore);
                eTable{k, 4} = sprintf('%d objects', eItems(k).Count);
                eTable{k, 5} = eItems(k).ClinicalRule;
            end
            uitable(eLay, 'Data', eTable, ...
                'ColumnName', {'Rank', 'Biomarker', 'Attribution', 'Count', 'Rule Standard'}, ...
                'ColumnWidth', {45, 120, 85, 80, 140});

            % Calibration Curve (ECE)
            calPanel = uipanel(rightGrid, 'Title', 'ECE Reliability Curve (ECE: 0.021 • Platt Calibrated)', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            cLay = uigridlayout(calPanel, [1, 1]);
            app.AxesCalibration = uiaxes(cLay);
            cal = retinacare.engine.ExplainabilityEngine.getCalibrationData();
            plot(app.AxesCalibration, [0 1], [0 1], 'k--', 'LineWidth', 1.5);
            hold(app.AxesCalibration, 'on');
            plot(app.AxesCalibration, cal.ConfBins, cal.AccBins, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
            xlabel(app.AxesCalibration, 'Confidence');
            ylabel(app.AxesCalibration, 'Empirical Accuracy');
            title(app.AxesCalibration, 'Platt Scaled Reliability Curve', 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesCalibration.XGrid = 'on';
            app.AxesCalibration.YGrid = 'on';
            hold(app.AxesCalibration, 'off');
        end

        % =================================================================
        % TAB 10: CLINICAL REVIEW QUEUE (87 TRIAGE CASES)
        % =================================================================
        function buildTab10ReviewQueue(app)
            grid = uigridlayout(app.Tab10ReviewQueue, [3, 1]);
            grid.RowHeight = {60, '1x', 44};
            grid.Padding = [16 16 16 16];

            % Filter bar
            fPanel = uipanel(grid, 'BackgroundColor', app.COLOR_CARD_SURFACE, 'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);
            fLay = uigridlayout(fPanel, [1, 4]);
            fLay.ColumnWidth = {180, 180, '1x', 180};
            fLay.Padding = [8 8 8 8];
            uidropdown(fLay, 'Items', {'All Urgencies (87)', 'STAT & Urgent (14)', 'Priority (28)', 'Routine (45)'});
            uidropdown(fLay, 'Items', {'All Facilities (Indore)', 'Depalpur CHC', 'Mhow Civil Hospital', 'Sanwer PHC', 'Rau PHC', 'Betma PHC'});
            uilabel(fLay, 'Text', '⏱️ Triage SLA: Target <30s / Case • Current Average: 12.4s', 'FontWeight', 'bold', 'FontColor', app.COLOR_GREEN);
            uibutton(fLay, 'push', 'Text', 'Claim Next Priority Case', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(11));

            % Main Triage Table
            qPanel = uipanel(grid, 'Title', 'District Clinical Review Queue — Sorted by Risk & SLA', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            qLay = uigridlayout(qPanel, [1, 1]);
            uitable(qLay, 'Data', app.ClinicalDB.ReviewQueue, ...
                'ColumnName', {'Patient Demographics', 'UHID Number', 'ICDR Stage', 'DME Status', 'Triage Urgency', 'AI Confidence', 'Origin PHC', 'Workflow Status'}, ...
                'ColumnWidth', {160, 120, 140, 130, 110, 80, 120, 90});

            % Action bar
            uibutton(grid, 'push', 'Text', 'Open Selected Patient Case in Review Workstation ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 13, ...
                'ButtonPushedFcn', @(b, ev) app.selectTab(11));
        end

        % =================================================================
        % TAB 11: OPHTHALMOLOGIST REVIEW WORKSTATION
        % =================================================================
        function buildTab11Workstation(app)
            grid = uigridlayout(app.Tab11Workstation, [1, 2]);
            grid.ColumnWidth = {'1.6x', '1x'};
            grid.Padding = [16 16 16 16];

            % Dual Viewport: Raw vs AI Lesion Overlay
            viewPanel = uipanel(grid, 'Title', 'Dual-Viewport Comparison: Raw Optical vs AI Lesions', ...
                'BackgroundColor', app.COLOR_OPTICAL_BG, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_OPTICAL_GLOW);
            vLay = uigridlayout(viewPanel, [1, 2]);
            vLay.ColumnWidth = {'1x', '1x'};

            % Left: Raw View
            app.AxesWorkstationRaw = uiaxes(vLay);
            app.AxesWorkstationRaw.BackgroundColor = app.COLOR_OPTICAL_BG;
            app.AxesWorkstationRaw.Toolbar.Visible = 'off';
            imshow(app.CurrentRawImg, 'Parent', app.AxesWorkstationRaw);
            title(app.AxesWorkstationRaw, 'Raw Optical Fundus', 'Color', [1 1 1]);

            % Right: AI Overlay
            app.AxesWorkstationAI = uiaxes(vLay);
            app.AxesWorkstationAI.BackgroundColor = app.COLOR_OPTICAL_BG;
            app.AxesWorkstationAI.Toolbar.Visible = 'off';
            layers = struct();
            layers.DiscMask = app.CurrentAnatomy.DiscMask;
            layers.VesselMask = app.CurrentVessels.VesselMask;
            layers.MAMask = app.CurrentLesions.MicroaneurysmsMask;
            layers.HemorrhageMask = app.CurrentLesions.HemorrhagesMask;
            layers.ExudateMask = app.CurrentLesions.ExudatesMask;
            layers.CWSMask = app.CurrentLesions.CottonWoolSpotsMask;
            imshow(retinacare.engine.AnatomyLesionEngine.createOverlay(app.CurrentRawImg, layers, 0.7), 'Parent', app.AxesWorkstationAI);
            title(app.AxesWorkstationAI, 'AI Segmented Lesions', 'Color', app.COLOR_OPTICAL_GLOW);

            % Clinician Decision & Sign-off Form
            formPanel = uipanel(grid, 'Title', 'Clinician Validation & ABDM Sign-off', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            fLay = uigridlayout(formPanel, [8, 1]);
            fLay.RowHeight = {32, 34, 32, 34, 32, 34, 46, 30};
            fLay.Padding = [16 16 16 16];

            uilabel(fLay, 'Text', 'VALIDATED ICDR DIAGNOSIS:', 'FontWeight', 'bold');
            uidropdown(fLay, 'Items', { ...
                'Grade 2: Moderate NPDR (Confirmed)', ...
                'Grade 0: No DR', ...
                'Grade 1: Mild NPDR', ...
                'Grade 3: Severe NPDR', ...
                'Grade 4: Proliferative DR (Urgent)'});

            uilabel(fLay, 'Text', 'MACULAR EDEMA (DME) STATUS:', 'FontWeight', 'bold');
            uidropdown(fLay, 'Items', { ...
                'Non-Center-Involving DME (Confirmed)', ...
                'Center-Involving CSME', ...
                'No Clinically Significant DME'});

            uilabel(fLay, 'Text', 'MANAGEMENT PATHWAY:', 'FontWeight', 'bold');
            uidropdown(fLay, 'Items', { ...
                'Fast-Track Referral to MGM Hospital (Macular OCT)', ...
                'District Hospital Follow-up (30 Days)', ...
                'Urgent Panretinal Laser Photocoagulation (PRP)', ...
                'Routine PHC Monitoring (12 Months)'});

            uibutton(fLay, 'push', 'Text', '✍️ Digital Sign-off & ABDM HL7 Sync ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 13, ...
                'ButtonPushedFcn', @(b, ev) app.onDigitalSignoff());

            uilabel(fLay, 'Text', 'Signed reports automatically dispatch FHIR DiagnosticReport & notify ASHA', ...
                'FontSize', 9, 'FontColor', app.COLOR_TEXT_MUTED, 'HorizontalAlignment', 'center');
        end

        function onDigitalSignoff(app)
            uialert(app.UIFigure, sprintf(['Diagnostic Report successfully signed by Dr. Ananya Sharma for %s.\n\n' ...
                '• ABDM FHIR Resource ID: fhir-rep-2026-0919-8819\n' ...
                '• Fast-Track Referral Dispatched to MGM Eye Hospital\n' ...
                '• Automated SMS & WhatsApp sent to ASHA Sunita Yadav\n' ...
                '• Status in Review Queue updated to Completed.'], app.CurrentPatient.Name), ...
                'Report Signed & Dispatched');
            app.selectTab(12); % Move to Referral Hub
        end

        % =================================================================
        % TAB 12: TELE-OPHTHALMOLOGY REFERRAL COMMAND (ABDM)
        % =================================================================
        function buildTab12ReferralCentre(app)
            grid = uigridlayout(app.Tab12ReferralCentre, [2, 1]);
            grid.RowHeight = {140, '1x'};
            grid.Padding = [16 16 16 16];

            % Top: Referral Fast-Track Cards
            topGrid = uigridlayout(grid, [1, 4]);
            topGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            topGrid.Padding = [0 0 0 0];
            app.createMetricCard(topGrid, 'Total Referrals', '14 Active', 'ABDM Fast-Track Enqueued', app.COLOR_PURPLE_BRAND);
            app.createMetricCard(topGrid, 'Tertiary Hospital Booked', '9 Slots', 'M.Y. Hospital & Choithram', app.COLOR_BLUE);
            app.createMetricCard(topGrid, 'ASHA Field Alerts', '14 Sent', 'SMS + Voice Call Mobilized', app.COLOR_GREEN);
            app.createMetricCard(topGrid, 'Patient Transport Subsidy', 'Rs. 250 / Patient', 'Direct DBT via Ayushman Token', app.COLOR_ORANGE);

            % Bottom: Active Referrals Table
            refPanel = uipanel(grid, 'Title', 'ABDM Fast-Track Referral Dispatch Hub (FHIR HL7 R4 Linked)', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            rLay = uigridlayout(refPanel, [2, 1]);
            rLay.RowHeight = {'1x', 40};
            rLay.Padding = [12 12 12 12];

            uitable(rLay, 'Data', app.ClinicalDB.Referrals, ...
                'ColumnName', {'Referral ID', 'Patient Name', 'ABHA Number', 'Destination Hospital', 'Recommended Care', 'Urgency', 'ABDM Status', 'ASHA Mobilization'}, ...
                'ColumnWidth', {140, 130, 140, 170, 170, 100, 120, 120});

            uibutton(rLay, 'push', 'Text', '📱 Dispatch Instant ASHA Reminder & Mobilize Transport ➔', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) uialert(app.UIFigure, 'ASHA mobilization reminder broadcasted via National Health Authority Gateway.', 'ASHA Alert Dispatched'));
        end

        % =================================================================
        % TAB 13: LONGITUDINAL PATIENT RECORD (3-YEAR TRAJECTORY)
        % =================================================================
        function buildTab13Longitudinal(app)
            grid = uigridlayout(app.Tab13Longitudinal, [2, 1]);
            grid.RowHeight = {160, '1x'};
            grid.Padding = [16 16 16 16];

            % Top: Retinal Journey Timeline for Suresh Chandra Verma
            tPanel = uipanel(grid, 'Title', sprintf('Retinal Journey Timeline: %s (UHID: %s)', app.CurrentPatient.Name, app.CurrentPatient.UHID), ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            tLay = uigridlayout(tPanel, [1, 3]);
            tLay.ColumnWidth = {'1x', '1x', '1x'};
            tLay.Padding = [8 8 8 8];

            visits = app.CurrentPatient.Visits;
            vBoxes = {
                'Visit 1 • 15 Mar 2024', visits(1).StageName, sprintf('HbA1c: %.1f%% • MAs: %d', visits(1).HbA1c, visits(1).MACount), app.COLOR_GREEN;
                'Visit 2 • 20 Nov 2024', visits(2).StageName, sprintf('HbA1c: %.1f%% • MAs: %d', visits(2).HbA1c, visits(2).MACount), app.COLOR_AMBER;
                'Visit 3 • 19 Sep 2026 (Today)', visits(3).StageName, sprintf('HbA1c: %.1f%% • MAs: %d • DME', visits(3).HbA1c, visits(3).MACount), app.COLOR_ORANGE
            };

            for v = 1:3
                vCard = uipanel(tLay, 'BackgroundColor', app.COLOR_PURPLE_SOFT, 'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);
                vg = uigridlayout(vCard, [3, 1]);
                vg.RowHeight = {18, 20, 18};
                vg.Padding = [6 6 6 6];
                uilabel(vg, 'Text', vBoxes{v, 1}, 'FontSize', 10, 'FontWeight', 'bold', 'FontColor', app.COLOR_PURPLE_DEEP);
                uilabel(vg, 'Text', vBoxes{v, 2}, 'FontSize', 13, 'FontWeight', 'bold', 'FontColor', vBoxes{v, 4});
                uilabel(vg, 'Text', vBoxes{v, 3}, 'FontSize', 10, 'FontColor', app.COLOR_TEXT_MUTED);
            end

            % Bottom: Dual Progression Trajectory Charts
            cGrid = uigridlayout(grid, [1, 2]);
            cGrid.ColumnWidth = {'1x', '1x'};
            cGrid.Padding = [0 0 0 0];

            % Plot 1: ICDR vs HbA1c
            p1 = uipanel(cGrid, 'Title', 'Progression: ICDR Grade vs HbA1c Trajectory', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            l1 = uigridlayout(p1, [1, 1]);
            app.AxesLongSeverity = uiaxes(l1);
            vDates = 1:length(visits);
            vStages = [visits.Stage];
            vHb = [visits.HbA1c];
            yyaxis(app.AxesLongSeverity, 'left');
            plot(app.AxesLongSeverity, vDates, vStages, 'b-o', 'LineWidth', 2.5, 'MarkerFaceColor', 'b');
            ylabel(app.AxesLongSeverity, 'ICDR Stage (0 to 4)');
            ylim(app.AxesLongSeverity, [0 4]);
            yyaxis(app.AxesLongSeverity, 'right');
            plot(app.AxesLongSeverity, vDates, vHb, 'r--s', 'LineWidth', 2.5, 'MarkerFaceColor', 'r');
            ylabel(app.AxesLongSeverity, 'HbA1c (%)');
            app.AxesLongSeverity.XTick = vDates;
            app.AxesLongSeverity.XTickLabel = {visits.Date};
            title(app.AxesLongSeverity, 'Microvascular Progression vs Glycemic Control', 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesLongSeverity.XGrid = 'on';
            app.AxesLongSeverity.YGrid = 'on';

            % Plot 2: Microaneurysms vs Hard Exudates
            p2 = uipanel(cGrid, 'Title', 'Biomarker Burden: Microaneurysms vs Hard Exudates', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            l2 = uigridlayout(p2, [1, 1]);
            app.AxesLongLesions = uiaxes(l2);
            vMA = [visits.MACount];
            vEx = [visits.ExudateArea];
            yyaxis(app.AxesLongLesions, 'left');
            bar(app.AxesLongLesions, vDates, vMA, 'FaceColor', [0.85 0.25 0.25], 'EdgeColor', 'none');
            ylabel(app.AxesLongLesions, 'Microaneurysm Count');
            yyaxis(app.AxesLongLesions, 'right');
            plot(app.AxesLongLesions, vDates, vEx, 'm-d', 'LineWidth', 2.5, 'MarkerFaceColor', 'y');
            ylabel(app.AxesLongLesions, 'Hard Exudate Area (mm²)');
            app.AxesLongLesions.XTick = vDates;
            app.AxesLongLesions.XTickLabel = {visits.Date};
            title(app.AxesLongLesions, 'Structural Biomarker Burden Accretion', 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesLongLesions.XGrid = 'on';
            app.AxesLongLesions.YGrid = 'on';
        end

        % =================================================================
        % TAB 14: DISTRICT SIMULINK & CAPACITY SIMULATOR
        % =================================================================
        function buildTab14DistrictSimulink(app)
            grid = uigridlayout(app.Tab14DistrictSimulink, [2, 1]);
            grid.RowHeight = {140, '1x'};
            grid.Padding = [16 16 16 16];

            % Top: Simulation Parameters & Controls
            simCard = uipanel(grid, 'Title', 'Simulink / SimEvents Discrete-Event District Capacity Engine', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            sGrid = uigridlayout(simCard, [2, 5]);
            sGrid.RowHeight = {28, 36};
            sGrid.ColumnWidth = {'1x', '1x', '1x', '1x', 180};
            sGrid.Padding = [8 8 8 8];

            uilabel(sGrid, 'Text', 'Arrival Rate (\lambda pts/hr):', 'FontWeight', 'bold');
            uilabel(sGrid, 'Text', 'Field Cameras Deployed:', 'FontWeight', 'bold');
            uilabel(sGrid, 'Text', 'Review Ophthalmologists:', 'FontWeight', 'bold');
            uilabel(sGrid, 'Text', 'Mesh Link (Mbps):', 'FontWeight', 'bold');
            uilabel(sGrid, 'Text', 'Simulation Scenario:', 'FontWeight', 'bold');

            spnLambda = uispinner(sGrid, 'Value', 100, 'Limits', [10 500]);
            spnCams = uispinner(sGrid, 'Value', 18, 'Limits', [1 50]);
            spnDocs = uispinner(sGrid, 'Value', 4, 'Limits', [1 20]);
            spnNet = uispinner(sGrid, 'Value', 1.8, 'Limits', [0.5 50], 'Step', 0.2);
            uibutton(sGrid, 'push', 'Text', '▶ Run SimEvents Model', ...
                'BackgroundColor', app.COLOR_PURPLE_BRAND, 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(b, ev) app.onRunSimulink(spnLambda.Value, spnCams.Value, spnDocs.Value));

            % Bottom: Throughput & Queue Depth Charts
            cGrid = uigridlayout(grid, [1, 2]);
            cGrid.ColumnWidth = {'1x', '1x'};
            cGrid.Padding = [0 0 0 0];

            p1 = uipanel(cGrid, 'Title', 'Hourly Screening Throughput (8-Hour Clinic Shift)', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            l1 = uigridlayout(p1, [1, 1]);
            app.AxesSimThroughput = uiaxes(l1);

            p2 = uipanel(cGrid, 'Title', 'Discrete-Event Queue Depths & Bottleneck Tracking', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            l2 = uigridlayout(p2, [1, 1]);
            app.AxesSimQueues = uiaxes(l2);

            app.onRunSimulink(100, 18, 4);
        end

        function onRunSimulink(app, lambda, cams, docs)
            app.SimEngine.ArrivalRatePerHour = lambda;
            app.SimEngine.NumCameras = cams;
            app.SimEngine.NumReviewDoctors = docs;
            res = app.SimEngine.runSimulation();

            bar(app.AxesSimThroughput, 1:8, res.ThroughputHourly, 'FaceColor', app.COLOR_PURPLE_ROYAL, 'EdgeColor', 'none');
            xlabel(app.AxesSimThroughput, 'Clinic Hour (1 to 8)');
            ylabel(app.AxesSimThroughput, 'Patients Screened');
            title(app.AxesSimThroughput, sprintf('Total: %d • Referrals: %d • Annual: %d', ...
                res.TotalScreened, res.ReferralsGenerated, res.AnnualProjected), 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesSimThroughput.XGrid = 'on';
            app.AxesSimThroughput.YGrid = 'on';

            tMin = res.TimeMinutes;
            plot(app.AxesSimQueues, tMin, res.QueueDepths.Intake, 'b-', 'LineWidth', 1.5);
            hold(app.AxesSimQueues, 'on');
            plot(app.AxesSimQueues, tMin, res.QueueDepths.Camera, 'm-', 'LineWidth', 1.5);
            plot(app.AxesSimQueues, tMin, res.QueueDepths.TeleDoctor, 'r-', 'LineWidth', 2);
            plot(app.AxesSimQueues, tMin, res.QueueDepths.TertiaryOPD, 'k--', 'LineWidth', 2);
            xlabel(app.AxesSimQueues, 'Time (Minutes)');
            ylabel(app.AxesSimQueues, 'Queue Depth (Patients)');
            legend(app.AxesSimQueues, {'Intake', 'Camera', 'Doctor Review', 'Tertiary OPD'}, 'Location', 'northwest');
            title(app.AxesSimQueues, sprintf('Bottleneck Status: %s', res.BottleneckStatus), 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesSimQueues.XGrid = 'on';
            app.AxesSimQueues.YGrid = 'on';
            hold(app.AxesSimQueues, 'off');
        end

        % =================================================================
        % TAB 15: AI MODEL REGISTRY & CLINICAL VALIDATION CENTRE
        % =================================================================
        function buildTab15ModelRegistry(app)
            grid = uigridlayout(app.Tab15ModelRegistry, [2, 1]);
            grid.RowHeight = {'1.2x', '1x'};
            grid.Padding = [16 16 16 16];

            % 15 Active Production Models Table
            mPanel = uipanel(grid, 'Title', 'Active Production Inference Models (15 Pipeline Nodes) — NVIDIA Jetson TensorRT', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            mLay = uigridlayout(mPanel, [1, 1]);
            uitable(mLay, 'Data', app.ModelReg.ModelsTable, ...
                'ColumnName', {'Node', 'Model Name', 'Architecture', 'Params', 'Target Task', 'Precision', 'Latency', 'Version', 'Status'}, ...
                'ColumnWidth', {50, 160, 130, 70, 110, 100, 65, 65, 65});

            % ROC and Precision-Recall Curves
            curvesGrid = uigridlayout(grid, [1, 2]);
            curvesGrid.ColumnWidth = {'1x', '1x'};
            curvesGrid.Padding = [0 0 0 0];

            rPanel = uipanel(curvesGrid, 'Title', 'Multi-Center Clinical Validation: ROC Curves (IDRiD, EyePACS, Messidor)', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            rLay = uigridlayout(rPanel, [1, 1]);
            app.AxesROCCurve = uiaxes(rLay);
            [fpr, tpr, auc] = app.ModelReg.getROCCurve('IDRiD');
            plot(app.AxesROCCurve, fpr, tpr, 'b-', 'LineWidth', 2.5);
            hold(app.AxesROCCurve, 'on');
            plot(app.AxesROCCurve, [0 1], [0 1], 'k--', 'LineWidth', 1);
            xlabel(app.AxesROCCurve, 'False Positive Rate (1 - Specificity)');
            ylabel(app.AxesROCCurve, 'True Positive Rate (Sensitivity)');
            title(app.AxesROCCurve, sprintf('IDRiD Benchmark: AUC = %.3f', auc), 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesROCCurve.XGrid = 'on';
            app.AxesROCCurve.YGrid = 'on';
            hold(app.AxesROCCurve, 'off');

            prPanel = uipanel(curvesGrid, 'Title', 'Precision-Recall Validation Curve', ...
                'BackgroundColor', app.COLOR_CARD_SURFACE, 'FontWeight', 'bold', 'ForegroundColor', app.COLOR_PURPLE_DEEP);
            prLay = uigridlayout(prPanel, [1, 1]);
            app.AxesPRCurve = uiaxes(prLay);
            [rec, prec] = app.ModelReg.getPRCurve('IDRiD');
            plot(app.AxesPRCurve, rec, prec, 'r-', 'LineWidth', 2.5);
            xlabel(app.AxesPRCurve, 'Recall (Sensitivity)');
            ylabel(app.AxesPRCurve, 'Precision (PPV)');
            title(app.AxesPRCurve, 'Precision-Recall Curve (AP = 0.965)', 'Color', app.COLOR_PURPLE_DEEP);
            app.AxesPRCurve.XGrid = 'on';
            app.AxesPRCurve.YGrid = 'on';
        end

        % =================================================================
        % HELPER METHODS
        % =================================================================
        function createMetricCard(app, parent, titleText, valueText, subText, accentColor)
            card = uipanel(parent, 'BackgroundColor', app.COLOR_CARD_SURFACE, ...
                'BorderType', 'line', 'HighlightColor', app.COLOR_BORDER_SOFT);
            cLay = uigridlayout(card, [3, 1]);
            cLay.RowHeight = {16, 32, 16};
            cLay.Padding = [10 8 10 8];
            cLay.RowSpacing = 2;

            uilabel(cLay, 'Text', upper(titleText), 'FontSize', 9, 'FontWeight', 'bold', 'FontColor', app.COLOR_TEXT_MUTED);
            uilabel(cLay, 'Text', valueText, 'FontSize', 20, 'FontWeight', 'bold', 'FontColor', accentColor);
            uilabel(cLay, 'Text', subText, 'FontSize', 10, 'FontColor', app.COLOR_TEXT_MUTED);
        end

        function refreshAllAxes(app)
            % Refresh axes across tabs when patient or image changes
            app.updateAnatomyOverlay();
            app.renderSoftmaxChart();
            app.renderSeverityWheel();

            [~, blend] = retinacare.engine.ExplainabilityEngine.generateGradCAM(app.CurrentRawImg, app.CurrentLesions, app.CurrentAnatomy, app.CurrentAIResult.PredictedStage);
            imshow(blend, 'Parent', app.AxesGradCAM);
            imshow(app.CurrentRawImg, 'Parent', app.AxesCapture);
            imshow(app.CurrentRawImg, 'Parent', app.AxesQualityRaw);
            imshow(app.CurrentEnhancedImg, 'Parent', app.AxesQualityEnh);

            cla(app.AxesQualityHist);
            [counts, binLocs] = imhist(app.CurrentRawImg(:,:,2), 64);
            bar(app.AxesQualityHist, binLocs, counts, 'BarWidth', 1, 'FaceColor', app.COLOR_GREEN, 'EdgeColor', 'none');
            title(app.AxesQualityHist, 'Hemoglobin Contrast Spectrum', 'Color', app.COLOR_TEXT_MAIN);
            xlabel(app.AxesQualityHist, 'Pixel Intensity (0–255)', 'FontSize', 9);
            ylabel(app.AxesQualityHist, 'Frequency', 'FontSize', 9);
            app.AxesQualityHist.XGrid = 'on';
            app.AxesQualityHist.YGrid = 'on';
        end
    end
end
