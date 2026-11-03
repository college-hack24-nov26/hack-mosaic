import React, { createContext, useContext, useState, useEffect } from 'react';
import { User } from '../types';
import { api } from '../services/api';
import { mockCurrentUser } from '../services/mockData';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (phone: string, pass: string) => Promise<void>;
  demoLogin: () => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('pashurakshak_token');
    if (token) {
      setUser(mockCurrentUser);
    }
    setIsLoading(false);
  }, []);

  const login = async (phone: string, pass: string) => {
    const res = await api.login(phone, pass);
    setUser(res.user);
  };

  const demoLogin = () => {
    localStorage.setItem('pashurakshak_token', 'demo_authority_token');
    setUser(mockCurrentUser);
  };

  const logout = () => {
    localStorage.removeItem('pashurakshak_token');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, isAuthenticated: !!user, isLoading, login, demoLogin, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
};

