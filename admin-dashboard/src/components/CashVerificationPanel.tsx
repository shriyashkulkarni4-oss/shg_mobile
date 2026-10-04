import { SetStateAction, useState } from "react";
import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { toast } from "sonner";
import { collection, query, where, getDocs, updateDoc } from "firebase/firestore";
import { db } from "./firebase"; // adjust path

interface Props {
  phone: string;
  emiId: string;
  loanId: string;
  emiAmount: number;
  monthIndex?: number;
  markEmiPaid: (loanId: string, emiAmount: number, txHash: string,monthIndex?: number) => Promise<void>;
}

export default function CashVerificationPanel({
  phone,
  emiId,
  loanId,
  emiAmount,
   monthIndex,
  markEmiPaid,
}: Props) {
  const [otp, setOtp] = useState("");
  const [loading, setLoading] = useState(false);

  const verifyCashPayment = async () => {
    if (otp.length !== 4) {
      toast.error("Enter valid 4-digit OTP");
      return;
    }

    setLoading(true);

    try {
      const res = await fetch("http://localhost:5002/verify-otp", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          phone,
          otp,
          emiId,
        }),
      });

      const data = await res.json();

      // if (data.success) {
      //   await markEmiPaid(loanId, emiAmount, "CASH");

      //   toast.success("Cash payment verified");
      //   setOtp("");
      // }
      if (data.success) {

  // 🔥 1. UPDATE TRANSACTION STATUS
  const q = query(
    collection(db, "transactions"),
    where("loanId", "==", loanId),
    where("emiId", "==", emiId),
    where("status", "==", "PENDING")
  );

  const snap = await getDocs(q);

  for (const docSnap of snap.docs) {
  await updateDoc(docSnap.ref, {
    status: "VERIFIED",
    verifiedAt: new Date(),
  });
}

  // 🔥 2. UPDATE LOAN EMI
  await markEmiPaid(loanId, emiAmount, "CASH",monthIndex);

  toast.success("Cash payment verified");
  setOtp("");
}
       else {
        toast.error(data.message || "Invalid OTP");
      }
    } catch (err) {
      console.error(err);
      toast.error("Verification failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      <Input
        placeholder="Enter OTP"
        value={otp}
        onChange={(e: { target: { value: SetStateAction<string>; }; }) => setOtp(e.target.value)}
      />

      <Button onClick={verifyCashPayment} disabled={loading}>
        Verify Cash Payment
      </Button>
    </div>
  );
}