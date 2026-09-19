# RetinaCare AI — Smart DR Screening & Clinical Decision Support (MATLAB App Designer)

An advanced MATLAB App Designer tele-ophthalmology clinical decision support application modeled faithfully after the [Stitch Project 8514012087795404150](https://stitch.withgoogle.com/projects/8514012087795404150).

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=coder1238/DR_Prj&file=run_retinacare.m)

---

## 🌟 Overview of Features

RetinaCare AI encapsulates **all 15 clinical screens and workflow modules** from the Stitch design specification:

1. **📊 Clinical Command Centre**: Executive triage dashboard, real-time KPI metrics, screening pulse pipeline, and district telemetry.
2. **👤 Patient Registration & Clinical Intake**: ABHA identity, metabolic profile (HbA1c, glucose), baseline ophthalmic parameters (BCVA, IOP), and ABDM consent.
3. **📷 Retinal Capture Studio**: Remidio NM-FOP / Topcon / Zeiss hardware telemetry, OD/OS eye toggles, multi-field selection (Macula 45°, Disc 45°, ETDRS 7-field).
4. **🔬 Image Quality Lab & Optical Pre-Processing**: Tenengrad sharpness, illumination uniformity, centration index, and multi-stage filtering (CUNSB-RFIE, MAXIM, CLAHE, Homomorphic).
5. **🧠 AI Constellation Command Centre**: 6-stage deep clinical inference pipeline (Quality $\rightarrow$ RETFound Foundation ViT $\rightarrow$ Anatomy $\rightarrow$ Lesions $\rightarrow$ ICDR/DME $\rightarrow$ Morphology).
6. **🗺️ Retinal Anatomy & Lesion Segmentation Map**: Interactive multi-layer fundus canvas with toggles for Optic Disc/Cup, Vessels, Microaneurysms, Hemorrhages, Hard Exudates, Cotton Wool Spots, and Neovascularization with opacity control.
7. **🎯 DR Severity Studio**: ICDR 5-class softmax probability distribution, radial severity gauge, DME risk grading, and clinical action protocol.
8. **🔍 Explainability & Evidence Lab**: Grad-CAM saliency heatmaps, ranked attributed clinical evidence table, and Platt-calibrated ECE reliability curves.
9. **📋 Clinical Review Queue & Triage**: Urgency-filtered patient worklist with $<30$s SLA tracking.
10. **🩺 Ophthalmologist Review Workstation**: Dual-viewport comparison (Raw vs AI Lesions), clinician validation form, management pathway selection, and digital sign-off.
11. **📈 Longitudinal Patient Record**: Retinal journey timeline, dual-axis progression trajectories (ICDR vs HbA1c, Microaneurysms vs Exudate area), and historical scan comparison.
12. **🏥 Tele-Ophthalmology Referral Command Centre**: ABDM Fast-Track dispatch, tertiary hospital slot allocation, and automated ASHA health worker mobilization.
13. **⚡ District Intelligence & Simulink Resource Lab**: Discrete-Event Capacity Simulator modeled after MATLAB Simulink / SimEvents queuing theory (Poisson arrivals, bottleneck detection, capacity forecasting).
14. **🤖 AI Model Registry & Clinical Validation Centre**: 15 active production models catalog, benchmark validation metrics across IDRiD, EyePACS, DeepDRiD, Messidor, and APTOS 2019 with interactive ROC and PR curves.
15. **🔐 Clinical Workspace Access & Security Login**: Role-based access, facility selector, and ABDM Ayushman token authentication.

---

## 🚀 Quick Start in MATLAB

### 1. Launch the Application
Open MATLAB, navigate to `/workspaces/DR_Prj/`, and in the MATLAB Command Window run:
```matlab
run_retinacare
```
Or open the application directly in **MATLAB App Designer**:
```matlab
appdesigner('RetinaCareApp.mlapp')
```
Or instantiate programmatically:
```matlab
app = RetinaCareApp();
```

### 2. Build / Refresh the .mlapp Package
To rebuild or update `RetinaCareApp.mlapp` after any code modifications:
- In MATLAB:
  ```matlab
  build_mlapp
  ```
- From terminal (Linux/macOS/Windows):
  ```bash
  python3 build_mlapp.py
  ```

### 3. Deploy to MATLAB Web App Server
To package and deploy the application for **MATLAB Web App Server**:
1. Run the deployment script in MATLAB:
   ```matlab
   deploy_web_app
   ```
   Or specify your custom server apps folder:
   ```matlab
   deploy_web_app('ServerAppsDir', '/usr/local/MATLAB/MATLAB_Web_App_Server/R2024b/apps')
   ```
2. The script compiles `RetinaCareApp.m` into `dist/RetinaCareApp.ctf` using MATLAB Compiler and places it in the Web App Server directory.
3. Access the application in any web browser at:
   `http://<server-host>:9988/webapps/home/` and launch **RetinaCareApp**.

### 4. Run Automated Verification Tests
To run the automated test suite testing all 11 application, algorithm, and `.mlapp` package modules:
```matlab
test_retinacare
```

---

## 📁 Repository Structure

```
/workspaces/DR_Prj/
├── RetinaCareApp.mlapp            % Standard MATLAB App Designer Package Archive
├── RetinaCareApp.m                % Master App Designer Class (All 15 Modules)
├── build_mlapp.m                  % MATLAB one-click .mlapp builder
├── build_mlapp.py                 % Standalone OPC-compliant .mlapp packager
├── run_retinacare.m               % One-click launcher script
├── test_retinacare.m              % Comprehensive 11-part test suite
├── deploy_web_app.m               % MATLAB Web App Server compiler script
├── RetinaCare_AI_Detailed_Analysis.md % Full architectural & clinical analysis
├── +retinacare/
│   ├── +engine/
│   │   ├── ImageProcessingLab.m   % CUNSB, MAXIM, CLAHE, Homomorphic, Sharpness
│   │   ├── AnatomyLesionEngine.m  % Disc/Cup, Vessels, MA, Hem, Exudates, Overlays
│   │   ├── ConstellationAI.m      % 6-Stage Constellation Inference & ICDR/DME
│   │   ├── ExplainabilityEngine.m % Grad-CAM, Attention, Evidence Ranking, ECE
│   │   └── SimulinkQueueEngine.m  % SimEvents Discrete-Event Healthcare Simulator
│   ├── +data/
│   │   ├── ClinicalDatabase.m     % Realistic patient cohorts & longitudinal visits
│   │   └── SyntheticRetina.m      % Pure-MATLAB clinical synthetic fundus generator
│   ├── +models/
│   │   └── ModelRegistry.m        % 15 Production models & benchmark ROC/PR curves
│   └── +referral/
│       └── ABDMGateway.m          % ABDM FHIR Resource generator & ASHA alerts
└── sample_data/                   % Generated clinical-grade PNG fundus images
    ├── stage_0_normal_OD.png
    ├── stage_1_mild_npdr_OD.png
    ├── stage_2_moderate_npdr_dme_OD.png
    ├── stage_3_severe_npdr_OD.png
    ├── stage_4_proliferative_dr_OD.png
    ├── patient_suresh_verma_baseline.png
    └── patient_suresh_verma_followup.png
```