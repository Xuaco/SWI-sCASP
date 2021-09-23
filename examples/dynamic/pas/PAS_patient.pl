:- module(pas_patient,
          [ measurement/2,
            history/1,
            case_diagnosis/1,
            case_evidence/1,
            case_contraindication/1
          ]).
:- use_module(library(scasp)).

:- discontiguous
    case_evidence/1,
    history/1,
    measurement/2.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Patient-01's profile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Patient Interface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Evidence
:- pred evidence(accf_stage_c) :: 'the patient is in ACCF stage C'.
:- pred evidence(pregnancy) :: 'the patient is pregnant or planning to get pregnant'.
:- pred evidence('E') :: 'the patient is/has @(E)'.

%% Diagnosis
:- pred diagnosis(hf_with_reduced_ef) ::
       'the patient is diagnosed with heart failure with reduced ejection fraction'.
:- pred diagnosis('D') :: 'the patient is diagnosed with @(D)'.

%% History
:- pred history('H') :: 'the patient has a history of @(H)'.

%% Measurement
:- pred measurement('M','V') :: 'there is a measurement of @(M) of @(V)'.

%* Demographics *%
measurement(age, 76).
case_evidence(african_american).
case_evidence(male).

%* Assessments *%
case_evidence(nyha_class_4).
case_evidence(accf_stage_c).

%* Contraindications *%
case_contraindication(continuous_positive_airway_pressure).

%* Diagnoses *%
case_diagnosis(ischemic_heart_disease).
case_diagnosis(hypertension).
case_diagnosis(diabetes).
case_diagnosis(atrial_fibrillation).

%* Dosages *%

%* Evidence *%
case_evidence(sleepApnea).
case_evidence(angina).

%* Illness History *%
history(stroke).
history(ischemic_attack).

%* Measurements *%
measurement(lvef, 0.35).
measurement(heart_rate, 72).
measurement(creatinine, 1.9).
measurement(glomerular_filtration_rate, 55).
measurement(potassium, 4.2).

%* Medication History *%
history(ace_inhibitors).
history(beta_blockers).