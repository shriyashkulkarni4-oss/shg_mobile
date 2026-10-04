import { useState } from "react";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { toast } from "sonner";
import axios from "axios";
import { doc, updateDoc } from "firebase/firestore";
import { db } from "../firebase";

interface Props {
  uid: string;
  phone: string;
  onVerified: () => void;
}

export function VerifyPhone({ uid, phone, onVerified }: Props) {
  const [otp, setOtp] = useState("");
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);

  const sendOtp = async () => {
    if (!uid || !phone) {
    toast.error("Invalid user or phone number");
    return;
  }
    try {
      setLoading(true);
      await axios.post("http://localhost:5003/send-otp", {
        phone,
      });
      setSent(true);
      toast.success("OTP sent");
    } catch (err) {
      toast.error("Failed to send OTP");
    } finally {
      setLoading(false);
    }
  };

 const verifyOtp = async () => {
  if (otp.length !== 4) {
    toast.error("Enter valid 4-digit OTP");
    return;
  }
  try {
    const res = await fetch("http://localhost:5003/verify-otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ phone, otp }),
    });

    const data = await res.json();

    if (!res.ok) {
      toast.error("Invalid OTP");
      return;
    }

    // ✅ STEP 1: UPDATE FIRESTORE
    await updateDoc(doc(db, "users", uid), {
      phoneVerified: true,
    });

    toast.success("Phone verified successfully");

    // ✅ STEP 2: FORCE DASHBOARD LOAD
    onVerified();

  } catch (err) {
    console.error(err);
    toast.error("Verification failed");
  }
};


  return (
    <div className="p-8 max-w-md mx-auto">
      <h2 className="text-xl mb-4">Verify Phone Number</h2>

      {!sent ? (
        <Button onClick={sendOtp} disabled={loading}>
          Send OTP to {phone}
        </Button>
      ) : (
        <>
          <Input
            placeholder="Enter OTP"
            value={otp}
            onChange={(e) => setOtp(e.target.value)}
            className="my-4"
          />
          <Button onClick={verifyOtp} disabled={loading}>
            Verify OTP
          </Button>
        </>
      )}
    </div>
  );
}
