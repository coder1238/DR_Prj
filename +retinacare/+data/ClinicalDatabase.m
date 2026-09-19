classdef ClinicalDatabase < handle
    % CLINICALDATABASE Clinical Cohort Registry, Longitudinal Records, & Worklists
    % Contains patient records, ABHA identities, metabolic profiles, and review queues.
    
    properties
        Patients
        ReviewQueue
        Referrals
    end
    
    methods
        function obj = ClinicalDatabase()
            obj.initDatabase();
        end
        
        function initDatabase(obj)
            % Initialize realistic patient cohort from Stitch project specs
            
            % 1. Suresh Chandra Verma (Key Longitudinal Case)
            p1 = struct();
            p1.UHID = 'MP-IND-2024-8819';
            p1.ABHA = '91-4829-1092-4411';
            p1.Name = 'Suresh Chandra Verma';
            p1.Age = 56;
            p1.Gender = 'Male';
            p1.Phone = '+91 98260 14820';
            p1.District = 'Indore (Sanwer CHC)';
            p1.DiabetesType = 'Type 2 DM';
            p1.DurationYears = 12;
            p1.HbA1c = 8.9;
            p1.FastingGlucose = 178;
            p1.Insulin = 'No (Metformin + Glimepiride)';
            p1.Hypertension = 'Yes (Amlodipine 5mg)';
            p1.Smoking = 'Former (quit 4 yrs ago)';
            p1.eGFR = 78;
            p1.BCVA_OD = '6/12';
            p1.BCVA_OS = '6/9';
            p1.IOP_OD = 16.5;
            p1.IOP_OS = 15.0;
            p1.CataractStatus = 'Mild Nuclear Sclerosis (Grade 1)';
            p1.Symptoms = 'Blurriness during reading, occasional floaters';
            p1.CurrentStage = 2; % Moderate NPDR
            p1.DME = 'Non-Center-Involving DME (>500um from FAZ)';
            p1.CurrentFundus = 'patient_suresh_verma_followup.png';
            
            % Longitudinal timeline for Suresh Chandra Verma
            p1.Visits = [
                struct('Date', '2024-03-15', 'Stage', 1, 'StageName', 'Mild NPDR', 'HbA1c', 8.2, 'MACount', 8, 'ExudateArea', 0.00, 'BCVA', '6/9', 'Action', 'Diet counseling, 6m follow-up'), ...
                struct('Date', '2024-11-20', 'Stage', 2, 'StageName', 'Moderate NPDR', 'HbA1c', 8.6, 'MACount', 19, 'ExudateArea', 0.08, 'BCVA', '6/12', 'Action', 'Metformin increased, tele-review'), ...
                struct('Date', '2026-09-19', 'Stage', 2, 'StageName', 'Moderate NPDR + DME', 'HbA1c', 8.9, 'MACount', 26, 'ExudateArea', 0.24, 'BCVA', '6/12', 'Action', 'ABDM Fast-Track to MGM Eye Hospital for Macular OCT')
            ];
            
            % 2. Ramesh Patel (Severe / PDR case)
            p2 = struct();
            p2.UHID = 'MP-IND-2024-5512';
            p2.ABHA = '91-3819-4402-9912';
            p2.Name = 'Ramesh Patel';
            p2.Age = 58;
            p2.Gender = 'Male';
            p2.Phone = '+91 94250 89102';
            p2.District = 'Dewas District Hospital';
            p2.DiabetesType = 'Type 2 DM';
            p2.DurationYears = 16;
            p2.HbA1c = 9.8;
            p2.FastingGlucose = 215;
            p2.Insulin = 'Yes (Premix 30/70)';
            p2.Hypertension = 'Yes (Telmisartan 40mg)';
            p2.Smoking = 'Non-smoker';
            p2.eGFR = 54;
            p2.BCVA_OD = '6/24';
            p2.BCVA_OS = '6/18';
            p2.IOP_OD = 18.0;
            p2.IOP_OS = 17.5;
            p2.CataractStatus = 'Clear Lens';
            p2.Symptoms = 'Sudden vision loss episodes, dark cobwebs in right eye';
            p2.CurrentStage = 4; % PDR
            p2.DME = 'Center-Involving CSME (<500um)';
            p2.CurrentFundus = 'stage_4_proliferative_dr_OD.png';
            p2.Visits = [
                struct('Date', '2025-01-10', 'Stage', 3, 'StageName', 'Severe NPDR', 'HbA1c', 9.2, 'MACount', 45, 'ExudateArea', 0.35, 'BCVA', '6/18', 'Action', 'Advised laser, lost to follow-up'), ...
                struct('Date', '2026-09-19', 'Stage', 4, 'StageName', 'Proliferative DR (NVD)', 'HbA1c', 9.8, 'MACount', 62, 'ExudateArea', 0.52, 'BCVA', '6/24', 'Action', 'URGENT: STAT Vitrectomy & PRP Laser booking')
            ];
            
            % 3. Sunita Bai (Normal case)
            p3 = struct();
            p3.UHID = 'MP-IND-2024-3310';
            p3.ABHA = '91-6621-8831-2290';
            p3.Name = 'Sunita Bai';
            p3.Age = 52;
            p3.Gender = 'Female';
            p3.Phone = '+91 97550 43198';
            p3.District = 'Dhar (Badnawar PHC)';
            p3.DiabetesType = 'Type 2 DM';
            p3.DurationYears = 4;
            p3.HbA1c = 6.7;
            p3.FastingGlucose = 124;
            p3.Insulin = 'No (Diet + Metformin 500mg)';
            p3.Hypertension = 'No';
            p3.Smoking = 'Non-smoker';
            p3.eGFR = 92;
            p3.BCVA_OD = '6/6';
            p3.BCVA_OS = '6/6';
            p3.IOP_OD = 14.0;
            p3.IOP_OS = 14.5;
            p3.CataractStatus = 'None';
            p3.Symptoms = 'Routine screening, no visual complaints';
            p3.CurrentStage = 0; % No DR
            p3.DME = 'No DME';
            p3.CurrentFundus = 'stage_0_normal_OD.png';
            p3.Visits = [
                struct('Date', '2025-08-14', 'Stage', 0, 'StageName', 'No DR', 'HbA1c', 6.6, 'MACount', 0, 'ExudateArea', 0.00, 'BCVA', '6/6', 'Action', 'Annual rescreening scheduled'), ...
                struct('Date', '2026-09-19', 'Stage', 0, 'StageName', 'No DR', 'HbA1c', 6.7, 'MACount', 0, 'ExudateArea', 0.00, 'BCVA', '6/6', 'Action', 'Normal fundus confirmed, rescreen in 12m')
            ];
            
            % 4. Mohan Lal (Mild NPDR)
            p4 = struct();
            p4.UHID = 'MP-IND-2024-9921';
            p4.ABHA = '91-1120-7744-8833';
            p4.Name = 'Mohan Lal';
            p4.Age = 64;
            p4.Gender = 'Male';
            p4.Phone = '+91 91110 32871';
            p4.District = 'Ujjain (Mahidpur Vision Centre)';
            p4.DiabetesType = 'Type 2 DM';
            p4.DurationYears = 8;
            p4.HbA1c = 7.4;
            p4.FastingGlucose = 148;
            p4.Insulin = 'No';
            p4.Hypertension = 'Yes (Enalapril 5mg)';
            p4.Smoking = 'Smoker (Bidi, 10/day)';
            p4.eGFR = 71;
            p4.BCVA_OD = '6/9';
            p4.BCVA_OS = '6/9';
            p4.IOP_OD = 15.0;
            p4.IOP_OS = 15.5;
            p4.CataractStatus = 'Early Cortical';
            p4.Symptoms = 'Occasional night glare';
            p4.CurrentStage = 1; % Mild NPDR
            p4.DME = 'No DME';
            p4.CurrentFundus = 'stage_1_mild_npdr_OD.png';
            p4.Visits = [
                struct('Date', '2026-09-19', 'Stage', 1, 'StageName', 'Mild NPDR', 'HbA1c', 7.4, 'MACount', 7, 'ExudateArea', 0.00, 'BCVA', '6/9', 'Action', 'Rescreen in 6-12m, smoking cessation counseling')
            ];
            
            % 5. Kamala Devi (Severe NPDR)
            p5 = struct();
            p5.UHID = 'MP-IND-2024-7741';
            p5.ABHA = '91-5543-2219-0012';
            p5.Name = 'Kamala Devi';
            p5.Age = 61;
            p5.Gender = 'Female';
            p5.Phone = '+91 98930 65112';
            p5.District = 'Khargone (Kasrawad CHC)';
            p5.DiabetesType = 'Type 2 DM';
            p5.DurationYears = 14;
            p5.HbA1c = 8.7;
            p5.FastingGlucose = 192;
            p5.Insulin = 'Yes (Lantus 14u)';
            p5.Hypertension = 'Yes';
            p5.Smoking = 'Non-smoker';
            p5.eGFR = 62;
            p5.BCVA_OD = '6/18';
            p5.BCVA_OS = '6/12';
            p5.IOP_OD = 17.0;
            p5.IOP_OS = 16.0;
            p5.CataractStatus = 'Pseudophakic OS, NS-1 OD';
            p5.Symptoms = 'Significant vision drop in right eye';
            p5.CurrentStage = 3; % Severe NPDR
            p5.DME = 'Non-Center-Involving DME';
            p5.CurrentFundus = 'stage_3_severe_npdr_OD.png';
            p5.Visits = [
                struct('Date', '2026-09-19', 'Stage', 3, 'StageName', 'Severe NPDR', 'HbA1c', 8.7, 'MACount', 38, 'ExudateArea', 0.31, 'BCVA', '6/18', 'Action', 'Priority tele-referral within 7 days for PRP')
            ];
            
            obj.Patients = [p1, p2, p3, p4, p5];
            
            % Populate Clinical Review Queue matching Stitch Screen 0a418bfa...
            obj.ReviewQueue = {
                'Ramesh Patel, 58M', 'MP-IND-2024-5512', 'PDR (Stage 4)', 'Center-Involving DME', 'STAT (<48h)', '96.2%', 'Dewas DH', 'Claimed';
                'Kamala Devi, 61F', 'MP-IND-2024-7741', 'Severe NPDR (Stage 3)', 'Non-CI DME', 'Urgent (<7d)', '91.8%', 'Kasrawad CHC', 'Pending';
                'Suresh C. Verma, 56M', 'MP-IND-2024-8819', 'Moderate NPDR (Stage 2)', 'Non-CI DME', 'Priority (<14d)', '87.6%', 'Sanwer CHC', 'In Review';
                'Mohan Lal, 64M', 'MP-IND-2024-9921', 'Mild NPDR (Stage 1)', 'No DME', 'Routine (6m)', '89.4%', 'Mahidpur VC', 'Pending';
                'Sunita Bai, 52F', 'MP-IND-2024-3310', 'No DR (Stage 0)', 'No DME', 'Normal (12m)', '98.5%', 'Badnawar PHC', 'Completed';
                'Mangilal Joshi, 67M', 'MP-IND-2024-1102', 'Severe NPDR (Stage 3)', 'CSME Present', 'Urgent (<7d)', '93.4%', 'Depalpur PHC', 'Pending';
                'Sundar Bai, 60F', 'MP-IND-2024-4428', 'Moderate NPDR (Stage 2)', 'No DME', 'Priority (<30d)', '85.2%', 'Mhow Vision Centre', 'Pending'
            };
            
            % Populate Referrals (ABDM Fast-Track Linked) matching Screen 22762618...
            obj.Referrals = {
                'REF-2026-0919-01', 'Ramesh Patel', '91-3819-4402-9912', 'M.Y. Hospital Eye OPD', 'Vitrectomy / PRP Laser', 'STAT (<48h)', 'Dispatched (FHIR)', 'ASHA Mobilized';
                'REF-2026-0919-02', 'Kamala Devi', '91-5543-2219-0012', 'Choithram Netralaya Indore', 'Panretinal Laser Evaluation', 'Urgent (<7d)', 'Booked for 22 Sep', 'SMS Sent';
                'REF-2026-0919-03', 'Suresh C. Verma', '91-4829-1092-4411', 'MGM Medical College Eye Centre', 'Macular OCT & Anti-VEGF', 'Priority (<14d)', 'Pending Doctor Sign', 'Queue #14';
                'REF-2026-0919-04', 'Mangilal Joshi', '91-8812-4011-3329', 'AIIMS Bhopal Retina Clinic', 'Intravitreal Anti-VEGF Workup', 'Urgent (<7d)', 'Acknowledged', 'Transport Scheduled'
            };
        end
        
        function p = getPatientByUHID(obj, uhid)
            p = [];
            for k = 1:length(obj.Patients)
                if strcmp(obj.Patients(k).UHID, uhid)
                    p = obj.Patients(k);
                    return;
                end
            end
        end
    end
end
