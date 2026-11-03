import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { Activity, Bell, LogOut, Shield, MapPin, ChevronDown, AlertTriangle, Film } from 'lucide-react';

interface NavbarProps {
  onOpenBroadcast: () => void;
  onNavigateToMap?: () => void;
  onReplayIntro?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  onOpenBroadcast,
  onNavigateToMap,
  onReplayIntro,
}) => {
  const { user, logout } = useAuth();
  const [timeStr, setTimeStr] = useState('14:28:52 IST');

  useEffect(() => {
    const updateTime = () => {
      const d = new Date();
      setTimeStr(d.toLocaleTimeString('en-US', { hour12: false }) + ' IST');
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="h-16 bg-surface-card border-b border-black/10 px-6 flex items-center justify-between sticky top-0 z-30 font-figtree">
      {/* Brand & Telemetry Controls */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-lg bg-brand-primary flex items-center justify-center shadow-sm">
            <Activity className="w-5 h-5 text-ink stroke-[2.5]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-lg tracking-tight text-ink">
                PashuRakshak
              </span>
              <span className="text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-black/5 text-ink-secondary">
                Govt Portal
              </span>
            </div>
            <p className="text-[10px] text-ink-metadata font-inter -mt-0.5">
              Government Animal Health & Disease Surveillance
            </p>
          </div>
        </div>

        {/* Scope Dropdown (From Reference Screenshot 1) */}
        <div className="hidden md:flex items-center gap-1.5 bg-parchment/80 border border-black/10 px-3 py-1 rounded text-xs">
          <MapPin className="w-3.5 h-3.5 text-zinc-500" />
          <span>Scope: <strong>Maharashtra (Statewide)</strong></span>
          <ChevronDown className="w-3 h-3 text-zinc-500" />
        </div>

        {/* Live Telemetry Status */}
        <div className="hidden lg:flex items-center gap-1.5 px-2.5 py-0.5 rounded bg-emerald-50 text-emerald-800 border border-emerald-200 text-[11px] font-semibold">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
          <span>LIVE TELEMETRY</span>
        </div>

        {/* Live Clock */}
        <div className="hidden xl:flex items-center gap-1 text-zinc-600 font-mono text-[11px]">
          {timeStr}
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3">
        {/* Threat Warning Pill */}
        {onNavigateToMap && (
          <button
            onClick={onNavigateToMap}
            className="hidden sm:flex items-center gap-1.5 bg-red-50 text-alert-critical border border-red-200 px-3 py-1.5 rounded font-bold text-xs hover:bg-red-100 transition-colors"
          >
            <AlertTriangle className="w-3.5 h-3.5" />
            <span>3 HIGH/CRIT THREATS</span>
          </button>
        )}

        {/* Replay Intro Button */}
        {onReplayIntro && (
          <button
            onClick={onReplayIntro}
            title="Replay Netflix Cinematic Intro"
            className="p-2 text-ink-metadata hover:text-ink hover:bg-parchment rounded-sm transition-colors"
          >
            <Film className="w-4 h-4" />
          </button>
        )}

        {/* Primary Broadcast Warning Button */}
        <button
          onClick={onOpenBroadcast}
          className="btn-primary h-10 px-4 text-xs"
        >
          <Bell className="w-4 h-4 fill-ink" />
          <span>Broadcast Warning</span>
        </button>

        {/* User Role Badge */}
        {user && (
          <div className="flex items-center gap-3 pl-3 border-l border-black/10">
            <div className="text-right hidden sm:block">
              <div className="text-xs font-bold text-ink">{user.name}</div>
              <div className="flex items-center justify-end gap-1 mt-0.5">
                <span className="inline-flex items-center gap-0.5 text-[10px] font-semibold text-vet-accent border border-vet-accent/40 bg-blue-50 px-1.5 py-0.2 rounded-sm font-inter">
                  <Shield className="w-2.5 h-2.5" /> {user.role.toUpperCase()}
                </span>
                <span className="text-[10px] text-ink-metadata font-inter">
                  • {user.district}
                </span>
              </div>
            </div>

            <button
              onClick={logout}
              title="Logout session"
              className="p-2 text-ink-metadata hover:text-alert-critical hover:bg-parchment rounded-sm transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        )}
      </div>
    </header>
  );
};
