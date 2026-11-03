// @ts-nocheck
import React from 'react';
import { 
  LayoutDashboard, 
  Map, 
  BookOpen, 
  ClipboardList, 
  AlertOctagon, 
  Syringe, 
  Users, 
  HelpCircle 
} from 'lucide-react';

export type TabType = 'overview' | 'map' | 'protocols' | 'cases' | 'alerts' | 'vaccination' | 'workforce';

interface SidebarProps {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
  pendingCount?: number;
  alertCount?: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  onTabChange,
  pendingCount = 24,
  alertCount = 3,
}) => {
  const navItems = [
    {
      id: 'overview' as TabType,
      label: 'Surveillance Overview',
      icon: LayoutDashboard,
      badge: null,
    },
    {
      id: 'map' as TabType,
      label: 'Outbreak Geospatial Map',
      icon: Map,
      badge: 'Live',
    },
    {
      id: 'protocols' as TabType,
      label: 'Biosecurity Protocols',
      icon: BookOpen,
      badge: '5 Path',
      badgeColor: 'bg-blue-100 text-[#2F6FDE]',
    },
    {
      id: 'cases' as TabType,
      label: 'Case Management',
      icon: ClipboardList,
      badge: pendingCount > 0 ? `${pendingCount}` : null,
      badgeColor: 'bg-caution-amber text-ink',
    },
    {
      id: 'alerts' as TabType,
      label: 'Outbreak Alerts',
      icon: AlertOctagon,
      badge: alertCount > 0 ? `${alertCount}` : null,
      badgeColor: 'bg-alert-critical text-white',
    },
    {
      id: 'vaccination' as TabType,
      label: 'Vaccination Drive',
      icon: Syringe,
      badge: '42.8k',
      badgeColor: 'bg-green-100 text-[#16a34a]',
    },
    {
      id: 'workforce' as TabType,
      label: 'Field Workforce',
      icon: Users,
      badge: '48 Active',
      badgeColor: 'bg-blue-100 text-[#2F6FDE]',
    },
  ];

  return (
    <aside className="w-64 bg-surface-card border-r border-black/10 flex flex-col justify-between shrink-0 font-figtree select-none min-h-[calc(100vh-4rem)]">
      <div className="p-4 space-y-1">
        <div className="text-[11px] font-bold uppercase tracking-wider text-ink-metadata px-3 py-2">
          Surveillance Console
        </div>

        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;

          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              className={`w-full flex items-center justify-between px-3.5 py-3 rounded-sm text-sm font-semibold transition-all duration-150 cursor-pointer ${
                isActive
                  ? 'bg-parchment text-ink shadow-sm border-l-4 border-l-brand-primary'
                  : 'text-ink-secondary hover:bg-parchment/60 hover:text-ink'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon
                  className={`w-4 h-4 ${
                    isActive ? 'text-ink' : 'text-ink-metadata'
                  }`}
                />
                <span>{item.label}</span>
              </div>

              {item.badge && (
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-pill font-mono ${
                    item.badgeColor || 'bg-brand-primary/30 text-ink'
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* System Status in Sidebar Footer */}
      <div className="p-4 border-t border-black/5 bg-parchment/40 text-xs font-inter space-y-2">
        <div className="flex items-center justify-between text-ink-metadata">
          <span className="flex items-center gap-1.5 font-medium">
            <span className="w-2 h-2 rounded-full bg-brand-primary animate-pulse"></span>
            Telemetry Stream
          </span>
          <span className="font-mono text-[10px]">Connected</span>
        </div>
        <div className="text-[11px] text-ink-metadata">
          <div className="font-semibold text-ink">DAHD Outbreak Node v1.0</div>
          <div>PostgreSQL 16 + PostGIS</div>
        </div>
      </div>
    </aside>
  );
};
