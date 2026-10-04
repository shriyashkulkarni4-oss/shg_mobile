// import { useEffect, useState } from "react";
// import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../ui/card";
// import { Button } from "../ui/button";
// import { Badge } from "../ui/badge";
// import { Progress } from "../ui/progress";
// import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "../ui/dialog";
// import { Input } from "../ui/input";
// import { Label } from "../ui/label";
// import { Textarea } from "../ui/textarea";
// import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../ui/select";
// import { Calculator, TrendingUp, CheckCircle2, Clock, AlertCircle, Plus } from "lucide-react";
// import { toast } from "sonner";
// import { Slider } from "../ui/slider";
// import { addDoc, collection, doc, getDoc, serverTimestamp, Timestamp, query, where, getDocs, orderBy, updateDoc, onSnapshot } from "firebase/firestore";
// import { db } from "../firebase";
// import { useAuth } from "../AuthContext"; // adjust path
// import { Emi } from "../../types/emi";

// import OTPVerification from "./OTPVerification";
// import { getContract, getReadContract, decodeRepaymentTx } from "./blockchain";
// import { ethers } from "ethers";


// interface Loan {
//   id: string;
//   amount: number;
//   disbursed: string;
//   purpose: string;
//   emi: number;
//   remaining: number;
//   nextDue: string;
//   status: "PENDING" | "APPROVED" | "REJECTED";
//   isVerified: boolean;
// }

// interface LoanManagementProps {
//   loans: Loan[];
//   trustScore: number;
//   savings: number;
// }

// export function LoanManagement({ loans, trustScore, savings }: LoanManagementProps) {
//   const [isOtpVerified, setIsOtpVerified] = useState(false);
//   const [isApplyDialogOpen, setIsApplyDialogOpen] = useState(false);
//   const [isCalculatorOpen, setIsCalculatorOpen] = useState(false);
//   const [loanAmount, setLoanAmount] = useState(10000);
//   const [loanTenure, setLoanTenure] = useState(12);
//   const [showOtp, setShowOtp] = useState(false);
//   const [phoneNumber, setPhoneNumber] = useState<string | null>(null);
//   const [selectedEmiId, setSelectedEmiId] = useState<string | null>(null);
//   const { uid, shgId } = useAuth();
//   const [userName, setMemberName] = useState("");
//   const [loanId, setLoanId] = useState<string | null>();
//   const [amount, setAmount] = useState("");
//   const [status, setStatus] = useState("");
//   const [successPay, setPay] = useState(0);
//   const [totalContributed, setTotalContributed] = useState(0);

//   const [repayments, setRepayments] = useState<any[]>([]);

//   const [txHash, setTxHash] = useState("");          // latest tx hash
//   const [inputTxHash, setInputTxHash] = useState(""); // verification input
//   const [verifiedData, setVerifiedData] = useState<any>(null);
//   const [isPaying, setIsPaying] = useState(false);

//   const [isOpen, setIsOpen] = useState(false);
//   const [selectedLoan, setSelectedLoan] = useState<any>(null);

//   const [loanApplication, setLoanApplication] = useState({
//     amount: "",
//     purpose: "",
//     tenure: "",
//     description: ""
//   });

//   const interestRate = 12; // Annual interest rate
//   const generateDueDates = (startDate: Date, months: number) => {
//   const dates: {
//     date: Timestamp;
//     paid: boolean;
//     paidAt?: Timestamp;
//     txHash?: string;
//   }[] = [];

//     for (let i = 1; i <= months; i++) {
//       const due = new Date(startDate);
//       due.setMonth(due.getMonth() + i);

//       dates.push({
//         date: Timestamp.fromDate(due),
//         paid: false,

//       });
//     }

//     return dates;
//   };

//   const calculateEMI = (principal: number, tenure: number) => {
//     const monthlyRate = interestRate / 12 / 100;
//     const emi = (principal * monthlyRate * Math.pow(1 + monthlyRate, tenure)) /
//       (Math.pow(1 + monthlyRate, tenure) - 1);
//     return Math.round(emi);
//   };

//   const calculateEligibility = () => {
//     const maxLoan = savings * 2; // Can borrow up to 2x savings
//     const trustScoreMultiplier = trustScore >= 90 ? 1.2 : trustScore >= 80 ? 1.1 : 1.0;
//     return Math.round(maxLoan * trustScoreMultiplier);
//   };
//   const getCurrentEmiIndex = (dueDates: any[]) => {
//     return dueDates.findIndex((d) => d.paid === false);
//   };

//   function getTrustMultiplier(score: number) {
//   if (score < 40) return 0;        // ❌ No loan
//   if (score < 55) return 1.5;
//   if (score < 70) return 2.0;
//   if (score < 80) return 2.5;
//   if (score < 90) return 3.0;
//   return 3.5;
// }


// const BASE_CAP = 90000; // SHG safety cap

// function calculateEligibleAmount(
//   savings: number,
//   trustScore: number,
//   // activeLoanBalance: number
// ) {
//   const multiplier = getTrustMultiplier(trustScore);

//   const trustLimit = savings * multiplier;
//   // const netLimit = trustLimit - activeLoanBalance;

//   return Math.max(
//     0,
//     Math.min(BASE_CAP, trustLimit)
//   );
// }

// // const markEmiPaid = async (
// //   loanId: string,
// //   emiAmount: number,
// //   hash: string,
// //   monthIndex?: number
// // ) => {
// //     const loanRef = doc(db, "ShgGroups", shgId!, "loans", loanId);
// //     const snap = await getDoc(loanRef);

// //     if (!snap.exists()) return;

// //     const loan = snap.data();
// //     const dueDates = [...loan.dueDates];

// //    const currentIndex =
// //   monthIndex !== undefined
// //     ? monthIndex
// //     : getCurrentEmiIndex(dueDates);
// //     if (currentIndex === -1) return; // already fully paid

// //     // mark EMI paid
// //     dueDates[currentIndex] = {
// //       ...dueDates[currentIndex],
// //       paid: true,
// //       paidAt: Timestamp.now(),   // 🔥 EMI payment time
// //       txHash: hash,            // 🔥 blockchain tx hash
// //     };

// //     const newPaidAmount = loan.paidAmount + emiAmount;
// //     const newRemaining = loan.remainingAmount - emiAmount;

// //     const allPaid = dueDates.every((d: any) => d.paid);

// //     await updateDoc(loanRef, {
// //       dueDates,
// //       paidAmount: newPaidAmount,
// //       remainingAmount: Math.max(newRemaining, 0),
// //       status: allPaid ? "COMPLETED" : "APPROVED",
// //     });
// //   };

// const markEmiPaid = async (
//   loanId: string,
//   emiAmount: number,
//   hash: string,
//   monthIndex?: number
// ) => {
//   try {
//     if (!shgId) return;

//     const loanRef = doc(db, "ShgGroups", shgId, "loans", loanId);
//     const snap = await getDoc(loanRef);

//     if (!snap.exists()) return;

//     const loan = snap.data();
//     const dueDates = [...(loan.dueDates || [])];

//     // ✅ determine correct EMI index
//     const currentIndex =
//       monthIndex !== undefined
//         ? monthIndex
//         : getCurrentEmiIndex(dueDates);

//     if (currentIndex === -1) {
//       console.log("⚠️ All EMIs already paid");
//       return;
//     }

//     // ❌ prevent duplicate payment
//     if (dueDates[currentIndex]?.paid) {
//       console.log("⚠️ EMI already paid at index:", currentIndex);
//       return;
//     }

//     // ✅ update EMI
//     dueDates[currentIndex] = {
//       ...dueDates[currentIndex],
//       paid: true,
//       paidAt: Timestamp.now(),
//       txHash: hash || "0",
//     };

//     // ✅ safe calculations
//     const newPaidAmount = (loan.paidAmount || 0) + emiAmount;
//     const newRemaining = (loan.remainingAmount || 0) - emiAmount;

//     const allPaid = dueDates.every((d: any) => d.paid);

//     await updateDoc(loanRef, {
//       dueDates: JSON.parse(JSON.stringify(dueDates)), // ✅ FORCE DEEP WRITE
//       paidAmount: newPaidAmount,
//       remainingAmount: Math.max(newRemaining, 0),
//       status: allPaid ? "COMPLETED" : "APPROVED",
//     });

//     console.log("✅ EMI UPDATED SUCCESSFULLY:", {
//       loanId,
//       index: currentIndex,
//       amount: emiAmount,
//     });

//   } catch (err) {
//     console.error("❌ markEmiPaid ERROR:", err);
//   }
// };

//   const fetchUserPhone = async () => {
//     if (!uid) return null;

//     const q = query(
//       collection(db, "users"),
//       where("uid", "==", uid)
//     );

//     const snap = await getDocs(q);

//     if (snap.empty) {
//       console.log("No user found for uid:", uid);
//       return null;
//     }

//     const userData = snap.docs[0].data();
//     console.log("User data:", userData);

//     return userData.phoneNumber;
//   };

//   const fetchUserLoans = async () => {
//     const q = query(
//       collection(db, "ShgGroups", shgId!, "loans"),
//       where("memberId", "==", uid)
//     );

//     const snap = await getDocs(q);

//     return snap.docs.map(doc => ({
//       id: doc.id,
//       ...doc.data(),
//     }));
//   };

//   const eligibleAmount = calculateEligibility();
//   const emi = calculateEMI(loanAmount, loanTenure);
//   const totalPayable = emi * loanTenure;
//   const totalInterest = totalPayable - loanAmount;
//   // uid + shgId
//   const [loans2, setLoans] = useState<any[]>([]);
//   const [loadingLoans, setLoadingLoans] = useState(true);

//   // useEffect(() => {
//   //   if (!uid || !shgId) return;

//   //   const loadLoans = async () => {
//   //     try {
//   //       const userLoans = await fetchUserLoans();
//   //       setLoans(userLoans);
//   //     } catch (err) {
//   //       console.error(err);
//   //     } finally {
//   //       setLoadingLoans(false);
//   //     }
//   //   };

//   //   loadLoans();
//   // }, [uid, shgId]);
//   useEffect(() => {
//     console.log("Ethereum at load:", window.ethereum);
//     loadRepayments();
//   }, []);
//   useEffect(() => {
//     if (!shgId || !uid) return;

//     const unsub = onSnapshot(
//       doc(db, "ShgGroups", shgId, "members", uid),
//       (snap) => {
//         if (snap.exists()) {
//           setMemberName(snap.data().name);
//         }
//       }
//     );

//     return () => unsub();
//   }, [shgId, uid]);
//   useEffect(() => {
//     if (!shgId || !uid) return;

//     const q = query(
//       collection(db, "ShgGroups", shgId, "loans"),
//       where("memberId", "==", uid)
//     );

//     const unsub = onSnapshot(q, (snap) => {
//       const data = snap.docs.map((d) => ({
//         id: d.id,
//         ...d.data(),
//       }));
//       setLoans(data);
//     });

//     return () => unsub();
//   }, [shgId, uid]);


//     useEffect(() => {
//   if (!shgId || !uid) return;

//   const fetchTotalContributed = async () => {
//     let total = 0;

//     const roundsSnap = await getDocs(
//       collection(db, "ShgGroups", shgId, "monthlyRounds")
//     );

//     for (const roundDoc of roundsSnap.docs) {
//       const contribRef = collection(
//         db,
//         "ShgGroups",
//         shgId,
//         "monthlyRounds",
//         roundDoc.id,
//         "contributions"
//       );

//       const contribSnap = await getDocs(contribRef);

//       contribSnap.forEach((c) => {
//         if (c.id === uid) {
//           total += c.data().amountPaid || 0;
//         }
//       });
//     }

//     setTotalContributed(total);
//   };

//   fetchTotalContributed();
// }, [shgId, uid]);


//   const loadRepayments = async () => {
//     try {
//       const contract = await getReadContract();
//       const total = await contract.totalRepayments();
//       const count = Number(total);

//       const data = [];

//       for (let i = 0; i < count; i++) {
//         const r = await contract.getRepayment(i);
//         data.push({
//           payer: r.payer,
//           loanId: r.loanId.toString(),
//           amount: ethers.formatEther(r.amount),
//           time: new Date(Number(r.timestamp) * 1000).toLocaleString(),
//         });
//       }

//       setRepayments(data);
//     } catch (err) {
//       console.error("❌ loadRepayments failed:", err);
//     }
//   };
  
//   const payEMI = async () => {
//     try {
//       setStatus("Waiting for wallet...");
//       const contract = await getContract();

//       const tx = await contract.payEMI(
//         Number(loanId),
//         { value: ethers.parseEther(amount) }
//       );

//       setTxHash(tx.hash);
//       await tx.wait();

//       setStatus("✅ EMI recorded on blockchain");
//       return tx.hash;
//     } catch (err: any) {
//       setStatus("❌ " + err.message);
//       return null;
//     }
//   };

// //   const handleCashPayment = async (emiId) => {
// //   const phone = await fetchUserPhone();

// //   await fetch("http://localhost:5001/send-otp", {
// //     method: "POST",
// //     headers: { "Content-Type": "application/json" },
// //     body: JSON.stringify({
// //       phone,
// //       emiId
// //     })
// //   });

// //   toast.success("OTP sent. Give it to agent after payment.");
// // };

// // const handleCashPayment = async (emiId: string) => {
// //   try {
// //     const phone = await fetchUserPhone();

// //     if (!phone) {
// //       toast.error("Phone number not found");
// //       return;
// //     }

// //     const res = await fetch("http://localhost:5001/send-otp", {
// //       method: "POST",
// //       headers: {
// //         "Content-Type": "application/json",
// //       },
// //       body: JSON.stringify({
// //         phone,
// //         emiId,
// //       }),
// //     });

// //     const data = await res.json();

// //     if (data.success) {
// //       toast.success("OTP sent. Give it to agent after payment.");
// //     } else {
// //       toast.error("Failed to send OTP");
// //     }
// //   } catch (err) {
// //     console.error(err);
// //     toast.error("Error sending OTP");
// //   }
// // };

// const handleCashPayment = async (loan: any) => {
//   try {
//     const phone = await fetchUserPhone();

//     if (!phone) {
//       toast.error("Phone number not found");
//       return;
//     }
//     const dueDates = loan.dueDates || [];

//     const currentIndex = dueDates.findIndex((d: any) => !d.paid);

//     if (currentIndex === -1) {
//       toast.error("All EMIs already paid");
//       return;
//     }
//     // 🔥 1. CREATE TRANSACTION IN FIRESTORE
//     await addDoc(collection(db, "transactions"), {
//       memberId: uid,
//       loanId: loan.id,
//       emiId: loan.id, // (you are using loan.id as emiId)
//       amount: loan.emi, // 🔥 REAL EMI AMOUNT
//       monthIndex: currentIndex,
//       mode: "CASH",
//       status: "PENDING",
//       phone,
//       shgId,
//       createdAt: serverTimestamp(),
//     });

//     // 🔥 2. SEND OTP
//     const res = await fetch("http://localhost:5001/send-otp", {
//       method: "POST",
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: JSON.stringify({
//         phone,
//         emiId: loan.id,
//       }),
//     });

//     const data = await res.json();

//     if (data.success) {
//       toast.success("OTP sent. Give it to admin after payment.");
//     } else {
//       toast.error("Failed to send OTP");
//     }
//   } catch (err) {
//     console.error(err);
//     toast.error("Error sending OTP");
//   }
// };

//   const mappedLoans = loans2.map((loan) => {
//     const nextDueDate = (() => {
//       if (!loan.dueDates || loan.dueDates.length === 0) return null;

//       // NEW FORMAT: { date, paid }
//       if (typeof loan.dueDates[0] === "object" && loan.dueDates[0].date) {
//         return loan.dueDates.find((d: any) => !d.paid)?.date?.toDate?.();
//       }

//       // OLD FORMAT: Timestamp[]
//       return loan.dueDates[0]?.toDate?.();
//     })();


//     return {
//       id: loan.id,
//       purpose: loan.purpose,
//       status: loan.status,

//       amount: loan.principalAmount,
//       remaining: loan.remainingAmount,
//       emi: loan.emiAmount,
//       dueDates: loan.dueDates,
//       disbursed: loan.startDate?.toDate().toLocaleDateString("en-IN") || "0",
//       nextDue: nextDueDate
//         ? nextDueDate.toLocaleDateString("en-IN")
//         : "ALL EMI's PAID",
//       isVerified: loan.isVerified || false,
//     };
//   });
//   const forceConnectWallet = async () => {
//     if (!window.ethereum) {
//       alert("MetaMask not installed");
//       return false;
//     }

//     const accounts = await window.ethereum.request({
//       method: "eth_requestAccounts",
//     });

//     if (!accounts || accounts.length === 0) {
//       alert("No account selected");
//       return false;
//     }

//     console.log("Connected:", accounts[0]);
//     return true;
//   };

//   const handleVerifyClick = async (emiId: string) => {
//     const phone = await fetchUserPhone();

//     if (!phone) {
//       toast.error("Phone number not found");
//       return;
//     }

//     setSelectedEmiId(emiId);
//     setPhoneNumber(phone);
//     setIsOtpVerified(false); // 🔥 reset every time
//     setShowOtp(true);
//   };


//   const handleApplyLoan = async () => {
//     if (!loanApplication.amount || !loanApplication.purpose || !loanApplication.tenure) {
//       toast.error("Please fill in all required fields");
//       return;
//     }

//     try {

//       const principal = Number(loanApplication.amount);
//       const tenure = Number(loanApplication.tenure);
//       const startDate = new Date();
//       const purpose = loanApplication.purpose
//       const description = loanApplication.description;
//       const monthlyRate = interestRate / 12 / 100;
//       const emi =
//         (principal * monthlyRate * Math.pow(1 + monthlyRate, tenure)) /
//         (Math.pow(1 + monthlyRate, tenure) - 1);

//       const emiAmount = Math.round(emi);
//       const totalPayable = emiAmount * tenure;
//       const memberRef2 = doc(
//         db,
//         "ShgGroups", shgId!
//       );
//       const memberSnap2 = await getDoc(memberRef2);
//       const loanDoc = {
//         adminId: memberSnap2!.data()!.createdBy, // assigned later on approval
//         memberId: uid,

//         principalAmount: principal,
//         interestRate,
//         tenureMonths: tenure,

//         emiAmount,
//         totalPayable,
//         paidAmount: 0,
//         remainingAmount: totalPayable,
//         purpose: purpose,
//         description: description,
//         startDate: Timestamp.fromDate(startDate),
//         dueDates: generateDueDates(startDate, tenure),

//         status: "PENDING", // APPROVED after admin approval
//         isVerified: false,
//         createdAt: serverTimestamp(),
//       };

//       await addDoc(
//         collection(db, "ShgGroups", shgId!, "loans"),
//         loanDoc
//       );

//       toast.success("Loan application submitted successfully!");
//       setIsApplyDialogOpen(false);
//       setLoanApplication({ amount: "", purpose: "", tenure: "", description: "" });

//     } catch (err) {
//       console.error(err);
//       toast.error("Failed to apply loan");
//     }
//   };

//   // 🔹 popup-specific paid status (outside map, safe scope)


//   return (


//     <div className="max-w-[1600px] mx-auto space-y-6">
//       {/* Header */}
//       <div className="flex justify-between items-start">
//         <div>
//           <h2 className="text-3xl text-gray-900 mb-2">Loan Management</h2>
//           <p className="text-gray-600">Manage your loans and explore new opportunities</p>
//         </div>
//         <div className="flex gap-3">
//           <Dialog open={isCalculatorOpen} onOpenChange={setIsCalculatorOpen}>
//             <DialogTrigger asChild>
//               <Button variant="outline" className="gap-2">
//                 <Calculator className="w-4 h-4" />
//                 EMI Calculator
//               </Button>
//             </DialogTrigger>
//             <DialogContent className="max-w-2xl">
//               <DialogHeader>
//                 <DialogTitle>Loan EMI Calculator</DialogTitle>
//                 <DialogDescription>
//                   Calculate your monthly installments and plan your loan
//                 </DialogDescription>
//               </DialogHeader>
//               <div className="space-y-6">
//                 <div className="space-y-4">
//                   <div className="space-y-2">
//                     <div className="flex justify-between">
//                       <Label>Loan Amount</Label>
//                       <span className="text-sm">₹{loanAmount.toLocaleString('en-IN')}</span>
//                     </div>
//                     <Slider
//                       value={[loanAmount]}
//                       onValueChange={([value]) => setLoanAmount(value)}
//                       min={2000}
//                       max={134560}
//                       step={1}
//                       className="w-full"
//                     />
//                   </div>

//                   <div className="space-y-2">
//                     <div className="flex justify-between">
//                       <Label>Tenure (Months)</Label>
//                       <span className="text-sm">{loanTenure} months</span>
//                     </div>
//                     <Slider
//                       value={[loanTenure]}
//                       onValueChange={([value]) => setLoanTenure(value)}
//                       min={3}
//                       max={24}
//                       step={1}
//                       className="w-full"
//                     />
//                   </div>
//                 </div>

//                 <div className="grid grid-cols-2 gap-4 p-4 bg-gray-50 rounded-lg">
//                   <div>
//                     <p className="text-sm text-gray-600">Monthly EMI</p>
//                     <p className="text-2xl text-teal-600">₹{emi.toLocaleString('en-IN')}</p>
//                   </div>
//                   <div>
//                     <p className="text-sm text-gray-600">Total Interest</p>
//                     <p className="text-2xl text-orange-600">₹{totalInterest.toLocaleString('en-IN')}</p>
//                   </div>
//                   <div>
//                     <p className="text-sm text-gray-600">Total Payable</p>
//                     <p className="text-2xl text-gray-900">₹{totalPayable.toLocaleString('en-IN')}</p>
//                   </div>
//                   <div>
//                     <p className="text-sm text-gray-600">Interest Rate</p>
//                     <p className="text-2xl text-gray-900">{interestRate}% p.a.</p>
//                   </div>
//                 </div>
//               </div>
//             </DialogContent>
//           </Dialog>

//           <Dialog open={isApplyDialogOpen} onOpenChange={setIsApplyDialogOpen}>
//             <DialogTrigger asChild>
//               <Button className="gap-2">
//                 <Plus className="w-4 h-4" />
//                 Apply for Loan
//               </Button>
//             </DialogTrigger>
//             <DialogContent>
//               <DialogHeader>
//                 <DialogTitle>Apply for New Loan</DialogTitle>
//                 <DialogDescription>
//                   Submit your loan application for group review
//                 </DialogDescription>
//               </DialogHeader>
//               <div className="space-y-4">
//                 <div className="space-y-2">
//                   <Label htmlFor="loan-amount">Loan Amount (₹) *</Label>
//                   <Input
//                     id="loan-amount"
//                     type="number"
//                     placeholder="20000"
//                     value={loanApplication.amount}
//                       max={calculateEligibleAmount(totalContributed,trustScore)}
//                     onChange={(e) => setLoanApplication({ ...loanApplication, amount: e.target.value })}
//                   />
//                   <p className="text-xs text-gray-500">
//                     You are eligible for up to ₹{calculateEligibleAmount(totalContributed,trustScore)}
//                   </p>
//                 </div>
//                 <div className="space-y-2">
//                   <Label htmlFor="loan-purpose">Loan Purpose *</Label>
//                   <Select
//                     value={loanApplication.purpose}
//                     onValueChange={(value: any) => setLoanApplication({ ...loanApplication, purpose: value })}
//                   >
//                     <SelectTrigger>
//                       <SelectValue placeholder="Select purpose" />
//                     </SelectTrigger>
//                     <SelectContent>
//                       <SelectItem value="business">Business/Livelihood</SelectItem>
//                       <SelectItem value="education">Education</SelectItem>
//                       <SelectItem value="medical">Medical Emergency</SelectItem>
//                       <SelectItem value="agriculture">Agriculture</SelectItem>
//                       <SelectItem value="home">Home Improvement</SelectItem>
//                       <SelectItem value="other">Other</SelectItem>
//                     </SelectContent>
//                   </Select>
//                 </div>
//                 <div className="space-y-2">
//                   <Label htmlFor="loan-tenure">Repayment Tenure (Months) *</Label>
//                   <Select
//                     value={loanApplication.tenure}
//                     onValueChange={(value: any) => setLoanApplication({ ...loanApplication, tenure: value })}
//                   >
//                     <SelectTrigger>
//                       <SelectValue placeholder="Select tenure" />
//                     </SelectTrigger>
//                     <SelectContent>
//                       <SelectItem value="6">6 months</SelectItem>
//                       <SelectItem value="12">12 months</SelectItem>
//                       <SelectItem value="18">18 months</SelectItem>
//                       <SelectItem value="24">24 months</SelectItem>
//                     </SelectContent>
//                   </Select>
//                 </div>
//                 <div className="space-y-2">
//                   <Label htmlFor="loan-description">Description</Label>
//                   <Textarea
//                     id="loan-description"
//                     placeholder="Provide details about how you plan to use this loan..."
//                     value={loanApplication.description}
//                     onChange={(e) => setLoanApplication({ ...loanApplication, description: e.target.value })}
//                     rows={3}
//                   />
//                 </div>
//               </div>
//               <DialogFooter>
//                 <Button variant="outline" onClick={() => setIsApplyDialogOpen(false)}>Cancel</Button>
//                 <Button onClick={handleApplyLoan}>Submit Application</Button>
//               </DialogFooter>
//             </DialogContent>
//           </Dialog>
//         </div>
//       </div>

//       {/* Eligibility Card */}
//       <Card className="bg-gradient-to-br from-teal-50 to-blue-50 border-teal-200">
//         <CardHeader>
//           <CardTitle className="flex items-center gap-2">
//             <CheckCircle2 className="w-5 h-5 text-teal-600" />
//             Your Loan Eligibility
//           </CardTitle>
//         </CardHeader>
//         <CardContent>
//           <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
//             <div>
//               <p className="text-sm text-gray-600 mb-1">Maximum Eligible Amount</p>
//               <p className="text-3xl text-teal-600">₹{calculateEligibleAmount(totalContributed,trustScore)}</p>
//               <p className="text-xs text-gray-500 mt-1">Based on your savings and trust score</p>
//             </div>
//             <div>
//               <p className="text-sm text-gray-600 mb-1">Trust Score</p>
//               <p className="text-3xl text-gray-900">{trustScore}</p>
//               <div className="flex items-center gap-2 mt-1">
//                 <Progress value={trustScore} className="h-2 flex-1" />
//                 <span className="text-xs text-gray-500">{trustScore}%</span>
//               </div>
//             </div>
//             <div>
//               <p className="text-sm text-gray-600 mb-1">Interest Rate</p>
//               <p className="text-3xl text-gray-900">{interestRate}%</p>
//               <p className="text-xs text-gray-500 mt-1">Annual interest rate</p>
//             </div>
//           </div>
//         </CardContent>
//       </Card>

//       {/* APPROVED Loans */}
//       <div className="space-y-4">
//         <h3 className="text-xl text-gray-900">APPROVED Loans</h3>
//         {mappedLoans.length > 0 ? (
//           <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
//             {mappedLoans.map((loan) => {
//               const totalEmis = loan.dueDates.length;
//               const paidEmis = loan.dueDates.filter((d: any) => d.paid).length;
//               const repaidPercentage = (paidEmis / totalEmis) * 100;

//               const currentEmiIndex = getCurrentEmiIndex(loan.dueDates);
//               const isFullyPaid = currentEmiIndex === -1;

//               return (
//                 <Card key={loan.id}>
//                   <CardHeader>
//                     <div className="flex justify-between items-start">
//                       <div>
//                         <CardTitle>{loan.purpose}</CardTitle>
//                         <CardDescription className="flex items-center gap-2 mt-1">
//                           Disbursed: {loan.disbursed}
//                         </CardDescription>
//                       </div>
//                       <Badge
//                         className={
//                           loan.status === "COMPLETED"
//                             ? "bg-blue-100 text-blue-800"
//                             : loan.status === "APPROVED"
//                               ? "bg-green-100 text-green-800"
//                               : loan.status === "REJECTED"
//                                 ? "bg-orange-600 text-red"
//                                 : "bg-yellow-100 text-yellow-800"

//                         }
//                       >
//                         {loan.status}

//                       </Badge>

//                     </div>
//                   </CardHeader>
//                   <CardContent className="space-y-4">
//                     {/* Loan Amount */}
//                     <div className="grid grid-cols-2 gap-4">
//                       <div>
//                         <p className="text-sm text-gray-600">Loan Amount</p>
//                         <p className="text-xl text-gray-900">₹{loan.amount.toLocaleString('en-IN')}</p>
//                       </div>
//                       <div>
//                         <p className="text-sm text-gray-600">Remaining</p>
//                         <p className="text-xl text-orange-600">₹{loan.remaining.toLocaleString('en-IN')}</p>
//                       </div>
//                     </div>

//                     {/* Repayment Progress */}
//                     <div className="space-y-2">
//                       <div className="flex justify-between text-sm">
//                         <span className="text-gray-600">Repayment Progress</span>
//                         <span className="text-gray-900">{repaidPercentage.toFixed(1)}%</span>
//                       </div>
//                       <Progress value={repaidPercentage} className="h-3" />
//                     </div>

//                     {/* EMI Details */}
//                     <div className="bg-blue-50 p-4 rounded-lg">
//                       <div className="flex items-center justify-between mb-2">
//                         <span className="text-sm text-gray-600">Monthly EMI</span>
//                         <span className="text-lg text-gray-900">₹{loan.emi.toLocaleString('en-IN')}</span>
//                       </div>
//                       <div className="flex items-center gap-2 text-sm">
//                         <Clock className="w-4 h-4 text-orange-600" />
//                         <span className="text-gray-600">Next Due: <span className="text-orange-600">{loan.nextDue}</span></span>
//                       </div>
//                       <div className="flex flex-col gap-3">
//                         <Button
//                           onClick={() => handleVerifyClick(loan.id)}
//                           variant="outline"
//                           disabled={loan.isVerified}
//                         >
//                           {loan.isVerified ? "Verified" : "Verify EMI"}
//                         </Button>


//                         <Button
//                           disabled={!loan.isVerified || isFullyPaid}
//                           className={`w-full ${!loan.isVerified
//                             ? "opacity-50 cursor-not-allowed"
//                             : isFullyPaid
//                               ? "bg-green-600 hover:bg-green-600 cursor-not-allowed"
//                               : ""
//                             }`}
//                           onClick={() => {
//                             if (!loan.isVerified || isFullyPaid) return;
//                             setSelectedLoan(loan);
//                             setIsOpen(true); // 👉 confirmation popup
//                           }}
//                         >
//                           {!loan.isVerified
//                             ? "Verify EMI First"
//                             : isFullyPaid
//                               ? "✅ Paid"
//                               : `Pay ₹${loan.emi}`}
//                         </Button>

//                         <Button onClick={() => handleCashPayment(loan)}>
//   Pay via Cash
// </Button>

//                       </div>
//                     </div>
//                   </CardContent>
//                 </Card>
//               );
//             })}
//           </div>
//         ) : (
//           <Card>
//             <CardContent className="py-12 text-center">
//               <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-4" />
//               <p className="text-gray-600 mb-4">You don't have any APPROVED loans</p>
//               <Button onClick={() => setIsApplyDialogOpen(true)}>Apply for Your First Loan</Button>
//             </CardContent>
//           </Card>
//         )}
//       </div>

//       {/* Loan Benefits */}
//       <Card className="border-purple-200 bg-purple-50/30">
//         <CardHeader>
//           <CardTitle className="flex items-center gap-2">
//             <TrendingUp className="w-5 h-5 text-purple-600" />
//             Benefits of SHG Loans
//           </CardTitle>
//         </CardHeader>
//         <CardContent>
//           <ul className="space-y-2 text-gray-700">
//             <li className="flex gap-2">
//               <span className="text-purple-600">•</span>
//               <span>Lower interest rates compared to traditional banks and moneylenders</span>
//             </li>
//             <li className="flex gap-2">
//               <span className="text-purple-600">•</span>
//               <span>Flexible repayment terms decided by the group</span>
//             </li>
//             <li className="flex gap-2">
//               <span className="text-purple-600">•</span>
//               <span>No collateral required - trust score determines eligibility</span>
//             </li>
//             <li className="flex gap-2">
//               <span className="text-purple-600">•</span>
//               <span>Quick approval process within the group</span>
//             </li>
//             <li className="flex gap-2">
//               <span className="text-purple-600">•</span>
//               <span>Support from fellow members throughout the repayment journey</span>
//             </li>
//           </ul>
//         </CardContent>
//       </Card>

//       <Dialog open={showOtp} onOpenChange={setShowOtp}>
//         <DialogContent className="max-w-md">
//           <DialogHeader>
//             <DialogTitle>Verify EMI</DialogTitle>
//             <DialogDescription>
//               Enter the OTP sent to your registered phone number
//             </DialogDescription>
//           </DialogHeader>

//           {phoneNumber && (
//             <OTPVerification
//               phoneNumber={phoneNumber}
//               onVerified={async () => {
//                 if (!selectedEmiId || !shgId) return;

//                 await updateDoc(
//                   doc(db, "ShgGroups", shgId, "loans", selectedEmiId),
//                   { isVerified: true }
//                 );

//                 // update local UI instantly
//                 setLoans((prev) =>
//                   prev.map((loan) =>
//                     loan.id === selectedEmiId
//                       ? { ...loan, isVerified: true }
//                       : loan
//                   )
//                 );

//                 setIsOtpVerified(true);
//                 setShowOtp(false);
//                 toast.success("OTP verified. You can now pay EMI.");
//               }}
//             />

//           )}
//         </DialogContent>
//       </Dialog>
//       {isOpen && selectedLoan && (
//         <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
//           <Card className="w-full max-w-md rounded-2xl shadow-xl border border-gray-200">

//             {/* Header */}
//             <CardHeader className="pb-2">
//               <CardTitle className="text-xl font-semibold text-center">
//                 Confirm Contribution
//               </CardTitle>
//               <p className="text-sm text-center text-gray-500">
//                 Please verify your payment details
//               </p>
//             </CardHeader>

//             {/* Content */}
//             <CardContent className="space-y-6 px-6 pb-6">

//               {/* Info Box */}
//               <div className="space-y-3 rounded-xl bg-gray-50 p-4 text-sm">
//                 <div className="flex justify-between">
//                   <span className="text-gray-600">Name</span>
//                   <span className="font-medium">{userName}</span>
//                 </div>

//                 <div className="flex justify-between">
//                   <span className="text-gray-600">User ID</span>
//                   <span className="font-medium text-xs">{uid}</span>
//                 </div>

//                 <div className="flex justify-between border-t pt-3">
//                   <span className="text-gray-600">Amount</span>
//                   <span className="font-semibold text-teal-600 text-lg">
//                     ₹{selectedLoan.emi.toLocaleString("en-IN")}
//                   </span>
//                 </div>
//               </div>

//               {/* Action Buttons */}
//               <div className="flex flex-col gap-3">
//                 <Button
//                   variant="outline"
//                   className="w-full rounded-xl"
//                   onClick={() => setIsOpen(false)}
//                 >
//                   Cancel
//                 </Button>

//                 <Button
//                   className="w-full rounded-xl"
//                   disabled={isPaying}
//                   onClick={async () => {
//                     if (isPaying) return;

//                     setLoanId("1");
//                     setAmount((selectedLoan.emi / 3000).toString());
//                     setIsPaying(true);

//                     try {
//                       const connected = await forceConnectWallet();
//                       if (!connected) return;

//                       const success = await payEMI();

//                       if (success) {
//                         await markEmiPaid(selectedLoan.id, selectedLoan.emi, success);
//                         toast.success("EMI Paid Successfully");
//                         setIsOpen(false);
//                       }

//                     } finally {
//                       setIsPaying(false);
//                     }
//                   }}
//                 >
//                   {isPaying ? "Processing..." : "Confirm Pay"}
//                 </Button>

//               </div>
//             </CardContent>
//           </Card>
//         </div>
//       )}

//     </div>

//   );
// }
import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../ui/card";
import { Button } from "../ui/button";
import { Badge } from "../ui/badge";
import { Progress } from "../ui/progress";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "../ui/dialog";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Textarea } from "../ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../ui/select";
import { Calculator, TrendingUp, CheckCircle2, Clock, AlertCircle, Plus } from "lucide-react";
import { toast } from "sonner";
import { Slider } from "../ui/slider";
import { addDoc, collection, doc, getDoc, serverTimestamp, Timestamp, query, where, getDocs, orderBy, updateDoc, onSnapshot } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../AuthContext"; // adjust path
import { Emi } from "../../types/emi";

import OTPVerification from "./OTPVerification";
import { getContract, getReadContract, decodeRepaymentTx } from "./blockchain";
import { ethers } from "ethers";


interface Loan {
  id: string;
  amount: number;
  disbursed: string;
  purpose: string;
  emi: number;
  remaining: number;
  nextDue: string;
  status: "PENDING" | "APPROVED" | "REJECTED";
  isVerified: boolean;
}

interface LoanManagementProps {
  loans: Loan[];
  trustScore: number;
  savings: number;
}

export function LoanManagement({ loans, trustScore, savings }: LoanManagementProps) {
  const [isOtpVerified, setIsOtpVerified] = useState(false);
  const [isApplyDialogOpen, setIsApplyDialogOpen] = useState(false);
  const [isCalculatorOpen, setIsCalculatorOpen] = useState(false);
  const [loanAmount, setLoanAmount] = useState(10000);
  const [loanTenure, setLoanTenure] = useState(12);
  const [showOtp, setShowOtp] = useState(false);
  const [phoneNumber, setPhoneNumber] = useState<string | null>(null);
  const [selectedEmiId, setSelectedEmiId] = useState<string | null>(null);
  const { uid, shgId } = useAuth();
  const [userName, setMemberName] = useState("");
  const [loanId, setLoanId] = useState<string | null>();
  const [amount, setAmount] = useState("");
  const [status, setStatus] = useState("");
  const [successPay, setPay] = useState(0);
  const [totalContributed, setTotalContributed] = useState(0);

  const [repayments, setRepayments] = useState<any[]>([]);

  const [txHash, setTxHash] = useState("");          // latest tx hash
  const [inputTxHash, setInputTxHash] = useState(""); // verification input
  const [verifiedData, setVerifiedData] = useState<any>(null);
  const [isPaying, setIsPaying] = useState(false);

  const [isOpen, setIsOpen] = useState(false);
  const [selectedLoan, setSelectedLoan] = useState<any>(null);

  const [loanApplication, setLoanApplication] = useState({
    amount: "",
    purpose: "",
    tenure: "",
    description: ""
  });

  const interestRate = 12; // Annual interest rate
  const generateDueDates = (startDate: Date, months: number) => {
  const dates: {
    date: Timestamp;
    paid: boolean;
    paidAt?: Timestamp;
    txHash?: string;
  }[] = [];

    for (let i = 1; i <= months; i++) {
      const due = new Date(startDate);
      due.setMonth(due.getMonth() + i);

      dates.push({
        date: Timestamp.fromDate(due),
        paid: false,

      });
    }

    return dates;
  };

  const calculateEMI = (principal: number, tenure: number) => {
    const monthlyRate = interestRate / 12 / 100;
    const emi = (principal * monthlyRate * Math.pow(1 + monthlyRate, tenure)) /
      (Math.pow(1 + monthlyRate, tenure) - 1);
    return Math.round(emi);
  };

  const calculateEligibility = () => {
    const maxLoan = savings * 2; // Can borrow up to 2x savings
    const trustScoreMultiplier = trustScore >= 90 ? 1.2 : trustScore >= 80 ? 1.1 : 1.0;
    return Math.round(maxLoan * trustScoreMultiplier);
  };
  const getCurrentEmiIndex = (dueDates: any[]) => {
    return dueDates.findIndex((d) => d.paid === false);
  };

  function getTrustMultiplier(score: number) {
  if (score < 40) return 0;        // ❌ No loan
  if (score < 55) return 1.5;
  if (score < 70) return 2.0;
  if (score < 80) return 2.5;
  if (score < 90) return 3.0;
  return 3.5;
}


const BASE_CAP = 90000; // SHG safety cap

function calculateEligibleAmount(
  savings: number,
  trustScore: number,
  // activeLoanBalance: number
) {
  const multiplier = getTrustMultiplier(trustScore);

  const trustLimit = savings * multiplier;
  // const netLimit = trustLimit - activeLoanBalance;

  return Math.max(
    0,
    Math.min(BASE_CAP, trustLimit)
  );
}

// const markEmiPaid = async (
//   loanId: string,
//   emiAmount: number,
//   hash: string,
//   monthIndex?: number
// ) => {
//     const loanRef = doc(db, "ShgGroups", shgId!, "loans", loanId);
//     const snap = await getDoc(loanRef);

//     if (!snap.exists()) return;

//     const loan = snap.data();
//     const dueDates = [...loan.dueDates];

//    const currentIndex =
//   monthIndex !== undefined
//     ? monthIndex
//     : getCurrentEmiIndex(dueDates);
//     if (currentIndex === -1) return; // already fully paid

//     // mark EMI paid
//     dueDates[currentIndex] = {
//       ...dueDates[currentIndex],
//       paid: true,
//       paidAt: Timestamp.now(),   // 🔥 EMI payment time
//       txHash: hash,            // 🔥 blockchain tx hash
//     };

//     const newPaidAmount = loan.paidAmount + emiAmount;
//     const newRemaining = loan.remainingAmount - emiAmount;

//     const allPaid = dueDates.every((d: any) => d.paid);

//     await updateDoc(loanRef, {
//       dueDates,
//       paidAmount: newPaidAmount,
//       remainingAmount: Math.max(newRemaining, 0),
//       status: allPaid ? "COMPLETED" : "APPROVED",
//     });
//   };

const markEmiPaid = async (
  loanId: string,
  emiAmount: number,
  hash: string,
  monthIndex?: number
) => {
  try {
    if (!shgId) return;

    const loanRef = doc(db, "ShgGroups", shgId, "loans", loanId);
    const snap = await getDoc(loanRef);

    if (!snap.exists()) return;

    const loan = snap.data();
    const dueDates = [...(loan.dueDates || [])];

    // ✅ determine correct EMI index
    const currentIndex =
      monthIndex !== undefined
        ? monthIndex
        : getCurrentEmiIndex(dueDates);

    if (currentIndex === -1) {
      console.log("⚠️ All EMIs already paid");
      return;
    }

    // ❌ prevent duplicate payment
    if (dueDates[currentIndex]?.paid) {
      console.log("⚠️ EMI already paid at index:", currentIndex);
      return;
    }

    // ✅ update EMI
    dueDates[currentIndex] = {
      ...dueDates[currentIndex],
      paid: true,
      paidAt: Timestamp.now(),
      txHash: hash || "0",
    };

    // ✅ safe calculations
    const newPaidAmount = (loan.paidAmount || 0) + emiAmount;
    const newRemaining = (loan.remainingAmount || 0) - emiAmount;

    const allPaid = dueDates.every((d: any) => d.paid);

    await updateDoc(loanRef, {
      dueDates: dueDates, // ✅ FIX: Preserving Timestamps
      paidAmount: newPaidAmount,
      remainingAmount: Math.max(newRemaining, 0),
      status: allPaid ? "COMPLETED" : "APPROVED",
    });

    console.log("✅ EMI UPDATED SUCCESSFULLY:", {
      loanId,
      index: currentIndex,
      amount: emiAmount,
    });

  } catch (err) {
    console.error("❌ markEmiPaid ERROR:", err);
  }
};

  const fetchUserPhone = async () => {
    if (!uid) return null;

    const q = query(
      collection(db, "users"),
      where("uid", "==", uid)
    );

    const snap = await getDocs(q);

    if (snap.empty) {
      console.log("No user found for uid:", uid);
      return null;
    }

    const userData = snap.docs[0].data();
    console.log("User data:", userData);

    return userData.phoneNumber;
  };

  const fetchUserLoans = async () => {
    const q = query(
      collection(db, "ShgGroups", shgId!, "loans"),
      where("memberId", "==", uid)
    );

    const snap = await getDocs(q);

    return snap.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  };

  const eligibleAmount = calculateEligibility();
  const emi = calculateEMI(loanAmount, loanTenure);
  const totalPayable = emi * loanTenure;
  const totalInterest = totalPayable - loanAmount;
  // uid + shgId
  const [loans2, setLoans] = useState<any[]>([]);
  const [loadingLoans, setLoadingLoans] = useState(true);

  // useEffect(() => {
  //   if (!uid || !shgId) return;

  //   const loadLoans = async () => {
  //     try {
  //       const userLoans = await fetchUserLoans();
  //       setLoans(userLoans);
  //     } catch (err) {
  //       console.error(err);
  //     } finally {
  //       setLoadingLoans(false);
  //     }
  //   };

  //   loadLoans();
  // }, [uid, shgId]);
  useEffect(() => {
    console.log("Ethereum at load:", (window as any).ethereum);
    loadRepayments();
  }, []);
  useEffect(() => {
    if (!shgId || !uid) return;

    const unsub = onSnapshot(
      doc(db, "ShgGroups", shgId, "members", uid),
      (snap) => {
        if (snap.exists()) {
          setMemberName(snap.data().name);
        }
      }
    );

    return () => unsub();
  }, [shgId, uid]);
  useEffect(() => {
    if (!shgId || !uid) return;

    const q = query(
      collection(db, "ShgGroups", shgId, "loans"),
      where("memberId", "==", uid)
    );

    const unsub = onSnapshot(q, (snap) => {
      const data = snap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
      }));
      setLoans(data);
    });

    return () => unsub();
  }, [shgId, uid]);


    useEffect(() => {
  if (!shgId || !uid) return;

  const fetchTotalContributed = async () => {
    let total = 0;

    const roundsSnap = await getDocs(
      collection(db, "ShgGroups", shgId, "monthlyRounds")
    );

    for (const roundDoc of roundsSnap.docs) {
      const contribRef = collection(
        db,
        "ShgGroups",
        shgId,
        "monthlyRounds",
        roundDoc.id,
        "contributions"
      );

      const contribSnap = await getDocs(contribRef);

      contribSnap.forEach((c) => {
        if (c.id === uid) {
          total += c.data().amountPaid || 0;
        }
      });
    }

    setTotalContributed(total);
  };

  fetchTotalContributed();
}, [shgId, uid]);


  const loadRepayments = async () => {
    try {
      const contract = await getReadContract();
      const total = await contract.totalRepayments();
      const count = Number(total);

      const data = [];

      for (let i = 0; i < count; i++) {
        const r = await contract.getRepayment(i);
        data.push({
          payer: r.payer,
          loanId: r.loanId.toString(),
          amount: ethers.formatEther(r.amount),
          time: new Date(Number(r.timestamp) * 1000).toLocaleString(),
        });
      }

      setRepayments(data);
    } catch (err) {
      console.error("❌ loadRepayments failed:", err);
    }
  };
  
  const payEMI = async () => {
    try {
      setStatus("Waiting for wallet...");
      const contract = await getContract();

      const tx = await contract.payEMI(
        Number(loanId),
        { value: ethers.parseEther(amount) }
      );

      setTxHash(tx.hash);
      await tx.wait();

      setStatus("✅ EMI recorded on blockchain");
      return tx.hash;
    } catch (err: any) {
      setStatus("❌ " + err.message);
      return null;
    }
  };

//   const handleCashPayment = async (emiId) => {
//   const phone = await fetchUserPhone();

//   await fetch("http://localhost:5001/send-otp", {
//     method: "POST",
//     headers: { "Content-Type": "application/json" },
//     body: JSON.stringify({
//       phone,
//       emiId
//     })
//   });

//   toast.success("OTP sent. Give it to agent after payment.");
// };

// const handleCashPayment = async (emiId: string) => {
//   try {
//     const phone = await fetchUserPhone();

//     if (!phone) {
//       toast.error("Phone number not found");
//       return;
//     }

//     const res = await fetch("http://localhost:5001/send-otp", {
//       method: "POST",
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: JSON.stringify({
//         phone,
//         emiId,
//       }),
//     });

//     const data = await res.json();

//     if (data.success) {
//       toast.success("OTP sent. Give it to agent after payment.");
//     } else {
//       toast.error("Failed to send OTP");
//     }
//   } catch (err) {
//     console.error(err);
//     toast.error("Error sending OTP");
//   }
// };

const handleCashPayment = async (loan: any) => {
  try {
    const phone = await fetchUserPhone();

    if (!phone) {
      toast.error("Phone number not found");
      return;
    }
    const dueDates = loan.dueDates || [];

    const currentIndex = dueDates.findIndex((d: any) => !d.paid);

    if (currentIndex === -1) {
      toast.error("All EMIs already paid");
      return;
    }
    // 🔥 1. CREATE TRANSACTION IN FIRESTORE
    await addDoc(collection(db, "transactions"), {
      memberId: uid,
      loanId: loan.id,
      emiId: loan.id, // (you are using loan.id as emiId)
      amount: loan.emi, // 🔥 REAL EMI AMOUNT
      monthIndex: currentIndex,
      mode: "CASH",
      status: "PENDING",
      phone,
      shgId,
      createdAt: serverTimestamp(),
    });

    // 🔥 2. SEND OTP
    const res = await fetch("http://localhost:5002/send-otp", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        phone,
        emiId: loan.id,
      }),
    });

    const data = await res.json();

    if (data.success) {
      toast.success("OTP sent. Give it to admin after payment.");
    } else {
      toast.error("Failed to send OTP");
    }
  } catch (err) {
    console.error(err);
    toast.error("Error sending OTP");
  }
};

  const mappedLoans = loans2.map((loan) => {
    const nextDueDate = (() => {
      if (!loan.dueDates || loan.dueDates.length === 0) return null;

      // NEW FORMAT: { date, paid }
      if (typeof loan.dueDates[0] === "object" && loan.dueDates[0].date) {
        return loan.dueDates.find((d: any) => !d.paid)?.date?.toDate?.();
      }

      // OLD FORMAT: Timestamp[]
      return loan.dueDates[0]?.toDate?.();
    })();


    return {
      id: loan.id,
      purpose: loan.purpose,
      status: loan.status,

      amount: loan.principalAmount,
      remaining: loan.remainingAmount,
      emi: loan.emiAmount,
      dueDates: loan.dueDates,
      disbursed: loan.startDate?.toDate().toLocaleDateString("en-IN") || "0",
      nextDue: nextDueDate
        ? nextDueDate.toLocaleDateString("en-IN")
        : "ALL EMI's PAID",
      isVerified: loan.isVerified || false,
    };
  });
  const forceConnectWallet = async () => {
    if (!(window as any).ethereum) {
      alert("MetaMask not installed");
      return false;
    }

    const accounts = await (window as any).ethereum.request({
      method: "eth_requestAccounts",
    });

    if (!accounts || accounts.length === 0) {
      alert("No account selected");
      return false;
    }

    console.log("Connected:", accounts[0]);
    return true;
  };

  const handleVerifyClick = async (emiId: string) => {
    const phone = await fetchUserPhone();

    if (!phone) {
      toast.error("Phone number not found");
      return;
    }

    setSelectedEmiId(emiId);
    setPhoneNumber(phone);
    setIsOtpVerified(false); // 🔥 reset every time
    setShowOtp(true);
  };


  const handleApplyLoan = async () => {
    if (!loanApplication.amount || !loanApplication.purpose || !loanApplication.tenure) {
      toast.error("Please fill in all required fields");
      return;
    }

    try {

      const principal = Number(loanApplication.amount);
      const tenure = Number(loanApplication.tenure);
      const startDate = new Date();
      const purpose = loanApplication.purpose
      const description = loanApplication.description;
      const monthlyRate = interestRate / 12 / 100;
      const emi =
        (principal * monthlyRate * Math.pow(1 + monthlyRate, tenure)) /
        (Math.pow(1 + monthlyRate, tenure) - 1);

      const emiAmount = Math.round(emi);
      const totalPayable = emiAmount * tenure;
      const memberRef2 = doc(
        db,
        "ShgGroups", shgId!
      );
      const memberSnap2 = await getDoc(memberRef2);
      const loanDoc = {
        adminId: memberSnap2!.data()!.createdBy, // assigned later on approval
        memberId: uid,

        principalAmount: principal,
        interestRate,
        tenureMonths: tenure,

        emiAmount,
        totalPayable,
        paidAmount: 0,
        remainingAmount: totalPayable,
        purpose: purpose,
        description: description,
        startDate: Timestamp.fromDate(startDate),
        dueDates: generateDueDates(startDate, tenure),

        status: "PENDING", // APPROVED after admin approval
        isVerified: false,
        createdAt: serverTimestamp(),
      };

      await addDoc(
        collection(db, "ShgGroups", shgId!, "loans"),
        loanDoc
      );

      toast.success("Loan application submitted successfully!");
      setIsApplyDialogOpen(false);
      setLoanApplication({ amount: "", purpose: "", tenure: "", description: "" });

    } catch (err) {
      console.error(err);
      toast.error("Failed to apply loan");
    }
  };

  // 🔹 popup-specific paid status (outside map, safe scope)


  return (


    <div className="max-w-[1600px] mx-auto space-y-6">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <h2 className="text-3xl text-gray-900 mb-2">Loan Management</h2>
          <p className="text-gray-600">Manage your loans and explore new opportunities</p>
        </div>
        <div className="flex gap-3">
          <Dialog open={isCalculatorOpen} onOpenChange={setIsCalculatorOpen}>
            <DialogTrigger asChild>
              <Button variant="outline" className="gap-2">
                <Calculator className="w-4 h-4" />
                EMI Calculator
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>Loan EMI Calculator</DialogTitle>
                <DialogDescription>
                  Calculate your monthly installments and plan your loan
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-6">
                <div className="space-y-4">
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <Label>Loan Amount</Label>
                      <span className="text-sm">₹{loanAmount.toLocaleString('en-IN')}</span>
                    </div>
                    <Slider
                      value={[loanAmount]}
                      onValueChange={([value]: any) => setLoanAmount(value)}
                      min={2000}
                      max={134560}
                      step={1}
                      className="w-full"
                    />
                  </div>

                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <Label>Tenure (Months)</Label>
                      <span className="text-sm">{loanTenure} months</span>
                    </div>
                    <Slider
                      value={[loanTenure]}
                      onValueChange={([value]: any) => setLoanTenure(value)}
                      min={3}
                      max={24}
                      step={1}
                      className="w-full"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4 p-4 bg-gray-50 rounded-lg">
                  <div>
                    <p className="text-sm text-gray-600">Monthly EMI</p>
                    <p className="text-2xl text-teal-600">₹{emi.toLocaleString('en-IN')}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Total Interest</p>
                    <p className="text-2xl text-orange-600">₹{totalInterest.toLocaleString('en-IN')}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Total Payable</p>
                    <p className="text-2xl text-gray-900">₹{totalPayable.toLocaleString('en-IN')}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Interest Rate</p>
                    <p className="text-2xl text-gray-900">{interestRate}% p.a.</p>
                  </div>
                </div>
              </div>
            </DialogContent>
          </Dialog>

          <Dialog open={isApplyDialogOpen} onOpenChange={setIsApplyDialogOpen}>
            <DialogTrigger asChild>
              <Button className="gap-2">
                <Plus className="w-4 h-4" />
                Apply for Loan
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Apply for New Loan</DialogTitle>
                <DialogDescription>
                  Submit your loan application for group review
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="loan-amount">Loan Amount (₹) *</Label>
                  <Input
                    id="loan-amount"
                    type="number"
                    placeholder="20000"
                    value={loanApplication.amount}
                      max={calculateEligibleAmount(totalContributed,trustScore)}
                    onChange={(e) => setLoanApplication({ ...loanApplication, amount: e.target.value })}
                  />
                  <p className="text-xs text-gray-500">
                    You are eligible for up to ₹{calculateEligibleAmount(totalContributed,trustScore)}
                  </p>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="loan-purpose">Loan Purpose *</Label>
                  <Select
                    value={loanApplication.purpose}
                    onValueChange={(value: any) => setLoanApplication({ ...loanApplication, purpose: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select purpose" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="business">Business/Livelihood</SelectItem>
                      <SelectItem value="education">Education</SelectItem>
                      <SelectItem value="medical">Medical Emergency</SelectItem>
                      <SelectItem value="agriculture">Agriculture</SelectItem>
                      <SelectItem value="home">Home Improvement</SelectItem>
                      <SelectItem value="other">Other</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="loan-tenure">Repayment Tenure (Months) *</Label>
                  <Select
                    value={loanApplication.tenure}
                    onValueChange={(value: any) => setLoanApplication({ ...loanApplication, tenure: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select tenure" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="6">6 months</SelectItem>
                      <SelectItem value="12">12 months</SelectItem>
                      <SelectItem value="18">18 months</SelectItem>
                      <SelectItem value="24">24 months</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="loan-description">Description</Label>
                  <Textarea
                    id="loan-description"
                    placeholder="Provide details about how you plan to use this loan..."
                    value={loanApplication.description}
                    onChange={(e) => setLoanApplication({ ...loanApplication, description: e.target.value })}
                    rows={3}
                  />
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsApplyDialogOpen(false)}>Cancel</Button>
                <Button onClick={handleApplyLoan}>Submit Application</Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Eligibility Card */}
      <Card className="bg-gradient-to-br from-teal-50 to-blue-50 border-teal-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5 text-teal-600" />
            Your Loan Eligibility
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <p className="text-sm text-gray-600 mb-1">Maximum Eligible Amount</p>
              <p className="text-3xl text-teal-600">₹{calculateEligibleAmount(totalContributed,trustScore)}</p>
              <p className="text-xs text-gray-500 mt-1">Based on your savings and trust score</p>
            </div>
            <div>
              <p className="text-sm text-gray-600 mb-1">Trust Score</p>
              <p className="text-3xl text-gray-900">{trustScore}</p>
              <div className="flex items-center gap-2 mt-1">
                <Progress value={trustScore} className="h-2 flex-1" />
                <span className="text-xs text-gray-500">{trustScore}%</span>
              </div>
            </div>
            <div>
              <p className="text-sm text-gray-600 mb-1">Interest Rate</p>
              <p className="text-3xl text-gray-900">{interestRate}%</p>
              <p className="text-xs text-gray-500 mt-1">Annual interest rate</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* APPROVED Loans */}
      <div className="space-y-4">
        <h3 className="text-xl text-gray-900">APPROVED Loans</h3>
        {mappedLoans.length > 0 ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {mappedLoans.map((loan) => {
              const totalEmis = loan.dueDates.length;
              const paidEmis = loan.dueDates.filter((d: any) => d.paid).length;
              const repaidPercentage = (paidEmis / totalEmis) * 100;

              const currentEmiIndex = getCurrentEmiIndex(loan.dueDates);
              const isFullyPaid = currentEmiIndex === -1;

              return (
                <Card key={loan.id}>
                  <CardHeader>
                    <div className="flex justify-between items-start">
                      <div>
                        <CardTitle>{loan.purpose}</CardTitle>
                        <CardDescription className="flex items-center gap-2 mt-1">
                          Disbursed: {loan.disbursed}
                        </CardDescription>
                      </div>
                      <Badge
                        className={
                          loan.status === "COMPLETED"
                            ? "bg-blue-100 text-blue-800"
                            : loan.status === "APPROVED"
                              ? "bg-green-100 text-green-800"
                              : loan.status === "REJECTED"
                                ? "bg-orange-600 text-red"
                                : "bg-yellow-100 text-yellow-800"

                        }
                      >
                        {loan.status}

                      </Badge>

                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    {/* Loan Amount */}
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm text-gray-600">Loan Amount</p>
                        <p className="text-xl text-gray-900">₹{loan.amount.toLocaleString('en-IN')}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Remaining</p>
                        <p className="text-xl text-orange-600">₹{loan.remaining.toLocaleString('en-IN')}</p>
                      </div>
                    </div>

                    {/* Repayment Progress */}
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Repayment Progress</span>
                        <span className="text-gray-900">{repaidPercentage.toFixed(1)}%</span>
                      </div>
                      <Progress value={repaidPercentage} className="h-3" />
                    </div>

                    {/* EMI Details */}
                    <div className="bg-blue-50 p-4 rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm text-gray-600">Monthly EMI</span>
                        <span className="text-lg text-gray-900">₹{loan.emi.toLocaleString('en-IN')}</span>
                      </div>
                      <div className="flex items-center gap-2 text-sm">
                        <Clock className="w-4 h-4 text-orange-600" />
                        <span className="text-gray-600">Next Due: <span className="text-orange-600">{loan.nextDue}</span></span>
                      </div>
                      <div className="flex flex-col gap-3">
                        <Button
                          onClick={() => handleVerifyClick(loan.id)}
                          variant="outline"
                          disabled={loan.isVerified}
                        >
                          {loan.isVerified ? "Verified" : "Verify EMI"}
                        </Button>


                        <Button
                          disabled={!loan.isVerified || isFullyPaid}
                          className={`w-full ${!loan.isVerified
                            ? "opacity-50 cursor-not-allowed"
                            : isFullyPaid
                              ? "bg-green-600 hover:bg-green-600 cursor-not-allowed"
                              : ""
                            }`}
                          onClick={() => {
                            if (!loan.isVerified || isFullyPaid) return;
                            setSelectedLoan(loan);
                            setIsOpen(true); // 👉 confirmation popup
                          }}
                        >
                          {!loan.isVerified
                            ? "Verify EMI First"
                            : isFullyPaid
                              ? "✅ Paid"
                              : `Pay ₹${loan.emi}`}
                        </Button>

                        <Button
                          onClick={() => handleCashPayment(loan)}
                          disabled={loan.status !== "APPROVED" || isFullyPaid}
                          className={`w-full ${
                            loan.status !== "APPROVED"
                              ? "opacity-50 cursor-not-allowed"
                              : isFullyPaid
                                ? "bg-green-600 hover:bg-green-600 cursor-not-allowed"
                                : ""
                          }`}
                        >
                          {loan.status !== "APPROVED"
                            ? "Loan Not Approved Yet"
                            : isFullyPaid
                              ? "✅ All EMIs Paid"
                              : "Pay via Cash"}
                        </Button>

                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-600 mb-4">You don't have any APPROVED loans</p>
              <Button onClick={() => setIsApplyDialogOpen(true)}>Apply for Your First Loan</Button>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Loan Benefits */}
      <Card className="border-purple-200 bg-purple-50/30">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-purple-600" />
            Benefits of SHG Loans
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2 text-gray-700">
            <li className="flex gap-2">
              <span className="text-purple-600">•</span>
              <span>Lower interest rates compared to traditional banks and moneylenders</span>
            </li>
            <li className="flex gap-2">
              <span className="text-purple-600">•</span>
              <span>Flexible repayment terms decided by the group</span>
            </li>
            <li className="flex gap-2">
              <span className="text-purple-600">•</span>
              <span>No collateral required - trust score determines eligibility</span>
            </li>
            <li className="flex gap-2">
              <span className="text-purple-600">•</span>
              <span>Quick approval process within the group</span>
            </li>
            <li className="flex gap-2">
              <span className="text-purple-600">•</span>
              <span>Support from fellow members throughout the repayment journey</span>
            </li>
          </ul>
        </CardContent>
      </Card>

      <Dialog open={showOtp} onOpenChange={setShowOtp}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Verify EMI</DialogTitle>
            <DialogDescription>
              Enter the OTP sent to your registered phone number
            </DialogDescription>
          </DialogHeader>

          {phoneNumber && (
            <OTPVerification
              phoneNumber={phoneNumber}
              onVerified={async () => {
                if (!selectedEmiId || !shgId) return;

                await updateDoc(
                  doc(db, "ShgGroups", shgId, "loans", selectedEmiId),
                  { isVerified: true }
                );

                // update local UI instantly
                setLoans((prev) =>
                  prev.map((loan) =>
                    loan.id === selectedEmiId
                      ? { ...loan, isVerified: true }
                      : loan
                  )
                );

                setIsOtpVerified(true);
                setShowOtp(false);
                toast.success("OTP verified. You can now pay EMI.");
              }}
            />

          )}
        </DialogContent>
      </Dialog>
      {isOpen && selectedLoan && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <Card className="w-full max-w-md rounded-2xl shadow-xl border border-gray-200">

            {/* Header */}
            <CardHeader className="pb-2">
              <CardTitle className="text-xl font-semibold text-center">
                Confirm Contribution
              </CardTitle>
              <p className="text-sm text-center text-gray-500">
                Please verify your payment details
              </p>
            </CardHeader>

            {/* Content */}
            <CardContent className="space-y-6 px-6 pb-6">

              {/* Info Box */}
              <div className="space-y-3 rounded-xl bg-gray-50 p-4 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Name</span>
                  <span className="font-medium">{userName}</span>
                </div>

                <div className="flex justify-between">
                  <span className="text-gray-600">User ID</span>
                  <span className="font-medium text-xs">{uid}</span>
                </div>

                <div className="flex justify-between border-t pt-3">
                  <span className="text-gray-600">Amount</span>
                  <span className="font-semibold text-teal-600 text-lg">
                    ₹{selectedLoan.emi.toLocaleString("en-IN")}
                  </span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col gap-3">
                <Button
                  variant="outline"
                  className="w-full rounded-xl"
                  onClick={() => setIsOpen(false)}
                >
                  Cancel
                </Button>

                <Button
                  className="w-full rounded-xl"
                  disabled={isPaying}
                  onClick={async () => {
                    if (isPaying) return;

                    setLoanId("1");
                    setAmount((selectedLoan.emi / 3000).toString());
                    setIsPaying(true);

                    try {
                      const connected = await forceConnectWallet();
                      if (!connected) return;

                      const success = await payEMI();

                      if (success) {
                        await markEmiPaid(selectedLoan.id, selectedLoan.emi, success);

                        // Create transaction record for admin visibility
                        await addDoc(collection(db, "transactions"), {
                          memberId: uid,
                          loanId: selectedLoan.id,
                          emiId: selectedLoan.id,
                          amount: selectedLoan.emi,
                          mode: "ONLINE",
                          status: "VERIFIED",
                          txHash: success,
                          phone: await fetchUserPhone() || "",
                          shgId,
                          createdAt: serverTimestamp(),
                          verifiedAt: serverTimestamp(),
                        });

                        toast.success("EMI Paid Successfully");
                        setIsOpen(false);
                      }

                    } finally {
                      setIsPaying(false);
                    }
                  }}
                >
                  {isPaying ? "Processing..." : "Confirm Pay"}
                </Button>

              </div>
            </CardContent>
          </Card>
        </div>
      )}

    </div>

  );
}