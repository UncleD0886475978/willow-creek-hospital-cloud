-- Willow Creek Regional Hospital — Org Structure Schema
-- NOTE: This models staffing/departments only. No patient/PHI tables are
-- included here by design — those require a separate, more tightly
-- controlled schema, access model, and encryption strategy.

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Clinical' or 'Support'
    description TEXT
);

INSERT INTO departments (name, category, description) VALUES
('Executive Administration', 'Support', 'Hospital-wide leadership and operations'),
('Emergency Department', 'Clinical', 'Trauma and urgent care'),
('Internal Medicine', 'Clinical', 'General adult medical care'),
('Surgery', 'Clinical', 'Surgical procedures and pre/post-op care'),
('Intensive Care Unit', 'Clinical', 'Critical care for acute patients'),
('Radiology', 'Clinical', 'Diagnostic imaging services'),
('Laboratory', 'Clinical', 'Diagnostic testing and pathology'),
('Pharmacy', 'Clinical', 'Medication dispensing and management'),
('IT / Health Informatics', 'Support', 'Systems, EHR, and technology infrastructure'),
('Housekeeping / Environmental Services', 'Support', 'Facility cleaning and sanitation');

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role VARCHAR(100) NOT NULL,
    tier VARCHAR(20) NOT NULL, -- 'Director', 'Manager', 'Staff'
    department_id INTEGER REFERENCES departments(id),
    hire_date DATE,
    email VARCHAR(100)
);

-- Executive Administration
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Margaret', 'Ellsworth', 'Chief Executive Officer', 'Director', 1, '2019-04-01', 'm.ellsworth@willowcreekhospital.org'),
('Thomas', 'Reyes', 'Chief Operating Officer', 'Manager', 1, '2020-08-15', 't.reyes@willowcreekhospital.org'),
('Dana', 'Whitfield', 'Administrative Coordinator', 'Staff', 1, '2023-02-10', 'd.whitfield@willowcreekhospital.org');

-- Emergency Department
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Robert', 'Nakamura', 'Emergency Department Director', 'Director', 2, '2018-06-12', 'r.nakamura@willowcreekhospital.org'),
('Linda', 'Osei', 'Charge Nurse', 'Manager', 2, '2021-01-20', 'l.osei@willowcreekhospital.org'),
('Carlos', 'Mendez', 'ED Technician', 'Staff', 2, '2023-09-05', 'c.mendez@willowcreekhospital.org');

-- Internal Medicine
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Dr. Susan', 'Park', 'Chief of Medicine', 'Director', 3, '2017-03-22', 's.park@willowcreekhospital.org'),
('Dr. Ahmed', 'Farouk', 'Attending Physician', 'Manager', 3, '2020-11-01', 'a.farouk@willowcreekhospital.org'),
('Jenna', 'Cruz', 'Medical Assistant', 'Staff', 3, '2022-07-18', 'j.cruz@willowcreekhospital.org');

-- Surgery
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Dr. William', 'Hargrove', 'Chief of Surgery', 'Director', 4, '2016-09-09', 'w.hargrove@willowcreekhospital.org'),
('Patricia', 'Nguyen', 'Surgical Nurse Lead', 'Manager', 4, '2019-05-14', 'p.nguyen@willowcreekhospital.org'),
('Marcus', 'Bell', 'Surgical Technician', 'Staff', 4, '2023-01-30', 'm.bell@willowcreekhospital.org');

-- ICU
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Dr. Elena', 'Vasquez', 'ICU Director', 'Director', 5, '2018-02-14', 'e.vasquez@willowcreekhospital.org'),
('Michael', 'Fitzgerald', 'ICU Charge Nurse', 'Manager', 5, '2021-06-07', 'm.fitzgerald@willowcreekhospital.org'),
('Sarah', 'Kowalski', 'ICU Nurse', 'Staff', 5, '2023-04-11', 's.kowalski@willowcreekhospital.org');

-- Radiology
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Dr. James', 'Okonkwo', 'Radiology Director', 'Director', 6, '2019-10-03', 'j.okonkwo@willowcreekhospital.org'),
('Angela', 'Ruiz', 'Lead Technologist', 'Manager', 6, '2020-12-19', 'a.ruiz@willowcreekhospital.org'),
('Kevin', 'Tran', 'Radiology Technician', 'Staff', 6, '2022-08-25', 'k.tran@willowcreekhospital.org');

-- Laboratory
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Dr. Nicole', 'Andersen', 'Laboratory Director', 'Director', 7, '2017-11-11', 'n.andersen@willowcreekhospital.org'),
('Brian', 'Osei-Tutu', 'Lab Supervisor', 'Manager', 7, '2020-03-16', 'b.oseitutu@willowcreekhospital.org'),
('Emily', 'Rossi', 'Lab Technician', 'Staff', 7, '2023-05-22', 'e.rossi@willowcreekhospital.org');

-- Pharmacy
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Dr. Frank', 'Delgado', 'Chief Pharmacist', 'Director', 8, '2018-07-30', 'f.delgado@willowcreekhospital.org'),
('Monica', 'Ibrahim', 'Staff Pharmacist', 'Manager', 8, '2021-09-13', 'm.ibrahim@willowcreekhospital.org'),
('Tyler', 'Brooks', 'Pharmacy Technician', 'Staff', 8, '2023-03-08', 't.brooks@willowcreekhospital.org');

-- IT / Health Informatics
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Derek', 'Simmons', 'IT Director', 'Director', 9, '2019-01-07', 'd.simmons@willowcreekhospital.org'),
('Priya', 'Chandrasekar', 'Systems Administrator', 'Manager', 9, '2021-04-19', 'p.chandrasekar@willowcreekhospital.org'),
('Jordan', 'Vega', 'Help Desk Technician', 'Staff', 9, '2023-06-26', 'j.vega@willowcreekhospital.org');

-- Housekeeping / Environmental Services
INSERT INTO employees (first_name, last_name, role, tier, department_id, hire_date, email) VALUES
('Gloria', 'Marsh', 'EVS Director', 'Director', 10, '2018-05-04', 'g.marsh@willowcreekhospital.org'),
('Hector', 'Villanueva', 'Shift Supervisor', 'Manager', 10, '2020-10-27', 'h.villanueva@willowcreekhospital.org'),
('Amy', 'Doyle', 'Custodian', 'Staff', 10, '2023-08-14', 'a.doyle@willowcreekhospital.org');
