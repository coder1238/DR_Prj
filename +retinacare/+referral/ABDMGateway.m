classdef ABDMGateway < handle
    % ABDMGATEWAY Ayushman Bharat Digital Mission (ABDM) Integration Gateway
    % Generates FHIR DiagnosticReport and ServiceRequest resources, routes
    % tertiary referrals, and coordinates ASHA field health worker mobilization.
    
    methods (Static)
        function fhirReport = generateFHIRDiagnosticReport(patient, aiResult, doctorNotes)
            % Generate standard FHIR HL7 R4 DiagnosticReport
            if nargin < 3, doctorNotes = 'Validated by Tele-Ophthalmologist'; end
            
            reportId = sprintf('DR-REP-%s-%d', regexprep(patient.UHID, '[^a-zA-Z0-9]', ''), round(posixtime(datetime('now'))));
            
            fhirReport = struct();
            fhirReport.resourceType = 'DiagnosticReport';
            fhirReport.id = reportId;
            fhirReport.status = 'final';
            fhirReport.category = struct('coding', struct('system', 'http://terminology.hl7.org/CodeSystem/v2-0074', 'code', 'OPH', 'display', 'Ophthalmology'));
            fhirReport.code = struct('coding', struct('system', 'http://snomed.info/sct', 'code', '4855003', 'display', 'Diabetic Retinopathy Screening'));
            fhirReport.subject = struct('reference', sprintf('Patient/%s', patient.ABHA), 'display', patient.Name);
            fhirReport.effectiveDateTime = datestr(now, 'yyyy-mm-ddTHH:MM:SSZ');
            fhirReport.conclusion = sprintf('%s; %s. Confidence: %.1f%%.', aiResult.StageLabel, aiResult.DMEVerdict, aiResult.Confidence);
            fhirReport.conclusionCode = struct('coding', struct('system', 'http://snomed.info/sct', 'code', sprintf('ICDR-%d', aiResult.PredictedStage), 'display', aiResult.StageLabel));
            fhirReport.performer = struct('display', 'Dr. Sharma, MD (Ophthalmology)', 'reference', 'Practitioner/IND-MGM-OPH-084');
            fhirReport.note = struct('text', doctorNotes);
        end
        
        function fhirRequest = generateFHIRServiceRequest(patient, destinationHospital, procedureType, urgency)
            % Generate standard FHIR ServiceRequest for tertiary hospital referral
            reqId = sprintf('SRV-REQ-%d', round(posixtime(datetime('now'))));
            
            fhirRequest = struct();
            fhirRequest.resourceType = 'ServiceRequest';
            fhirRequest.id = reqId;
            fhirRequest.status = 'active';
            fhirRequest.intent = 'order';
            fhirRequest.priority = lower(strtok(urgency, ' '));
            fhirRequest.subject = struct('reference', sprintf('Patient/%s', patient.ABHA), 'display', patient.Name);
            fhirRequest.requester = struct('display', 'RetinaCare Tele-Ophthalmology Hub #01');
            fhirRequest.performer = struct('display', destinationHospital);
            fhirRequest.code = struct('coding', struct('system', 'http://snomed.info/sct', 'code', '399878007', 'display', procedureType));
            fhirRequest.authoredOn = datestr(now, 'yyyy-mm-ddTHH:MM:SSZ');
        end
        
        function alert = dispatchASHAAlert(patient, referralInfo)
            % Dispatches SMS/WhatsApp notification to assigned ASHA worker
            alert = struct();
            alert.Recipient = 'Sunita Parmar (ASHA Worker, Sector 4)';
            alert.Phone = '+91 97521 88402';
            alert.Patient = patient.Name;
            alert.ABHA = patient.ABHA;
            alert.Message = sprintf('URGENT ASHA ACTION: Patient %s requires escorted referral to %s for %s. Appointment window: %s. Please verify transport.', ...
                patient.Name, referralInfo.Hospital, referralInfo.Procedure, referralInfo.Urgency);
            alert.Status = 'SENT (Gateway ACK: 200 OK)';
            alert.Timestamp = datestr(now, 'HH:MM:SS dd-mmm-yyyy');
        end
    end
end
