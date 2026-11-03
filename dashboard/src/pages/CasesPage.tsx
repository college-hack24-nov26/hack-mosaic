// @ts-nocheck
import React from 'react';
import { DiseaseReport } from '../types';
import { CaseTable } from '../components/cases/CaseTable';

interface CasesPageProps {
  reports: DiseaseReport[];
  onSelectReport: (report: DiseaseReport) => void;
}

export const CasesPage: React.FC<CasesPageProps> = ({ reports, onSelectReport }) => {
  return (
    <div className="space-y-4 animate-fadeIn font-figtree">
      <div>
        <h1 className="text-2xl font-bold text-ink">Field Case Management</h1>
        <p className="text-sm text-ink-secondary font-inter">
          Comprehensive log of farmer-submitted disease reports, clinical photographs, and veterinary validation
        </p>
      </div>

      <CaseTable reports={reports} onSelectReport={onSelectReport} />
    </div>
  );
};

