import axios from "axios";

const API_BASE = "http://localhost:5003";

export const sendEmiOtp = async (emiId: string) => {
  return axios.post(`${API_BASE}/send-otp`, { emiId });
};

export const verifyEmiOtp = async (emiId: string, otp: string) => {
  return axios.post(`${API_BASE}/verify-otp`, { emiId, otp });
};

export const payEmi = async (emiId: string) => {
  return axios.post(`${API_BASE}/pay`, { emiId });
};

export const getMemberEmis = async (memberId: string) => {
  return axios.get(`${API_BASE}/member/${memberId}`);
};

