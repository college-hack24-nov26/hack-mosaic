import React, { useState, useEffect } from 'react';
import { ShieldAlert, Activity, ArrowRight, Volume2 } from 'lucide-react';

interface SplashScreenProps {
  onDismiss: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onDismiss }) => {
  const [isFadingOut, setIsFadingOut] = useState(false);

  // Pure Web Audio API synthesized cinematic Ta-Dum sound (Zero external dependencies)
  const playTaDumSound = () => {
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const now = ctx.currentTime;

      // Sub-bass impact oscillator
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(65, now);
      osc1.frequency.exponentialRampToValueAtTime(28, now + 1.2);

      gain1.gain.setValueAtTime(0.01, now);
      gain1.gain.exponentialRampToValueAtTime(0.8, now + 0.08);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 1.8);

      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 1.9);

      // Shimmer harmonic overtone
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(220, now + 0.05);
      osc2.frequency.exponentialRampToValueAtTime(110, now + 0.8);

      gain2.gain.setValueAtTime(0.001, now);
      gain2.gain.exponentialRampToValueAtTime(0.25, now + 0.1);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 1.2);

      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.05);
      osc2.stop(now + 1.3);
    } catch {
      // Audio context may require user interaction in some browsers
    }
  };

  const handleDismiss = () => {
    setIsFadingOut(true);
    setTimeout(() => {
      onDismiss();
    }, 750);
  };

  // Auto-dismiss after 2.8s
  useEffect(() => {
    const timer = setTimeout(handleDismiss, 2800);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div
      className={`fixed inset-0 bg-[#060708] z-[99999] flex flex-col items-center justify-center overflow-hidden transition-all duration-700 ease-out select-none ${
        isFadingOut ? 'opacity-0 scale-105 pointer-events-none' : 'opacity-100 scale-100'
      }`}
      style={{
        background: 'radial-gradient(circle at center, #111417 0%, #060708 100%)',
      }}
    >
      {/* Ambient Cinema Light Rays */}
      <div className="absolute w-[600px] h-[600px] rounded-full bg-[#94e130]/15 blur-[90px] animate-pulse pointer-events-none" />

      {/* Main Brand Stage */}
      <div className="relative z-10 flex flex-col items-center text-center px-6 max-w-xl animate-fadeIn">
        {/* Animated Brand Emblem */}
        <div className="relative mb-6">
          <div className="w-24 h-24 rounded-2xl bg-gradient-to-tr from-[#94e130] to-[#b6f756] flex items-center justify-center shadow-[0_0_50px_rgba(148,225,48,0.65)] transform hover:scale-105 transition-transform duration-300">
            <ShieldAlert className="w-14 h-14 text-[#141414] stroke-[2.4]" />
          </div>
          <div className="absolute -bottom-2 -right-2 w-8 h-8 rounded-full bg-[#2F6FDE] flex items-center justify-center text-white border-2 border-[#060708] shadow-md">
            <Activity className="w-4 h-4 stroke-[2.5]" />
          </div>
        </div>

        {/* Netflix-Style Cinematic Typography */}
        <h1 className="text-4xl sm:text-6xl font-black text-white font-figtree tracking-wider uppercase mb-1">
          <span className="text-white drop-shadow-[0_0_35px_rgba(148,225,48,0.7)]">
            PASHURAKSHAK
          </span>
        </h1>
        <p className="text-xs uppercase tracking-[0.35em] font-bold text-[#94e130] font-inter">
          National Livestock Disease & Outbreak Surveillance Network
        </p>

        {/* Diagnostic Boot Telemetry Feed */}
        <div className="mt-8 bg-white/5 border border-white/10 rounded-xl p-4 font-mono text-[11px] text-zinc-400 space-y-1.5 w-full text-left shadow-2xl backdrop-blur-md">
          <div className="flex items-center justify-between pb-1.5 border-b border-white/5 text-[10px] uppercase text-zinc-500 font-bold">
            <span>System Diagnostic Feed</span>
            <span className="text-[#94e130]">v1.0-RC ONLINE</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#94e130]"></span> PostGIS RFC 7946 GeoJSON Stream:
            </span>
            <span className="text-[#94e130] font-bold">CONNECTED</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#94e130]"></span> MobileNetV3 Edge Inference Engine:
            </span>
            <span className="text-[#94e130] font-bold">INITIALIZED</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#94e130]"></span> XGBoost Epidemic Hotspot Classifier:
            </span>
            <span className="text-[#94e130] font-bold">ACTIVE (84% CONF)</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#2F6FDE]"></span> Jurisdiction:
            </span>
            <span className="text-white font-semibold">Maharashtra (Statewide)</span>
          </div>
        </div>

        {/* Action Controls */}
        <div className="mt-7 flex flex-wrap items-center justify-center gap-3">
          <button
            onClick={handleDismiss}
            className="px-7 py-3 bg-[#94e130] text-[#141414] font-black text-xs uppercase tracking-widest rounded-lg shadow-[0_0_25px_rgba(148,225,48,0.5)] hover:bg-[#82c927] transition-all flex items-center gap-2 active:scale-95 cursor-pointer"
          >
            <span>Enter Surveillance Console</span>
            <ArrowRight className="w-4 h-4 stroke-[3]" />
          </button>
          <button
            onClick={playTaDumSound}
            className="px-4 py-3 bg-white/10 hover:bg-white/20 text-white font-bold text-xs uppercase tracking-wider rounded-lg transition-all flex items-center gap-2 border border-white/15"
            title="Play Cinematic Sound"
          >
            <Volume2 className="w-4 h-4 text-[#94e130]" />
            <span>Play Ta-Dum</span>
          </button>
        </div>

        {/* Progress bar */}
        <div className="w-64 bg-white/10 h-1 rounded-full mt-6 overflow-hidden">
          <div className="h-full bg-gradient-to-r from-[#94e130] to-[#2F6FDE] w-full animate-[splashProgress_2.8s_linear_forwards]" />
        </div>
        <span className="text-[10px] text-zinc-500 mt-2 font-inter">Auto-launching in 2.8 seconds...</span>
      </div>
    </div>
  );
};

