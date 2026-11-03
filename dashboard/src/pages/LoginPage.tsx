import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Activity, Shield, Sparkles, ArrowRight, Lock, Phone } from 'lucide-react';

export const LoginPage: React.FC = () => {
  const { login, demoLogin } = useAuth();
  const [phoneNumber, setPhoneNumber] = useState('');
  const [password, setPassword] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await login(phoneNumber, password);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-parchment flex flex-col justify-center items-center p-4 font-figtree">
      {/* Container */}
      <div className="max-w-md w-full bg-surface-card rounded-md border border-black/15 shadow-xl p-8 space-y-6">
        {/* Brand Header */}
        <div className="text-center space-y-2">
          <div className="w-12 h-12 bg-brand-primary rounded-sm flex items-center justify-center mx-auto shadow-sm">
            <Activity className="w-7 h-7 text-ink stroke-[2.5]" />
          </div>
          <h1 className="text-2xl font-bold text-ink">Pashuvani</h1>
          <p className="text-xs text-ink-secondary font-inter">
            Government Livestock Epidemic & Disease Surveillance Portal
          </p>
          <div className="inline-flex items-center gap-1 text-[11px] font-semibold text-vet-accent border border-vet-accent/40 bg-vet-light/50 px-2 py-0.5 rounded-sm font-inter">
            <Shield className="w-3 h-3" /> Animal Husbandry Department, Maharashtra
          </div>
        </div>

        {/* 1-Click Demo Evaluation Button (Essential for Hackathon Judging) */}
        <div className="bg-brand-primary/15 border-2 border-brand-primary/50 p-4 rounded-sm space-y-2">
          <div className="flex items-center gap-1.5 text-xs font-bold text-ink uppercase tracking-wide">
            <Sparkles className="w-4 h-4 text-brand-hover fill-brand-primary" />
            Hackathon Judge / Evaluator Mode
          </div>
          <p className="text-[11px] text-ink-secondary font-inter">
            Bypass manual login to inspect the live surveillance dashboard as Pune District Animal Health Officer:
          </p>
          <button
            type="button"
            onClick={demoLogin}
            className="w-full btn-primary text-xs h-11 flex items-center justify-center gap-2"
          >
            <span>1-Click Demo Login (Dr. Suresh Patil)</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>

        <div className="relative flex py-1 items-center">
          <div className="flex-grow border-t border-black/10"></div>
          <span className="flex-shrink mx-4 text-xs text-ink-metadata uppercase font-inter font-semibold">
            Or Standard Credentials
          </span>
          <div className="flex-grow border-t border-black/10"></div>
        </div>

        {/* Credentials Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-xs font-inter">
          <div>
            <label className="block text-ink-secondary font-medium mb-1 flex items-center gap-1">
              <Phone className="w-3 h-3 text-ink-metadata" /> Registered Phone Number
            </label>
            <input
              type="text"
              required
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              placeholder="+91 98220 12345"
              className="w-full px-3 py-2.5 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary"
            />
          </div>

          <div>
            <label className="block text-ink-secondary font-medium mb-1 flex items-center gap-1">
              <Lock className="w-3 h-3 text-ink-metadata" /> Department Password
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••••••"
              className="w-full px-3 py-2.5 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full btn-secondary h-11 text-xs font-semibold"
          >
            {isSubmitting ? 'Authenticating...' : 'Sign In with Government ID'}
          </button>
        </form>

        <div className="pt-2 text-center text-[11px] text-ink-metadata font-inter border-t border-black/5">
          Restricted access. Encrypted via Go JWT RBAC protocol.
        </div>
      </div>
    </div>
  );
};

